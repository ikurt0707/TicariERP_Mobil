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
    function ListOrders(ASearch, AStatus: string; ATarih: string): TJSONObject;
    function ListOrderDetails(ASiparisID: Int64): TJSONObject;
    function ListOrderStatusCounts(ATarih: string): TJSONObject;
    function LoadOrder(ASiparisID: Int64): TJSONObject;
    function SaveOrder(ASiparisJson: string): TJSONObject;
    function UpdateOrderStatus(ASiparisID: Int64; ADurum, AOdemeTipi: string; ATahsilatTutari: Double): TJSONObject;
    function DeleteOrder(ASiparisID: Int64): TJSONObject;
    function MarkOrderUndelivered(ASiparisID: Int64; ANedenID: Integer; ANedenText: string): TJSONObject;
    function RestoreUndeliveredOrder(ASiparisID: Int64): TJSONObject;
    function ListDeliveryFailureReasons: TJSONObject;
    function CancelOpenOrders(ACariID: Integer): TJSONObject;
    function AddLineToExistingOrder(ASiparisID: Int64; AStokID: Integer): TJSONObject;
    function CustomerLastProductPrice(ACariID, AStokID: Integer; AExcludeSiparisID: Int64): TJSONObject;
    function GetTeslimEdilmemisSiparisler(ALimit: Integer): TJSONObject;
    function GetGunlukOzet(ATarih: string): TJSONObject;
    function GetCariSiparisleri(ACariID: Integer; APage, APageSize: Integer): TJSONObject;
    function ListRecentCustomerOrders(ACariID: Integer; ATelefon: string): TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

{$R *.dfm}

uses
  uDM, System.DateUtils, System.StrUtils;

function DagitimDurumFromDurum(const ADurum: string): string;
begin
  if SameText(ADurum, 'Teslim Edildi') then
    Result := 'Teslim Edildi'
  else if SameText(ADurum, 'Yolda') then
    Result := 'Yolda'
  else if SameText(ADurum, 'Iptal') or SameText(ADurum, 'Teslim Edilemedi') then
    Result := 'Teslim Edilemedi'
  else
    Result := 'Beklemede';
end;

function ResolveTahsilatTutari(ATahsilatTutari, AGenelToplam: Currency;
  const AOdemeTipi, ADurum: string): Currency;
begin
  if SameText(Trim(AOdemeTipi), 'Veresiye') then
    Result := 0
  else if ATahsilatTutari < 0 then
  begin
    if SameText(ADurum, 'Teslim Edildi') then
      Result := AGenelToplam
    else
      Result := 0;
  end
  else
    Result := ATahsilatTutari;
end;

procedure CleanOrderMovements(AQuery: TFDQuery; ASiparisID: Int64);
begin
  AQuery.SQL.Text := 'DELETE FROM CariHareket WHERE BelgeTipi IN (''TupSu Siparis'', ''TupSu Tahsilat'', ''Kurye Siparis'', ''Kurye Tahsilat'', ''Kurye Veresiye'') AND BelgeID = :BelgeID';
  AQuery.ParamByName('BelgeID').AsLargeInt := ASiparisID;
  AQuery.ExecSQL;

  AQuery.SQL.Text := 'DELETE FROM KasaHareket WHERE BelgeTipi IN (''TupSu Tahsilat'', ''Kurye Tahsilat'') AND BelgeID = :BelgeID';
  AQuery.ParamByName('BelgeID').AsLargeInt := ASiparisID;
  AQuery.ExecSQL;

  AQuery.SQL.Text := 'DELETE FROM StokHareket WHERE BelgeTipi IN (''TupSu Siparis'', ''Kurye Siparis'') AND BelgeID = :BelgeID';
  AQuery.ParamByName('BelgeID').AsLargeInt := ASiparisID;
  AQuery.ExecSQL;
end;

