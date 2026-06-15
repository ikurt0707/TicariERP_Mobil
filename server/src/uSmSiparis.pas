unit uSmSiparis;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  Datasnap.DSServer, Datasnap.DSAuth, Datasnap.DSProviderDataModuleAdapter,
  FireDAC.Comp.Client;

type
  {$METHODINFO ON}
  TSmSiparis = class(TDSServerModule)
  public
    /// <summary>Siparis listele (filtreleme destekli)</summary>
    function GetSiparisler(ADurum: string; APage, APageSize: Integer): TJSONObject;

    /// <summary>Siparis detay getir</summary>
    function GetSiparisById(ASiparisID: Int64): TJSONObject;

    /// <summary>Yeni siparis olustur</summary>
    function CreateSiparis(ASiparisJson: string): TJSONObject;

    /// <summary>Siparis durumunu guncelle</summary>
    function UpdateSiparisDurum(ASiparisID: Int64; ADurum: string): TJSONObject;

    /// <summary>Siparis iptal et</summary>
    function CancelSiparis(ASiparisID: Int64; ANeden: string): TJSONObject;

    /// <summary>Gunluk siparis ozeti</summary>
    function GetGunlukOzet(ATarih: string): TJSONObject;

    /// <summary>Musteri siparisleri getir</summary>
    function GetCariSiparisleri(ACariID: Integer; APage, APageSize: Integer): TJSONObject;

    /// <summary>Son siparisler (dashboard icin)</summary>
    function GetSonSiparisler(ALimit: Integer): TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

{$R *.dfm}

uses
  uDM, System.DateUtils;

