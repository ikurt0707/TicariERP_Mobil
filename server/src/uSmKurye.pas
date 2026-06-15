unit uSmKurye;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  Datasnap.DSServer, Datasnap.DSAuth, Datasnap.DSProviderDataModuleAdapter,
  FireDAC.Comp.Client;

type
  {$METHODINFO ON}
  TSmKurye = class(TDSServerModule)
  public
    /// <summary>Dagitim bekleyen siparisleri listele</summary>
    function GetDagitimBekleyenler: TJSONObject;

    /// <summary>Kuryeye siparis ata</summary>
    function AtaSiparis(ASiparisID: Int64; AKullaniciID: Integer): TJSONObject;

    /// <summary>Kurye yola cikildi bildir</summary>
    function YolaCikis(ASiparisID: Int64; AEnlem, ABoylam: Double): TJSONObject;

    /// <summary>Teslim edildi bildir</summary>
    function TeslimEt(ASiparisID: Int64; ATeslimNotu: string; ATahsilatTutari: Double): TJSONObject;

    /// <summary>Teslim edilemedi bildir</summary>
    function TeslimEdilemedi(ASiparisID: Int64; ANedenID: Integer; ANeden: string): TJSONObject;

    /// <summary>Kurye konum guncelle</summary>
    function KonumGuncelle(ASiparisID: Int64; AEnlem, ABoylam: Double): TJSONObject;

    /// <summary>Kurye dagitim ozeti</summary>
    function GetDagitimOzeti(AKullaniciID: Integer; ATarih: string): TJSONObject;

    /// <summary>Teslim edilemedi nedenlerini listele</summary>
    function GetTeslimEdilemediNedenleri: TJSONObject;

    /// <summary>Push device token kaydet</summary>
    function RegisterPushDevice(AKullaniciID: Integer; AToken, ADeviceId, APlatform: string): TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

uses
  uDM, System.DateUtils;

function TSmKurye.GetDagitimBekleyenler: TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT s.SiparisID, s.SiparisNo, s.CariAdi, s.Telefon, s.Adres, s.Mahalle, ' +
      '  s.GenelToplam, s.SiparisTarih, s.OdemeTipi ' +
      'FROM TupSuSiparisBaslik s ' +
      'WHERE s.DagitimDurum = ''Bekliyor'' AND s.Durum <> ''Iptal'' ' +
      'ORDER BY s.SiparisTarih ASC';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('siparisId', TJSONNumber.Create(LQuery.FieldByName('SiparisID').AsLargeInt));
      LObj.AddPair('siparisNo', LQuery.FieldByName('SiparisNo').AsString);
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
      LObj.AddPair('mahalle', LQuery.FieldByName('Mahalle').AsString);
      LObj.AddPair('genelToplam', TJSONNumber.Create(LQuery.FieldByName('GenelToplam').AsCurrency));
      LObj.AddPair('siparisTarih', DateToISO8601(LQuery.FieldByName('SiparisTarih').AsDateTime));
      LObj.AddPair('odemeTipi', LQuery.FieldByName('OdemeTipi').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmKurye.AtaSiparis(ASiparisID: Int64; AKullaniciID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE TupSuSiparisBaslik SET DagiticiKullaniciID = :KulID, DagitimDurum = ''Atandi'' ' +
      'WHERE SiparisID = :ID AND DagitimDurum = ''Bekliyor''';
    LQuery.ParamByName('ID').AsLargeInt := ASiparisID;
    LQuery.ParamByName('KulID').AsInteger := AKullaniciID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(LQuery.RowsAffected > 0));
    if LQuery.RowsAffected > 0 then
      Result.AddPair('message', 'Siparis kuryeye atandi')
    else
      Result.AddPair('message', 'Siparis atanamadi (zaten atanmis veya bulunamadi)');
  finally
    LQuery.Free;
  end;
end;

function TSmKurye.YolaCikis(ASiparisID: Int64; AEnlem, ABoylam: Double): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE TupSuSiparisBaslik SET ' +
      '  DagitimDurum = ''Yolda'', Durum = ''Yolda'', ' +
      '  YolaCikisTarihi = GETDATE(), ' +
      '  DagiticiSonKonumEnlem = :Enlem, DagiticiSonKonumBoylam = :Boylam ' +
      'WHERE SiparisID = :ID';
    LQuery.ParamByName('ID').AsLargeInt := ASiparisID;
    LQuery.ParamByName('Enlem').AsFloat := AEnlem;
    LQuery.ParamByName('Boylam').AsFloat := ABoylam;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(LQuery.RowsAffected > 0));
    Result.AddPair('message', 'Yola cikis kaydedildi');
  finally
    LQuery.Free;
  end;
end;

function TSmKurye.TeslimEt(ASiparisID: Int64; ATeslimNotu: string; ATahsilatTutari: Double): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE TupSuSiparisBaslik SET ' +
      '  DagitimDurum = ''TeslimEdildi'', Durum = ''TeslimEdildi'', ' +
      '  TeslimTarihi = GETDATE(), TeslimNotu = :Notu, TahsilatTutari = :Tahsilat ' +
      'WHERE SiparisID = :ID';
    LQuery.ParamByName('ID').AsLargeInt := ASiparisID;
    LQuery.ParamByName('Notu').AsString := ATeslimNotu;
    LQuery.ParamByName('Tahsilat').AsCurrency := ATahsilatTutari;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(LQuery.RowsAffected > 0));
    Result.AddPair('message', 'Siparis teslim edildi');
  finally
    LQuery.Free;
  end;