function TSmSiparis.ListOrders(ASearch, AStatus: string; ATarih: string): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
  LTarih: TDateTime;
  LHasDate: Integer;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;

  LHasDate := 0;
  LTarih := 0;
  if ATarih <> '' then
  begin
    try
      LTarih := ISO8601ToDate(ATarih);
      LHasDate := 1;
    except
      LHasDate := 0;
    end;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT TOP 300 isnull(TeslimEdilemediNeden, '''') as TeslimEdilemediNeden, ' +
      'SiparisID, SiparisNo, CariAdi, Telefon, isnull(Adres, '''') as Adres, Durum, OdemeTipi, SiparisTarih, GenelToplam, ' +
      'datediff(second, SiparisTarih, getdate()) as BeklemeSaniye, ' +
      'isnull(DagiticiKullaniciID, 0) as DagiticiKullaniciID, ' +
      'isnull(SiparisKaynak, ''Manuel'') as SiparisKaynak, ' +
      'isnull(DisKaynakPlatform, '''') as DisKaynakPlatform, ' +
      'isnull(DisPlatformSiparisNo, '''') as DisPlatformSiparisNo, ' +
      'isnull(stuff((select char(10) + cast(cast(D.Miktar as decimal(18,2)) as varchar(32)) + ' +
      ''' x '' + isnull(D.UrunAdi, '''') + '' - '' + cast(cast(D.SatirToplam as decimal(18,2)) as varchar(32)) + '' TL'' ' +
      'from TupSuSiparisDetay D where D.SiparisID = TupSuSiparisBaslik.SiparisID ' +
      'order by D.SiparisDetayID for xml path(''''), type).value(''.'', ''nvarchar(max)''), ' +
      '1, 1, ''''), SiparisNo) as UrunOzet ' +
      'FROM TupSuSiparisBaslik ' +
      'WHERE ((:Status = '''') OR ' +
      '       (:Status = ''Beklemede'' AND isnull(Durum, '''') NOT IN (''Teslim Edildi'', ''Iptal'', ''Teslim Edilemedi'')) OR ' +
      '       (:Status <> ''Beklemede'' AND Durum = :Status)) ' +
      '  AND (:Search = '''' OR SiparisNo LIKE :LikeSearch OR CariAdi LIKE :LikeSearch OR Telefon LIKE :LikeSearch) ' +
      '  AND ((:Status = ''Beklemede'') OR (:HasDate = 0 OR CAST(SiparisTarih AS DATE) = CAST(:Tarih AS DATE))) ' +
      'ORDER BY SiparisID DESC';
    LQuery.ParamByName('Status').AsString := Trim(AStatus);
    LQuery.ParamByName('Search').AsString := Trim(ASearch);
    LQuery.ParamByName('LikeSearch').AsString := '%' + Trim(ASearch) + '%';
    LQuery.ParamByName('HasDate').AsInteger := LHasDate;
    if LHasDate = 1 then
      LQuery.ParamByName('Tarih').AsDate := LTarih
    else
    begin
      LQuery.ParamByName('Tarih').DataType := ftDate;
      LQuery.ParamByName('Tarih').Clear;
    end;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('siparisId', TJSONNumber.Create(LQuery.FieldByName('SiparisID').AsLargeInt));
      LObj.AddPair('siparisNo', LQuery.FieldByName('SiparisNo').AsString);
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
      LObj.AddPair('durum', LQuery.FieldByName('Durum').AsString);
      LObj.AddPair('odemeTipi', LQuery.FieldByName('OdemeTipi').AsString);
      LObj.AddPair('siparisTarih', DateToISO8601(LQuery.FieldByName('SiparisTarih').AsDateTime));
      LObj.AddPair('genelToplam', TJSONNumber.Create(LQuery.FieldByName('GenelToplam').AsCurrency));
      LObj.AddPair('beklemeSaniye', TJSONNumber.Create(LQuery.FieldByName('BeklemeSaniye').AsInteger));
      LObj.AddPair('dagiticiKullaniciID', TJSONNumber.Create(LQuery.FieldByName('DagiticiKullaniciID').AsInteger));
      LObj.AddPair('siparisKaynak', LQuery.FieldByName('SiparisKaynak').AsString);
      LObj.AddPair('disKaynakPlatform', LQuery.FieldByName('DisKaynakPlatform').AsString);
      LObj.AddPair('disPlatformSiparisNo', LQuery.FieldByName('DisPlatformSiparisNo').AsString);
      LObj.AddPair('urunOzet', LQuery.FieldByName('UrunOzet').AsString);
      LObj.AddPair('teslimEdilemediNeden', LQuery.FieldByName('TeslimEdilemediNeden').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.ListOrderDetails(ASiparisID: Int64): TJSONObject;
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
      'SELECT SiparisDetayID, StokID, UrunAdi, Miktar, BirimFiyat, SatirToplam ' +
      'FROM TupSuSiparisDetay WHERE SiparisID = :SiparisID ORDER BY SiparisDetayID';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('siparisDetayId', TJSONNumber.Create(LQuery.FieldByName('SiparisDetayID').AsLargeInt));
      LObj.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
      LObj.AddPair('urunAdi', LQuery.FieldByName('UrunAdi').AsString);
      LObj.AddPair('miktar', TJSONNumber.Create(LQuery.FieldByName('Miktar').AsCurrency));
      LObj.AddPair('birimFiyat', TJSONNumber.Create(LQuery.FieldByName('BirimFiyat').AsCurrency));
      LObj.AddPair('satirToplam', TJSONNumber.Create(LQuery.FieldByName('SatirToplam').AsCurrency));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.ListOrderStatusCounts(ATarih: string): TJSONObject;
var
  LQuery: TFDQuery;
  LTarih: TDateTime;
  LHasDate: Integer;
begin
  Result := TJSONObject.Create;

  LHasDate := 0;
  LTarih := 0;
  if ATarih <> '' then
  begin
    try
      LTarih := ISO8601ToDate(ATarih);
      LHasDate := 1;
    except
      LHasDate := 0;
    end;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT ' +
      'SUM(CASE WHEN isnull(Durum, '''') NOT IN (''Teslim Edildi'', ''Iptal'', ''Teslim Edilemedi'') THEN 1 ELSE 0 END) AS BeklemedeAdet, ' +
      'SUM(CASE WHEN isnull(Durum, '''') = ''Teslim Edildi'' THEN 1 ELSE 0 END) AS TeslimAdet, ' +
      'SUM(CASE WHEN isnull(Durum, '''') = ''Teslim Edilemedi'' THEN 1 ELSE 0 END) AS TeslimEdilemediAdet ' +
      'FROM TupSuSiparisBaslik ' +
      'WHERE (:HasDate = 0 OR CAST(SiparisTarih AS DATE) = CAST(:Tarih AS DATE))';
    LQuery.ParamByName('HasDate').AsInteger := LHasDate;
    if LHasDate = 1 then
      LQuery.ParamByName('Tarih').AsDate := LTarih
    else
    begin
      LQuery.ParamByName('Tarih').DataType := ftDate;
      LQuery.ParamByName('Tarih').Clear;
    end;
    LQuery.Open;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('beklemedeAdet', TJSONNumber.Create(LQuery.FieldByName('BeklemedeAdet').AsInteger));
    Result.AddPair('teslimAdet', TJSONNumber.Create(LQuery.FieldByName('TeslimAdet').AsInteger));
    Result.AddPair('teslimEdilemediAdet', TJSONNumber.Create(LQuery.FieldByName('TeslimEdilemediAdet').AsInteger));
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.LoadOrder(ASiparisID: Int64): TJSONObject;
var
  LQuery: TFDQuery;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT B.*, ' +
      'isnull((SELECT SUM(isnull(H.Borc, 0) - isnull(H.Alacak, 0)) FROM CariHareket H WHERE H.CariID = B.CariID), 0) AS CariBorc, ' +
      'isnull((SELECT CASE WHEN isnull(AU.AdSoyad, '''') <> '''' THEN AU.AdSoyad ELSE AU.KullaniciAdi END ' +
      '  FROM ERP_AUTH.dbo.AuthUser AU WHERE AU.AuthUserID = B.DagiticiKullaniciID), '''') AS KuryeAdi ' +
      'FROM TupSuSiparisBaslik B ' +
      'WHERE B.SiparisID = :SiparisID';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
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
    LObj.AddPair('dagiticiKullaniciID', TJSONNumber.Create(LQuery.FieldByName('DagiticiKullaniciID').AsInteger));
    LObj.AddPair('tahsilatTutari', TJSONNumber.Create(LQuery.FieldByName('TahsilatTutari').AsCurrency));
    LObj.AddPair('cariBorc', TJSONNumber.Create(LQuery.FieldByName('CariBorc').AsCurrency));
    LObj.AddPair('kuryeAdi', LQuery.FieldByName('KuryeAdi').AsString);

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LObj);
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.SaveOrder(ASiparisJson: string): TJSONObject;
var
  LQuery: TFDQuery;
  LJson, LDetayJson: TJSONObject;
  LDetayArray: TJSONArray;
  LSiparisID: Int64;
  LSiparisNo, LDurum, LOdemeTipi, LCariAdi: string;
  LDagitimDurum: string;
  LGenelToplam, LTahsilatTutari: Currency;
  LCariID, I: Integer;
  LAramaLogID: Int64;
  LIsNew: Boolean;
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
    LSiparisID := LJson.GetValue<Int64>('siparisId', 0);
    LCariID := LJson.GetValue<Integer>('cariId', 0);
    LCariAdi := LJson.GetValue<string>('cariAdi', '');
    LDurum := LJson.GetValue<string>('durum', 'Beklemede');
    LOdemeTipi := LJson.GetValue<string>('odemeTipi', 'Nakit');
    LGenelToplam := LJson.GetValue<Double>('genelToplam', 0);
    LTahsilatTutari := ResolveTahsilatTutari(
      LJson.GetValue<Double>('tahsilatTutari', -1),
      LGenelToplam, LOdemeTipi, LDurum);
    LDagitimDurum := DagitimDurumFromDurum(LDurum);
    LAramaLogID := LJson.GetValue<Int64>('aramaLogId', 0);
    LIsNew := LSiparisID = 0;

    if LIsNew then
    begin
      LSiparisNo := 'TS' + FormatDateTime('yymmddhhnnsszzz', Now) + IntToStr(Random(90) + 10);
      LQuery.SQL.Text :=
        'INSERT INTO TupSuSiparisBaslik ' +
        '(SiparisNo, AramaLogID, CariID, CariAdi, Telefon, Adres, Mahalle, CallerId, Durum, ' +
        ' SiparisKaynak, DisKaynakPlatform, DisPlatformSiparisNo, DagitimDurum, DagiticiKullaniciID, ' +
        ' OdemeTipi, TahsilatTutari, SiparisNotu, AraToplam, Indirim, GenelToplam) ' +
        'VALUES (:SiparisNo, :AramaLogID, :CariID, :CariAdi, :Telefon, :Adres, :Mahalle, :CallerId, :Durum, ' +
        ' :SiparisKaynak, :DisKaynakPlatform, :DisPlatformSiparisNo, :DagitimDurum, :DagiticiKullaniciID, ' +
        ' :OdemeTipi, :TahsilatTutari, :SiparisNotu, :AraToplam, :Indirim, :GenelToplam); ' +
        'SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS SiparisID';
      LQuery.ParamByName('SiparisNo').AsString := LSiparisNo;
    end
    else
    begin
      LQuery.SQL.Text :=
        'UPDATE TupSuSiparisBaslik SET ' +
        'AramaLogID = :AramaLogID, CariID = :CariID, CariAdi = :CariAdi, Telefon = :Telefon, ' +
        'Adres = :Adres, Mahalle = :Mahalle, CallerId = :CallerId, Durum = :Durum, ' +
        'SiparisKaynak = :SiparisKaynak, DisKaynakPlatform = :DisKaynakPlatform, ' +
        'DisPlatformSiparisNo = :DisPlatformSiparisNo, DagitimDurum = :DagitimDurum, ' +
        'DagiticiKullaniciID = :DagiticiKullaniciID, OdemeTipi = :OdemeTipi, ' +
        'TahsilatTutari = :TahsilatTutari, SiparisNotu = :SiparisNotu, ' +
        'AraToplam = :AraToplam, Indirim = :Indirim, GenelToplam = :GenelToplam, ' +
        'SiparisTarih = GETDATE() ' +
        'WHERE SiparisID = :SiparisID; ' +
        'SELECT :SiparisID AS SiparisID';
      LQuery.ParamByName('SiparisID').AsLargeInt := LSiparisID;
    end;

    // Bind AramaLogID (nullable)
    LQuery.ParamByName('AramaLogID').DataType := ftLargeint;
    if LAramaLogID > 0 then
      LQuery.ParamByName('AramaLogID').AsLargeInt := LAramaLogID
    else
      LQuery.ParamByName('AramaLogID').Clear;

    LQuery.ParamByName('CariID').AsInteger := LCariID;
    LQuery.ParamByName('CariAdi').AsString := LCariAdi;
    LQuery.ParamByName('Telefon').AsString := LJson.GetValue<string>('telefon', '');
    LQuery.ParamByName('Adres').AsString := LJson.GetValue<string>('adres', '');
    LQuery.ParamByName('Mahalle').AsString := LJson.GetValue<string>('mahalle', '');
    LQuery.ParamByName('CallerId').AsString := LJson.GetValue<string>('callerId', '');
    LQuery.ParamByName('Durum').AsString := LDurum;
    LQuery.ParamByName('SiparisKaynak').AsString := LJson.GetValue<string>('siparisKaynak', 'Mobil');
    LQuery.ParamByName('DisKaynakPlatform').AsString := LJson.GetValue<string>('disKaynakPlatform', '');
    LQuery.ParamByName('DisPlatformSiparisNo').AsString := LJson.GetValue<string>('disPlatformSiparisNo', '');
    LQuery.ParamByName('DagitimDurum').AsString := LDagitimDurum;

    // DagiticiKullaniciID (nullable)
    LQuery.ParamByName('DagiticiKullaniciID').DataType := ftInteger;
    if LJson.GetValue<Integer>('dagiticiKullaniciID', 0) > 0 then
      LQuery.ParamByName('DagiticiKullaniciID').AsInteger := LJson.GetValue<Integer>('dagiticiKullaniciID', 0)
    else
      LQuery.ParamByName('DagiticiKullaniciID').Clear;

    LQuery.ParamByName('OdemeTipi').AsString := LOdemeTipi;
    LQuery.ParamByName('TahsilatTutari').AsCurrency := LTahsilatTutari;
    LQuery.ParamByName('SiparisNotu').AsString := LJson.GetValue<string>('siparisNotu', '');
    LQuery.ParamByName('AraToplam').AsCurrency := LJson.GetValue<Double>('araToplam', 0);
    LQuery.ParamByName('Indirim').AsCurrency := LJson.GetValue<Double>('indirim', 0);
    LQuery.ParamByName('GenelToplam').AsCurrency := LGenelToplam;

    if LIsNew then
    begin
      LQuery.Open;
      LSiparisID := LQuery.FieldByName('SiparisID').AsLargeInt;
      LQuery.Close;
    end
    else
      LQuery.ExecSQL;

    // Replace order lines
    LQuery.SQL.Text := 'DELETE FROM TupSuSiparisDetay WHERE SiparisID = :SiparisID';
    LQuery.ParamByName('SiparisID').AsLargeInt := LSiparisID;
    LQuery.ExecSQL;

    LDetayArray := LJson.GetValue<TJSONArray>('detaylar');
    if Assigned(LDetayArray) then
    begin
      for I := 0 to LDetayArray.Count - 1 do
      begin
        LDetayJson := LDetayArray.Items[I] as TJSONObject;
        LQuery.SQL.Text :=
          'INSERT INTO TupSuSiparisDetay (SiparisID, StokID, UrunAdi, Miktar, BirimFiyat, SatirToplam) ' +
          'VALUES (:SiparisID, :StokID, :UrunAdi, :Miktar, :BirimFiyat, :SatirToplam)';
        LQuery.ParamByName('SiparisID').AsLargeInt := LSiparisID;
        LQuery.ParamByName('StokID').AsInteger := LDetayJson.GetValue<Integer>('stokId', 0);
        LQuery.ParamByName('UrunAdi').AsString := LDetayJson.GetValue<string>('urunAdi', '');
        LQuery.ParamByName('Miktar').AsCurrency := LDetayJson.GetValue<Double>('miktar', 0);
        LQuery.ParamByName('BirimFiyat').AsCurrency := LDetayJson.GetValue<Double>('birimFiyat', 0);
        LQuery.ParamByName('SatirToplam').AsCurrency := LDetayJson.GetValue<Double>('satirToplam', 0);
        LQuery.ExecSQL;
      end;
    end;

    // Clean old movements
    CleanOrderMovements(LQuery, LSiparisID);

    // Create new movements (not for Iptal/Teslim Edilemedi)
    if not SameText(LDurum, 'Iptal') and not SameText(LDurum, 'Teslim Edilemedi') then
    begin
      LQuery.SQL.Text :=
        'INSERT INTO CariHareket (CariID, Tarih, BelgeTipi, BelgeID, Aciklama, Borc, Alacak, KasaID, KullaniciID) ' +
        'VALUES (:CariID, SYSDATETIME(), ''TupSu Siparis'', :BelgeID, :Aciklama, :Borc, 0, NULL, NULL)';
      LQuery.ParamByName('CariID').AsInteger := LCariID;
      LQuery.ParamByName('BelgeID').AsLargeInt := LSiparisID;
      LQuery.ParamByName('Aciklama').AsString := 'Tup&Su siparisi - ' + Trim(LCariAdi);
      LQuery.ParamByName('Borc').AsCurrency := LGenelToplam;
      LQuery.ExecSQL;

      // Tahsilat (teslim edildi + veresiye degil)
      if SameText(LDurum, 'Teslim Edildi') and (not SameText(LOdemeTipi, 'Veresiye')) then
      begin
        LQuery.SQL.Text :=
          'DECLARE @KasaID INT = (SELECT TOP 1 KasaID FROM Kasa WHERE Aktif = 1 ORDER BY KasaID); ' +
          'INSERT INTO CariHareket (CariID, Tarih, BelgeTipi, BelgeID, Aciklama, Borc, Alacak, KasaID, KullaniciID) ' +
          'VALUES (:CariID, SYSDATETIME(), ''TupSu Tahsilat'', :BelgeID, :Aciklama, 0, :Alacak, @KasaID, NULL); ' +
          'INSERT INTO KasaHareket (KasaID, Tarih, IslemTipi, BelgeTipi, BelgeID, Tutar, Aciklama, KullaniciID) ' +
          'SELECT @KasaID, SYSDATETIME(), ''Giris'', ''TupSu Tahsilat'', :BelgeID, :Alacak, :Aciklama, NULL ' +
          'WHERE @KasaID IS NOT NULL;';
        LQuery.ParamByName('CariID').AsInteger := LCariID;
        LQuery.ParamByName('BelgeID').AsLargeInt := LSiparisID;
        LQuery.ParamByName('Aciklama').AsString := 'Tup&Su teslim tahsilati - ' + Trim(LCariAdi);
        LQuery.ParamByName('Alacak').AsCurrency := LTahsilatTutari;
        LQuery.ExecSQL;
      end;
    end;

    // Stok hareketi (teslim edildi)
    if SameText(LDurum, 'Teslim Edildi') and Assigned(LDetayArray) then
    begin
      for I := 0 to LDetayArray.Count - 1 do
      begin
        LDetayJson := LDetayArray.Items[I] as TJSONObject;
        LQuery.SQL.Text :=
          'DECLARE @DepoID INT = (SELECT TOP 1 DepoID FROM Depo WHERE Aktif = 1 ORDER BY DepoID); ' +
          'INSERT INTO StokHareket (StokID, DepoID, Tarih, IslemTipi, BelgeTipi, BelgeID, MiktarGiris, MiktarCikis, BirimFiyat, Aciklama) ' +
          'SELECT :StokID, @DepoID, SYSDATETIME(), ''Teslim Cikis'', ''TupSu Siparis'', :BelgeID, 0, :MiktarCikis, :BirimFiyat, :Aciklama ' +
          'WHERE @DepoID IS NOT NULL';
        LQuery.ParamByName('StokID').AsInteger := LDetayJson.GetValue<Integer>('stokId', 0);
        LQuery.ParamByName('BelgeID').AsLargeInt := LSiparisID;
        LQuery.ParamByName('MiktarCikis').AsCurrency := LDetayJson.GetValue<Double>('miktar', 0);
        LQuery.ParamByName('BirimFiyat').AsCurrency := LDetayJson.GetValue<Double>('birimFiyat', 0);
        LQuery.ParamByName('Aciklama').AsString := 'Tup&Su teslim siparisi - ' + Trim(LCariAdi);
        LQuery.ExecSQL;
      end;
    end;

    // Link call to order
    if LAramaLogID > 0 then
    begin
      LQuery.SQL.Text :=
        'UPDATE TupSuAramaLog SET SiparisID = :SiparisID, Sonuc = ''Siparis Girildi'', Notu = ''Cagridan siparis olusturuldu'' ' +
        'WHERE AramaLogID = :AramaLogID';
      LQuery.ParamByName('SiparisID').AsLargeInt := LSiparisID;
      LQuery.ParamByName('AramaLogID').AsLargeInt := LAramaLogID;
      LQuery.ExecSQL;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('siparisId', TJSONNumber.Create(LSiparisID));
    if LIsNew then
      Result.AddPair('siparisNo', LSiparisNo);
    Result.AddPair('message', IfThen(LIsNew, 'Siparis basariyla olusturuldu', 'Siparis guncellendi'));
  finally
    LQuery.Free;
    LJson.Free;
  end;
end;

function TSmSiparis.UpdateOrderStatus(ASiparisID: Int64; ADurum, AOdemeTipi: string; ATahsilatTutari: Double): TJSONObject;
var
  LQuery: TFDQuery;
  LDagitimDurum: string;
  LTahsilatTutari: Currency;
begin
  Result := TJSONObject.Create;
  if ASiparisID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz siparis ID');
    Exit;
  end;

  LDagitimDurum := DagitimDurumFromDurum(ADurum);

  LQuery := DM.GetQuery;
  try
    // Resolve tahsilat
    LQuery.SQL.Text := 'SELECT GenelToplam, isnull(OdemeTipi, ''Nakit'') AS OdemeTipi FROM TupSuSiparisBaslik WHERE SiparisID = :SiparisID';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.Open;
    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Siparis bulunamadi');
      Exit;
    end;
    if Trim(AOdemeTipi) = '' then
      AOdemeTipi := LQuery.FieldByName('OdemeTipi').AsString;
    LTahsilatTutari := ResolveTahsilatTutari(ATahsilatTutari, LQuery.FieldByName('GenelToplam').AsCurrency, AOdemeTipi, ADurum);
    LQuery.Close;

    LQuery.SQL.Text :=
      'UPDATE TupSuSiparisBaslik SET Durum = :Durum, DagitimDurum = :DagitimDurum, ' +
      'OdemeTipi = :OdemeTipi, TahsilatTutari = :TahsilatTutari ' +
      'WHERE SiparisID = :SiparisID';
    LQuery.ParamByName('Durum').AsString := ADurum;
    LQuery.ParamByName('DagitimDurum').AsString := LDagitimDurum;
    LQuery.ParamByName('OdemeTipi').AsString := AOdemeTipi;
    LQuery.ParamByName('TahsilatTutari').AsCurrency := LTahsilatTutari;
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Siparis durumu guncellendi: ' + ADurum);
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.DeleteOrder(ASiparisID: Int64): TJSONObject;
var
  LQuery: TFDQuery;
  LDurum: string;
begin
  Result := TJSONObject.Create;
  if ASiparisID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz siparis ID');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'SELECT TOP 1 isnull(Durum, '''') AS Durum FROM TupSuSiparisBaslik WHERE SiparisID = :SiparisID';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.Open;
    if not LQuery.IsEmpty then
    begin
      LDurum := LQuery.FieldByName('Durum').AsString;
      if SameText(LDurum, 'Teslim Edildi') then
      begin
        Result.AddPair('success', TJSONBool.Create(False));
        Result.AddPair('message', 'Teslim edilmis siparis geri alinmadan silinemez.');
        Exit;
      end;
    end;
    LQuery.Close;

    // Clean movements
    CleanOrderMovements(LQuery, ASiparisID);

    // Update AramaLog
    LQuery.SQL.Text :=
      'UPDATE TupSuAramaLog SET SiparisID = NULL, Sonuc = ''Bekliyor'', Notu = ''Siparis silindi'' ' +
      'WHERE SiparisID = :SiparisID';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.ExecSQL;

    // Delete detail lines
    LQuery.SQL.Text := 'DELETE FROM TupSuSiparisDetay WHERE SiparisID = :SiparisID';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.ExecSQL;

    // Delete header
    LQuery.SQL.Text := 'DELETE FROM TupSuSiparisBaslik WHERE SiparisID = :SiparisID';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Siparis silindi');
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.MarkOrderUndelivered(ASiparisID: Int64; ANedenID: Integer; ANedenText: string): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  if ASiparisID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz siparis ID');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    // Ensure TeslimEdilemediNeden table exists
    LQuery.SQL.Text :=
      'IF OBJECT_ID(''dbo.TupSuTeslimEdilemediNeden'', ''U'') IS NULL ' +
      'BEGIN ' +
      '  CREATE TABLE dbo.TupSuTeslimEdilemediNeden(' +
      '    NedenID INT IDENTITY(1,1) NOT NULL PRIMARY KEY, ' +
      '    Neden NVARCHAR(200) NOT NULL, ' +
      '    Aktif BIT NOT NULL CONSTRAINT DF_TupSuTEN_Aktif DEFAULT(1), ' +
      '    KayitTarih DATETIME2 NOT NULL CONSTRAINT DF_TupSuTEN_KayitTarih DEFAULT(SYSDATETIME())' +
      '  ); ' +
      'END; ' +
      'IF COL_LENGTH(''dbo.TupSuSiparisBaslik'', ''TeslimEdilemediNedenID'') IS NULL ' +
      '  ALTER TABLE dbo.TupSuSiparisBaslik ADD TeslimEdilemediNedenID INT NULL; ' +
      'IF COL_LENGTH(''dbo.TupSuSiparisBaslik'', ''TeslimEdilemediNeden'') IS NULL ' +
      '  ALTER TABLE dbo.TupSuSiparisBaslik ADD TeslimEdilemediNeden NVARCHAR(500) NULL; ' +
      'IF COL_LENGTH(''dbo.TupSuSiparisBaslik'', ''TeslimEdilemediTarih'') IS NULL ' +
      '  ALTER TABLE dbo.TupSuSiparisBaslik ADD TeslimEdilemediTarih DATETIME NULL;';
    LQuery.ExecSQL;

    LQuery.SQL.Text :=
      'UPDATE dbo.TupSuSiparisBaslik SET ' +
      'Durum = N''Teslim Edilemedi'', DagitimDurum = N''Teslim Edilemedi'', ' +
      'TeslimEdilemediNedenID = :NedenID, TeslimEdilemediNeden = :Neden, ' +
      'TeslimEdilemediTarih = GETDATE() ' +
      'WHERE SiparisID = :SiparisID';
    LQuery.ParamByName('NedenID').DataType := ftInteger;
    if ANedenID > 0 then
      LQuery.ParamByName('NedenID').AsInteger := ANedenID
    else
      LQuery.ParamByName('NedenID').Clear;
    LQuery.ParamByName('Neden').AsString := Copy(Trim(ANedenText), 1, 500);
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.ExecSQL;

    // Clean movements
    CleanOrderMovements(LQuery, ASiparisID);

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Siparis teslim edilemedi olarak isaretlendi');
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.RestoreUndeliveredOrder(ASiparisID: Int64): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  if ASiparisID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz siparis ID');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE dbo.TupSuSiparisBaslik SET ' +
      'Durum = N''Beklemede'', DagitimDurum = N''Beklemede'', ' +
      'TeslimEdilemediNedenID = NULL, TeslimEdilemediNeden = NULL, TeslimEdilemediTarih = NULL ' +
      'WHERE SiparisID = :SiparisID AND isnull(Durum, '''') = N''Teslim Edilemedi''';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(LQuery.RowsAffected > 0));
    if LQuery.RowsAffected > 0 then
      Result.AddPair('message', 'Siparis beklemede durumuna geri alindi')
    else
      Result.AddPair('message', 'Siparis bulunamadi veya Teslim Edilemedi durumunda degil');
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.ListDeliveryFailureReasons: TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  LQuery := DM.GetQuery;
  try
    // Ensure table and seed data
    LQuery.SQL.Text :=
      'IF OBJECT_ID(''dbo.TupSuTeslimEdilemediNeden'', ''U'') IS NULL ' +
      'BEGIN ' +
      '  CREATE TABLE dbo.TupSuTeslimEdilemediNeden(' +
      '    NedenID INT IDENTITY(1,1) NOT NULL PRIMARY KEY, ' +
      '    Neden NVARCHAR(200) NOT NULL, ' +
      '    Aktif BIT NOT NULL DEFAULT(1), ' +
      '    KayitTarih DATETIME2 NOT NULL DEFAULT(SYSDATETIME())' +
      '  ); ' +
      'END; ' +
      'IF NOT EXISTS(SELECT 1 FROM dbo.TupSuTeslimEdilemediNeden) ' +
      'BEGIN ' +
      '  INSERT INTO dbo.TupSuTeslimEdilemediNeden(Neden) VALUES ' +
      '  (N''Musteri evde yok''), (N''Adres bulunamadi''), (N''Telefon cevap vermiyor''), ' +
      '  (N''Musteri teslim almadi''), (N''Musteri iptal etti''), (N''Diger''); ' +
      'END';
    LQuery.ExecSQL;

    LQuery.SQL.Text :=
      'SELECT NedenID, Neden FROM dbo.TupSuTeslimEdilemediNeden ' +
      'WHERE Aktif = 1 ORDER BY Neden';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('nedenId', TJSONNumber.Create(LQuery.FieldByName('NedenID').AsInteger));
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