function TSmSiparis.GetSiparisler(ADurum: string; APage, APageSize: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
  LOffset: Integer;
  LWhere: string;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  if APage < 1 then APage := 1;
  if APageSize < 1 then APageSize := 20;
  LOffset := (APage - 1) * APageSize;

  LWhere := '';
  if (ADurum <> '') and (ADurum <> 'Tumu') then
    LWhere := ' WHERE s.Durum = :Durum';

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT s.SiparisID, s.SiparisNo, s.CariAdi, s.Telefon, s.Durum, ' +
      '  s.GenelToplam, s.SiparisTarih, s.DagitimDurum, s.SiparisKaynak, s.OdemeTipi ' +
      'FROM TupSuSiparisBaslik s' + LWhere + ' ' +
      'ORDER BY s.SiparisTarih DESC ' +
      'OFFSET :Offset ROWS FETCH NEXT :PageSize ROWS ONLY';

    if LWhere <> '' then
      LQuery.ParamByName('Durum').AsString := ADurum;
    LQuery.ParamByName('Offset').AsInteger := LOffset;
    LQuery.ParamByName('PageSize').AsInteger := APageSize;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('siparisId', TJSONNumber.Create(LQuery.FieldByName('SiparisID').AsLargeInt));
      LObj.AddPair('siparisNo', LQuery.FieldByName('SiparisNo').AsString);
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('durum', LQuery.FieldByName('Durum').AsString);
      LObj.AddPair('genelToplam', TJSONNumber.Create(LQuery.FieldByName('GenelToplam').AsCurrency));
      LObj.AddPair('siparisTarih', DateToISO8601(LQuery.FieldByName('SiparisTarih').AsDateTime));
      LObj.AddPair('dagitimDurum', LQuery.FieldByName('DagitimDurum').AsString);
      LObj.AddPair('siparisKaynak', LQuery.FieldByName('SiparisKaynak').AsString);
      LObj.AddPair('odemeTipi', LQuery.FieldByName('OdemeTipi').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
    Result.AddPair('page', TJSONNumber.Create(APage));
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.GetSiparisById(ASiparisID: Int64): TJSONObject;
var
  LQuery: TFDQuery;
  LObj, LDetayObj: TJSONObject;
  LDetayArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'SELECT * FROM TupSuSiparisBaslik WHERE SiparisID = :ID';
    LQuery.ParamByName('ID').AsLargeInt := ASiparisID;
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Siparis bulunamadi');
      Exit;
    end;

    LObj := TJSONObject.Create;
    LObj.AddPair('siparisId', TJSONNumber.Create(LQuery.FieldByName('SiparisID').AsLargeInt));
    LObj.AddPair('siparisNo', LQuery.FieldByName('SiparisNo').AsString);
    LObj.AddPair('cariId', TJSONNumber.Create(LQuery.FieldByName('CariID').AsInteger));
    LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
    LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
    LObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
    LObj.AddPair('mahalle', LQuery.FieldByName('Mahalle').AsString);
    LObj.AddPair('durum', LQuery.FieldByName('Durum').AsString);
    LObj.AddPair('odemeTipi', LQuery.FieldByName('OdemeTipi').AsString);
    LObj.AddPair('siparisNotu', LQuery.FieldByName('SiparisNotu').AsString);
    LObj.AddPair('araToplam', TJSONNumber.Create(LQuery.FieldByName('AraToplam').AsCurrency));
    LObj.AddPair('indirim', TJSONNumber.Create(LQuery.FieldByName('Indirim').AsCurrency));
    LObj.AddPair('genelToplam', TJSONNumber.Create(LQuery.FieldByName('GenelToplam').AsCurrency));
    LObj.AddPair('siparisTarih', DateToISO8601(LQuery.FieldByName('SiparisTarih').AsDateTime));
    LObj.AddPair('dagitimDurum', LQuery.FieldByName('DagitimDurum').AsString);
    LObj.AddPair('siparisKaynak', LQuery.FieldByName('SiparisKaynak').AsString);
    LObj.AddPair('teslimNotu', LQuery.FieldByName('TeslimNotu').AsString);
    LObj.AddPair('tahsilatTutari', TJSONNumber.Create(LQuery.FieldByName('TahsilatTutari').AsCurrency));

    // Get order items
    LQuery.Close;
    LQuery.SQL.Text := 'SELECT * FROM TupSuSiparisDetay WHERE SiparisID = :ID';
    LQuery.ParamByName('ID').AsLargeInt := ASiparisID;
    LQuery.Open;

    LDetayArray := TJSONArray.Create;
    while not LQuery.Eof do
    begin
      LDetayObj := TJSONObject.Create;
      LDetayObj.AddPair('detayId', TJSONNumber.Create(LQuery.FieldByName('SiparisDetayID').AsLargeInt));
      LDetayObj.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
      LDetayObj.AddPair('urunAdi', LQuery.FieldByName('UrunAdi').AsString);
      LDetayObj.AddPair('miktar', TJSONNumber.Create(LQuery.FieldByName('Miktar').AsCurrency));
      LDetayObj.AddPair('birimFiyat', TJSONNumber.Create(LQuery.FieldByName('BirimFiyat').AsCurrency));
      LDetayObj.AddPair('satirToplam', TJSONNumber.Create(LQuery.FieldByName('SatirToplam').AsCurrency));
      LDetayArray.AddElement(LDetayObj);
      LQuery.Next;
    end;
    LObj.AddPair('detaylar', LDetayArray);

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LObj);
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.CreateSiparis(ASiparisJson: string): TJSONObject;
var
  LQuery: TFDQuery;
  LJson, LDetayJson: TJSONObject;
  LDetayArray: TJSONArray;
  LNewID: Int64;
  LSiparisNo: string;
  I: Integer;
begin
  Result := TJSONObject.Create;
  LJson := TJSONObject.ParseJSONValue(ASiparisJson) as TJSONObject;
  if LJson = nil then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz JSON');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    // Generate siparis no
    LSiparisNo := 'SP-' + FormatDateTime('yyyymmdd-hhnnss', Now);

    LQuery.SQL.Text :=
      'INSERT INTO TupSuSiparisBaslik (SiparisNo, CariID, CariAdi, Telefon, Adres, Mahalle, ' +
      '  Durum, OdemeTipi, SiparisNotu, AraToplam, Indirim, GenelToplam, SiparisTarih, ' +
      '  DagitimDurum, SiparisKaynak) ' +
      'VALUES (:SiparisNo, :CariID, :CariAdi, :Telefon, :Adres, :Mahalle, ' +
      '  :Durum, :OdemeTipi, :Notu, :AraToplam, :Indirim, :GenelToplam, GETDATE(), ' +
      '  :DagitimDurum, :Kaynak); ' +
      'SELECT SCOPE_IDENTITY() AS NewID';
    LQuery.ParamByName('SiparisNo').AsString := LSiparisNo;
    LQuery.ParamByName('CariID').AsInteger := LJson.GetValue<Integer>('cariId', 0);
    LQuery.ParamByName('CariAdi').AsString := LJson.GetValue<string>('cariAdi', '');
    LQuery.ParamByName('Telefon').AsString := LJson.GetValue<string>('telefon', '');
    LQuery.ParamByName('Adres').AsString := LJson.GetValue<string>('adres', '');
    LQuery.ParamByName('Mahalle').AsString := LJson.GetValue<string>('mahalle', '');
    LQuery.ParamByName('Durum').AsString := 'Hazirlaniyor';
    LQuery.ParamByName('OdemeTipi').AsString := LJson.GetValue<string>('odemeTipi', 'Nakit');
    LQuery.ParamByName('Notu').AsString := LJson.GetValue<string>('siparisNotu', '');
    LQuery.ParamByName('AraToplam').AsCurrency := LJson.GetValue<Double>('araToplam', 0);
    LQuery.ParamByName('Indirim').AsCurrency := LJson.GetValue<Double>('indirim', 0);
    LQuery.ParamByName('GenelToplam').AsCurrency := LJson.GetValue<Double>('genelToplam', 0);
    LQuery.ParamByName('DagitimDurum').AsString := 'Bekliyor';
    LQuery.ParamByName('Kaynak').AsString := LJson.GetValue<string>('siparisKaynak', 'Mobil');
    LQuery.Open;

    LNewID := LQuery.FieldByName('NewID').AsLargeInt;

    // Insert detail lines
    LDetayArray := LJson.GetValue<TJSONArray>('detaylar');
    if Assigned(LDetayArray) then
    begin
      for I := 0 to LDetayArray.Count - 1 do
      begin
        LDetayJson := LDetayArray.Items[I] as TJSONObject;
        LQuery.Close;
        LQuery.SQL.Text :=
          'INSERT INTO TupSuSiparisDetay (SiparisID, StokID, UrunAdi, Miktar, BirimFiyat, SatirToplam) ' +
          'VALUES (:SiparisID, :StokID, :UrunAdi, :Miktar, :BirimFiyat, :SatirToplam)';
        LQuery.ParamByName('SiparisID').AsLargeInt := LNewID;
        LQuery.ParamByName('StokID').AsInteger := LDetayJson.GetValue<Integer>('stokId', 0);
        LQuery.ParamByName('UrunAdi').AsString := LDetayJson.GetValue<string>('urunAdi', '');
        LQuery.ParamByName('Miktar').AsCurrency := LDetayJson.GetValue<Double>('miktar', 0);
        LQuery.ParamByName('BirimFiyat').AsCurrency := LDetayJson.GetValue<Double>('birimFiyat', 0);
        LQuery.ParamByName('SatirToplam').AsCurrency := LDetayJson.GetValue<Double>('satirToplam', 0);
        LQuery.ExecSQL;
      end;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('siparisId', TJSONNumber.Create(LNewID));
    Result.AddPair('siparisNo', LSiparisNo);
    Result.AddPair('message', 'Siparis basariyla olusturuldu');
  finally
    LQuery.Free;
    LJson.Free;
  end;
end;

function TSmSiparis.UpdateSiparisDurum(ASiparisID: Int64; ADurum: string): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE TupSuSiparisBaslik SET Durum = :Durum WHERE SiparisID = :ID';
    LQuery.ParamByName('ID').AsLargeInt := ASiparisID;
    LQuery.ParamByName('Durum').AsString := ADurum;
    LQuery.ExecSQL;

    if LQuery.RowsAffected > 0 then
    begin
      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('message', 'Siparis durumu guncellendi');
    end
    else
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Siparis bulunamadi');
    end;
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.CancelSiparis(ASiparisID: Int64; ANeden: string): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE TupSuSiparisBaslik SET Durum = ''Iptal'', TeslimEdilemediNeden = :Neden, ' +
      '  TeslimEdilemediTarih = GETDATE() ' +
      'WHERE SiparisID = :ID';
    LQuery.ParamByName('ID').AsLargeInt := ASiparisID;
    LQuery.ParamByName('Neden').AsString := ANeden;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(LQuery.RowsAffected > 0));
    Result.AddPair('message', 'Siparis iptal edildi');
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.GetGunlukOzet(ATarih: string): TJSONObject;
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
      '  COUNT(*) AS ToplamSiparis, ' +
      '  ISNULL(SUM(GenelToplam), 0) AS ToplamTutar, ' +
      '  SUM(CASE WHEN Durum = ''TeslimEdildi'' THEN 1 ELSE 0 END) AS TeslimEdilen, ' +
      '  SUM(CASE WHEN DagitimDurum = ''Yolda'' THEN 1 ELSE 0 END) AS Yolda, ' +
      '  SUM(CASE WHEN Durum = ''Hazirlaniyor'' THEN 1 ELSE 0 END) AS Bekleyen, ' +
      '  SUM(CASE WHEN Durum = ''Iptal'' THEN 1 ELSE 0 END) AS Iptal ' +
      'FROM TupSuSiparisBaslik ' +
      'WHERE CAST(SiparisTarih AS DATE) = :Tarih';
    LQuery.ParamByName('Tarih').AsDate := LTarih;
    LQuery.Open;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('tarih', DateToISO8601(LTarih));
    Result.AddPair('toplamSiparis', TJSONNumber.Create(LQuery.FieldByName('ToplamSiparis').AsInteger));
    Result.AddPair('toplamTutar', TJSONNumber.Create(LQuery.FieldByName('ToplamTutar').AsCurrency));
    Result.AddPair('teslimEdilen', TJSONNumber.Create(LQuery.FieldByName('TeslimEdilen').AsInteger));
    Result.AddPair('yolda', TJSONNumber.Create(LQuery.FieldByName('Yolda').AsInteger));
    Result.AddPair('bekleyen', TJSONNumber.Create(LQuery.FieldByName('Bekleyen').AsInteger));
    Result.AddPair('iptal', TJSONNumber.Create(LQuery.FieldByName('Iptal').AsInteger));
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.GetCariSiparisleri(ACariID: Integer; APage, APageSize: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
  LOffset: Integer;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  if APage < 1 then APage := 1;
  if APageSize < 1 then APageSize := 10;
  LOffset := (APage - 1) * APageSize;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT SiparisID, SiparisNo, CariAdi, Durum, GenelToplam, SiparisTarih, DagitimDurum ' +
      'FROM TupSuSiparisBaslik WHERE CariID = :CariID ' +
      'ORDER BY SiparisTarih DESC ' +
      'OFFSET :Offset ROWS FETCH NEXT :PageSize ROWS ONLY';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.ParamByName('Offset').AsInteger := LOffset;
    LQuery.ParamByName('PageSize').AsInteger := APageSize;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('siparisId', TJSONNumber.Create(LQuery.FieldByName('SiparisID').AsLargeInt));
      LObj.AddPair('siparisNo', LQuery.FieldByName('SiparisNo').AsString);
      LObj.AddPair('durum', LQuery.FieldByName('Durum').AsString);
      LObj.AddPair('genelToplam', TJSONNumber.Create(LQuery.FieldByName('GenelToplam').AsCurrency));
      LObj.AddPair('siparisTarih', DateToISO8601(LQuery.FieldByName('SiparisTarih').AsDateTime));
      LObj.AddPair('dagitimDurum', LQuery.FieldByName('DagitimDurum').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.GetSonSiparisler(ALimit: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  if ALimit < 1 then ALimit := 5;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT TOP(:Limit) SiparisID, SiparisNo, CariAdi, Telefon, Durum, ' +
      '  GenelToplam, SiparisTarih, DagitimDurum ' +
      'FROM TupSuSiparisBaslik ORDER BY SiparisTarih DESC';
    LQuery.ParamByName('Limit').AsInteger := ALimit;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('siparisId', TJSONNumber.Create(LQuery.FieldByName('SiparisID').AsLargeInt));
      LObj.AddPair('siparisNo', LQuery.FieldByName('SiparisNo').AsString);
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('durum', LQuery.FieldByName('Durum').AsString);
      LObj.AddPair('genelToplam', TJSONNumber.Create(LQuery.FieldByName('GenelToplam').AsCurrency));
      LObj.AddPair('siparisTarih', DateToISO8601(LQuery.FieldByName('SiparisTarih').AsDateTime));
      LObj.AddPair('dagitimDurum', LQuery.FieldByName('DagitimDurum').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

end.