end;

function TSmKurye.TeslimEdilemedi(ASiparisID: Int64; ANedenID: Integer; ANeden: string): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE TupSuSiparisBaslik SET ' +
      '  DagitimDurum = ''TeslimEdilemedi'', ' +
      '  TeslimEdilemediNedenID = :NedenID, TeslimEdilemediNeden = :Neden, ' +
      '  TeslimEdilemediTarih = GETDATE() ' +
      'WHERE SiparisID = :ID';
    LQuery.ParamByName('ID').AsLargeInt := ASiparisID;
    LQuery.ParamByName('NedenID').AsInteger := ANedenID;
    LQuery.ParamByName('Neden').AsString := ANeden;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(LQuery.RowsAffected > 0));
    Result.AddPair('message', 'Teslim edilemedi kaydedildi');
  finally
    LQuery.Free;
  end;
end;

function TSmKurye.KonumGuncelle(ASiparisID: Int64; AEnlem, ABoylam: Double): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE TupSuSiparisBaslik SET ' +
      '  DagiticiSonKonumEnlem = :Enlem, DagiticiSonKonumBoylam = :Boylam ' +
      'WHERE SiparisID = :ID';
    LQuery.ParamByName('ID').AsLargeInt := ASiparisID;
    LQuery.ParamByName('Enlem').AsFloat := AEnlem;
    LQuery.ParamByName('Boylam').AsFloat := ABoylam;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
  finally
    LQuery.Free;
  end;
end;

function TSmKurye.GetDagitimOzeti(AKullaniciID: Integer; ATarih: string): TJSONObject;
var
  LQuery: TFDQuery;
  LTarih: TDateTime;
begin
  Result := TJSONObject.Create;
  if ATarih = '' then
    LTarih := Date
  else
    LTarih := ISO8601ToDate(ATarih);

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT ' +
      '  COUNT(*) AS ToplamAtanan, ' +
      '  SUM(CASE WHEN DagitimDurum = ''TeslimEdildi'' THEN 1 ELSE 0 END) AS TeslimEdilen, ' +
      '  SUM(CASE WHEN DagitimDurum = ''Yolda'' THEN 1 ELSE 0 END) AS Yolda, ' +
      '  SUM(CASE WHEN DagitimDurum = ''TeslimEdilemedi'' THEN 1 ELSE 0 END) AS TeslimEdilemedi, ' +
      '  ISNULL(SUM(TahsilatTutari), 0) AS ToplamTahsilat ' +
      'FROM TupSuSiparisBaslik ' +
      'WHERE DagiticiKullaniciID = :KulID AND CAST(SiparisTarih AS DATE) = :Tarih';
    LQuery.ParamByName('KulID').AsInteger := AKullaniciID;
    LQuery.ParamByName('Tarih').AsDate := LTarih;
    LQuery.Open;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('toplamAtanan', TJSONNumber.Create(LQuery.FieldByName('ToplamAtanan').AsInteger));
    Result.AddPair('teslimEdilen', TJSONNumber.Create(LQuery.FieldByName('TeslimEdilen').AsInteger));
    Result.AddPair('yolda', TJSONNumber.Create(LQuery.FieldByName('Yolda').AsInteger));
    Result.AddPair('teslimEdilemedi', TJSONNumber.Create(LQuery.FieldByName('TeslimEdilemedi').AsInteger));
    Result.AddPair('toplamTahsilat', TJSONNumber.Create(LQuery.FieldByName('ToplamTahsilat').AsCurrency));
  finally
    LQuery.Free;
  end;
end;

function TSmKurye.GetTeslimEdilemediNedenleri: TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'SELECT * FROM TupSuTeslimEdilemediNeden ORDER BY TeslimEdilemediNedenID';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('nedenId', TJSONNumber.Create(LQuery.FieldByName('TeslimEdilemediNedenID').AsInteger));
      LObj.AddPair('neden', LQuery.FieldByName('Neden').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmKurye.RegisterPushDevice(AKullaniciID: Integer; AToken, ADeviceId, APlatform: string): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    // Upsert: update existing or insert new
    LQuery.SQL.Text :=
      'IF EXISTS (SELECT 1 FROM CourierPushDevice WHERE KullaniciID = :KulID AND DeviceID = :DevID) ' +
      '  UPDATE CourierPushDevice SET DeviceToken = :Token, Aktif = 1, SonGuncelleme = GETDATE() ' +
      '  WHERE KullaniciID = :KulID AND DeviceID = :DevID ' +
      'ELSE ' +
      '  INSERT INTO CourierPushDevice (KullaniciID, DeviceToken, DeviceID, Platform, Aktif, SonGuncelleme) ' +
      '  VALUES (:KulID, :Token, :DevID, :Platform, 1, GETDATE())';
    LQuery.ParamByName('KulID').AsInteger := AKullaniciID;
    LQuery.ParamByName('Token').AsString := AToken;
    LQuery.ParamByName('DevID').AsString := ADeviceId;
    LQuery.ParamByName('Platform').AsString := APlatform;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Push device kaydedildi');
  finally
    LQuery.Free;
  end;
end;

end.