function TSmSiparis.CancelOpenOrders(ACariID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE TupSuSiparisBaslik SET Durum = ''Iptal'', DagitimDurum = ''Teslim Edilemedi'' ' +
      'WHERE CariID = :CariID AND isnull(Durum, '''') NOT IN (''Teslim Edildi'', ''Iptal'')';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('iptalEdilen', TJSONNumber.Create(LQuery.RowsAffected));
    Result.AddPair('message', IntToStr(LQuery.RowsAffected) + ' siparis iptal edildi');
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.AddLineToExistingOrder(ASiparisID: Int64; AStokID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LStokAdi: string;
  LBirimFiyat: Currency;
begin
  Result := TJSONObject.Create;
  if (ASiparisID <= 0) or (AStokID <= 0) then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz siparis veya stok ID');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'SELECT StokAdi, SatisFiyat FROM Stok WHERE StokID = :StokID';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.Open;
    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Stok bulunamadi');
      Exit;
    end;
    LStokAdi := LQuery.FieldByName('StokAdi').AsString;
    LBirimFiyat := LQuery.FieldByName('SatisFiyat').AsCurrency;
    LQuery.Close;

    LQuery.SQL.Text :=
      'INSERT INTO TupSuSiparisDetay (SiparisID, StokID, UrunAdi, Miktar, BirimFiyat, SatirToplam) ' +
      'VALUES (:SiparisID, :StokID, :UrunAdi, 1, :BirimFiyat, :SatirToplam)';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ParamByName('UrunAdi').AsString := LStokAdi;
    LQuery.ParamByName('BirimFiyat').AsCurrency := LBirimFiyat;
    LQuery.ParamByName('SatirToplam').AsCurrency := LBirimFiyat;
    LQuery.ExecSQL;

    LQuery.SQL.Text :=
      'UPDATE TupSuSiparisBaslik SET ' +
      'AraToplam = isnull((SELECT SUM(SatirToplam) FROM TupSuSiparisDetay WHERE SiparisID = :SiparisID), 0), ' +
      'GenelToplam = isnull((SELECT SUM(SatirToplam) FROM TupSuSiparisDetay WHERE SiparisID = :SiparisID), 0) - isnull(Indirim, 0) ' +
      'WHERE SiparisID = :SiparisID';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', LStokAdi + ' eklendi');
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.CustomerLastProductPrice(ACariID, AStokID: Integer; AExcludeSiparisID: Int64): TJSONObject;
var
  LQuery: TFDQuery;
  LFiyat: Currency;
begin
  Result := TJSONObject.Create;
  LFiyat := 0;

  if AStokID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('fiyat', TJSONNumber.Create(0));
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT TOP 1 D.BirimFiyat ' +
      'FROM TupSuSiparisDetay D ' +
      'INNER JOIN TupSuSiparisBaslik B ON B.SiparisID = D.SiparisID ' +
      'WHERE D.StokID = :StokID AND B.CariID = :CariID ' +
      '  AND (:ExcludeID <= 0 OR B.SiparisID <> :ExcludeID) ' +
      'ORDER BY B.SiparisTarih DESC, D.SiparisDetayID DESC';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.ParamByName('ExcludeID').AsLargeInt := AExcludeSiparisID;
    LQuery.Open;
    if not LQuery.IsEmpty then
      LFiyat := LQuery.FieldByName('BirimFiyat').AsCurrency;
    LQuery.Close;

    if LFiyat <= 0 then
    begin
      LQuery.SQL.Text := 'SELECT SatisFiyat FROM Stok WHERE StokID = :StokID';
      LQuery.ParamByName('StokID').AsInteger := AStokID;
      LQuery.Open;
      if not LQuery.IsEmpty then
        LFiyat := LQuery.FieldByName('SatisFiyat').AsCurrency;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('fiyat', TJSONNumber.Create(LFiyat));
  finally
    LQuery.Free;
  end;
end;

function TSmSiparis.GetTeslimEdilmemisSiparisler(ALimit: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  if ALimit < 1 then ALimit := 50;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT TOP(:Limit) SiparisID, SiparisNo, CariAdi, Telefon, Durum, ' +
      '  GenelToplam, SiparisTarih, DagitimDurum, SiparisKaynak, OdemeTipi, isnull(Adres, '''') as Adres ' +
      'FROM TupSuSiparisBaslik ' +
      'WHERE isnull(Durum, '''') NOT IN (''Teslim Edildi'', ''Iptal'', ''Teslim Edilemedi'') ' +
      'ORDER BY SiparisTarih DESC';
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
      LObj.AddPair('siparisKaynak', LQuery.FieldByName('SiparisKaynak').AsString);
      LObj.AddPair('odemeTipi', LQuery.FieldByName('OdemeTipi').AsString);
      LObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
    Result.AddPair('toplam', TJSONNumber.Create(LArray.Count));
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
      '  SUM(CASE WHEN Durum = ''Teslim Edildi'' THEN 1 ELSE 0 END) AS TeslimEdilen, ' +
      '  SUM(CASE WHEN isnull(Durum, '''') NOT IN (''Teslim Edildi'', ''Iptal'', ''Teslim Edilemedi'') THEN 1 ELSE 0 END) AS Bekleyen, ' +
      '  SUM(CASE WHEN Durum = ''Iptal'' THEN 1 ELSE 0 END) AS Iptal, ' +
      '  SUM(CASE WHEN Durum = ''Teslim Edilemedi'' THEN 1 ELSE 0 END) AS TeslimEdilemedi ' +
      'FROM TupSuSiparisBaslik ' +
      'WHERE CAST(SiparisTarih AS DATE) = :Tarih';
    LQuery.ParamByName('Tarih').AsDate := LTarih;
    LQuery.Open;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('tarih', DateToISO8601(LTarih));
    Result.AddPair('toplamSiparis', TJSONNumber.Create(LQuery.FieldByName('ToplamSiparis').AsInteger));
    Result.AddPair('toplamTutar', TJSONNumber.Create(LQuery.FieldByName('ToplamTutar').AsCurrency));
    Result.AddPair('teslimEdilen', TJSONNumber.Create(LQuery.FieldByName('TeslimEdilen').AsInteger));
    Result.AddPair('bekleyen', TJSONNumber.Create(LQuery.FieldByName('Bekleyen').AsInteger));
    Result.AddPair('iptal', TJSONNumber.Create(LQuery.FieldByName('Iptal').AsInteger));
    Result.AddPair('teslimEdilemedi', TJSONNumber.Create(LQuery.FieldByName('TeslimEdilemedi').AsInteger));
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

function TSmSiparis.ListRecentCustomerOrders(ACariID: Integer; ATelefon: string): TJSONObject;
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
      'SELECT TOP 8 B.SiparisID, B.SiparisNo, B.SiparisTarih, B.GenelToplam, B.Durum, isnull(B.OdemeTipi, '''') AS OdemeTipi, ' +
      'isnull(B.Adres, '''') AS Adres, ' +
      'isnull((SELECT TOP 1 D.UrunAdi FROM TupSuSiparisDetay D WHERE D.SiparisID = B.SiparisID ORDER BY D.SiparisDetayID), ''Siparis'') AS UrunOzet ' +
      'FROM TupSuSiparisBaslik B ' +
      'WHERE ((:CariID > 0 AND CariID = :CariID) OR ' +
      '  (:CariID = 0 AND :Telefon <> '''' AND RIGHT(' +
      '    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(isnull(Telefon, ''''), ' +
      '    '' '', ''''), ''-'', ''''), ''('', ''''), '')'', ''''), ''+90'', ''''), ''90'', ''''), 10) = RIGHT(' +
      '    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(:Telefon, ' +
      '    '' '', ''''), ''-'', ''''), ''('', ''''), '')'', ''''), ''+90'', ''''), ''90'', ''''), 10))) ' +
      'ORDER BY SiparisTarih DESC, SiparisID DESC';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.ParamByName('Telefon').AsString := Trim(ATelefon);
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('siparisId', TJSONNumber.Create(LQuery.FieldByName('SiparisID').AsLargeInt));
      LObj.AddPair('siparisNo', LQuery.FieldByName('SiparisNo').AsString);
      LObj.AddPair('siparisTarih', DateToISO8601(LQuery.FieldByName('SiparisTarih').AsDateTime));
      LObj.AddPair('genelToplam', TJSONNumber.Create(LQuery.FieldByName('GenelToplam').AsCurrency));
      LObj.AddPair('durum', LQuery.FieldByName('Durum').AsString);
      LObj.AddPair('odemeTipi', LQuery.FieldByName('OdemeTipi').AsString);
      LObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
      LObj.AddPair('urunOzet', LQuery.FieldByName('UrunOzet').AsString);
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
