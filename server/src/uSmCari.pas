unit uSmCari;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  Datasnap.DSServer, Datasnap.DSAuth, Datasnap.DSProviderDataModuleAdapter,
  FireDAC.Comp.Client;

type
  {$METHODINFO ON}
  TSmCari = class(TDSServerModule)
  public
    /// <summary>Tum carileri listele (sayfalama destekli)</summary>
    function GetCariList(APage, APageSize: Integer): TJSONObject;

    /// <summary>CariID ile cari detay getir</summary>
    function GetCariById(ACariID: Integer): TJSONObject;

    /// <summary>Telefon numarasina gore cari ara</summary>
    function GetCariByTelefon(ATelefon: string): TJSONObject;

    /// <summary>Cari ara (ad, telefon, kod)</summary>
    function SearchCari(AArama: string; APage, APageSize: Integer): TJSONObject;

    /// <summary>Yeni cari ekle</summary>
    function CreateCari(ACariJson: string): TJSONObject;

    /// <summary>Cari guncelle</summary>
    function UpdateCari(ACariID: Integer; ACariJson: string): TJSONObject;

    /// <summary>Cari adreslerini getir</summary>
    function GetCariAdresler(ACariID: Integer): TJSONObject;

    /// <summary>Cari telefonlarini getir</summary>
    function GetCariTelefonlar(ACariID: Integer): TJSONObject;

    /// <summary>Cari hareket bakiye</summary>
    function GetCariBakiye(ACariID: Integer): TJSONObject;

    /// <summary>Cari hareketleri listele</summary>
    function GetCariHareketler(ACariID: Integer; APage, APageSize: Integer): TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

{$R *.dfm}

uses
  uDM, System.DateUtils;

function TSmCari.GetCariList(APage, APageSize: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
  LOffset: Integer;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  if APage < 1 then APage := 1;
  if APageSize < 1 then APageSize := 20;
  LOffset := (APage - 1) * APageSize;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT c.CariID, c.CariKod, c.CariAdi, c.CariTip, c.Aktif, c.WhatsAppTelefon, ' +
      '  (SELECT TOP 1 Telefon FROM CariTelefon WHERE CariID = c.CariID AND Varsayilan = 1) AS Telefon, ' +
      '  (SELECT TOP 1 AdresSatiri FROM CariAdres WHERE CariID = c.CariID AND Varsayilan = 1) AS Adres ' +
      'FROM Cari c ' +
      'WHERE c.Aktif = 1 ' +
      'ORDER BY c.CariAdi ' +
      'OFFSET :Offset ROWS FETCH NEXT :PageSize ROWS ONLY';
    LQuery.ParamByName('Offset').AsInteger := LOffset;
    LQuery.ParamByName('PageSize').AsInteger := APageSize;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('cariId', TJSONNumber.Create(LQuery.FieldByName('CariID').AsInteger));
      LObj.AddPair('cariKod', LQuery.FieldByName('CariKod').AsString);
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('cariTip', LQuery.FieldByName('CariTip').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
    Result.AddPair('page', TJSONNumber.Create(APage));
    Result.AddPair('pageSize', TJSONNumber.Create(APageSize));
  finally
    LQuery.Free;
  end;
end;

function TSmCari.GetCariById(ACariID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT c.*, ' +
      '  (SELECT TOP 1 Telefon FROM CariTelefon WHERE CariID = c.CariID AND Varsayilan = 1) AS VarsayilanTelefon, ' +
      '  (SELECT TOP 1 AdresSatiri FROM CariAdres WHERE CariID = c.CariID AND Varsayilan = 1) AS VarsayilanAdres ' +
      'FROM Cari c WHERE c.CariID = :CariID';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Cari bulunamadi');
      Exit;
    end;

    LObj := TJSONObject.Create;
    LObj.AddPair('cariId', TJSONNumber.Create(LQuery.FieldByName('CariID').AsInteger));
    LObj.AddPair('cariKod', LQuery.FieldByName('CariKod').AsString);
    LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
    LObj.AddPair('cariUnvani', LQuery.FieldByName('CariUnvani').AsString);
    LObj.AddPair('cariTip', LQuery.FieldByName('CariTip').AsString);
    LObj.AddPair('tcknVkn', LQuery.FieldByName('TCKN_VKN').AsString);
    LObj.AddPair('vergiDairesi', LQuery.FieldByName('VergiDairesi').AsString);
    LObj.AddPair('email', LQuery.FieldByName('Email').AsString);
    LObj.AddPair('riskLimiti', TJSONNumber.Create(LQuery.FieldByName('RiskLimiti').AsCurrency));
    LObj.AddPair('aktif', TJSONBool.Create(LQuery.FieldByName('Aktif').AsBoolean));
    LObj.AddPair('whatsAppTelefon', LQuery.FieldByName('WhatsAppTelefon').AsString);
    LObj.AddPair('telefon', LQuery.FieldByName('VarsayilanTelefon').AsString);
    LObj.AddPair('adres', LQuery.FieldByName('VarsayilanAdres').AsString);
    LObj.AddPair('konumEnlem', TJSONNumber.Create(LQuery.FieldByName('KonumEnlem').AsFloat));
    LObj.AddPair('konumBoylam', TJSONNumber.Create(LQuery.FieldByName('KonumBoylam').AsFloat));

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LObj);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.GetCariByTelefon(ATelefon: string): TJSONObject;
var
  LQuery: TFDQuery;
  LObj: TJSONObject;
  LNormalized: string;
begin
  Result := TJSONObject.Create;

  // Normalize telefon
  LNormalized := ATelefon.Replace(' ', '').Replace('(', '').Replace(')', '').Replace('-', '');
  if LNormalized.StartsWith('+90') then
    LNormalized := LNormalized.Substring(3)
  else if LNormalized.StartsWith('0') then
    LNormalized := LNormalized.Substring(1);

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT c.CariID, c.CariKod, c.CariAdi, c.CariTip, c.Aktif, c.WhatsAppTelefon, ' +
      '  ct.Telefon, ' +
      '  (SELECT TOP 1 AdresSatiri FROM CariAdres WHERE CariID = c.CariID AND Varsayilan = 1) AS Adres ' +
      'FROM Cari c ' +
      'INNER JOIN CariTelefon ct ON ct.CariID = c.CariID ' +
      'WHERE ct.TelefonNormalize = :Telefon OR ct.Telefon LIKE :TelLike';
    LQuery.ParamByName('Telefon').AsString := LNormalized;
    LQuery.ParamByName('TelLike').AsString := '%' + LNormalized;
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('found', TJSONBool.Create(False));
      Result.AddPair('data', TJSONNull.Create);
      Exit;
    end;

    LObj := TJSONObject.Create;
    LObj.AddPair('cariId', TJSONNumber.Create(LQuery.FieldByName('CariID').AsInteger));
    LObj.AddPair('cariKod', LQuery.FieldByName('CariKod').AsString);
    LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
    LObj.AddPair('cariTip', LQuery.FieldByName('CariTip').AsString);
    LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
    LObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
    LObj.AddPair('aktif', TJSONBool.Create(LQuery.FieldByName('Aktif').AsBoolean));

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('found', TJSONBool.Create(True));
    Result.AddPair('data', LObj);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.SearchCari(AArama: string; APage, APageSize: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
  LOffset: Integer;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  if APage < 1 then APage := 1;
  if APageSize < 1 then APageSize := 20;
  LOffset := (APage - 1) * APageSize;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT DISTINCT c.CariID, c.CariKod, c.CariAdi, c.CariTip, ' +
      '  (SELECT TOP 1 Telefon FROM CariTelefon WHERE CariID = c.CariID AND Varsayilan = 1) AS Telefon ' +
      'FROM Cari c ' +
      'LEFT JOIN CariTelefon ct ON ct.CariID = c.CariID ' +
      'WHERE c.Aktif = 1 AND ' +
      '  (c.CariAdi LIKE :Arama OR c.CariKod LIKE :Arama OR ct.Telefon LIKE :AramaTel) ' +
      'ORDER BY c.CariAdi ' +
      'OFFSET :Offset ROWS FETCH NEXT :PageSize ROWS ONLY';
    LQuery.ParamByName('Arama').AsString := '%' + AArama + '%';
    LQuery.ParamByName('AramaTel').AsString := '%' + AArama + '%';
    LQuery.ParamByName('Offset').AsInteger := LOffset;
    LQuery.ParamByName('PageSize').AsInteger := APageSize;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('cariId', TJSONNumber.Create(LQuery.FieldByName('CariID').AsInteger));
      LObj.AddPair('cariKod', LQuery.FieldByName('CariKod').AsString);
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('cariTip', LQuery.FieldByName('CariTip').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.CreateCari(ACariJson: string): TJSONObject;
var
  LQuery: TFDQuery;
  LJson: TJSONObject;
  LNewID: Integer;
begin
  Result := TJSONObject.Create;
  LJson := TJSONObject.ParseJSONValue(ACariJson) as TJSONObject;
  if LJson = nil then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz JSON');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'INSERT INTO Cari (CariKod, CariAdi, CariUnvani, CariTip, TCKN_VKN, ' +
      '  VergiDairesi, Email, Aktif, OlusturmaTarih, WhatsAppTelefon) ' +
      'VALUES (:CariKod, :CariAdi, :CariUnvani, :CariTip, :TCKN, ' +
      '  :VergiDairesi, :Email, 1, GETDATE(), :WhatsApp); ' +
      'SELECT SCOPE_IDENTITY() AS NewID';
    LQuery.ParamByName('CariKod').AsString := LJson.GetValue<string>('cariKod', '');
    LQuery.ParamByName('CariAdi').AsString := LJson.GetValue<string>('cariAdi', '');
    LQuery.ParamByName('CariUnvani').AsString := LJson.GetValue<string>('cariUnvani', '');
    LQuery.ParamByName('CariTip').AsString := LJson.GetValue<string>('cariTip', 'Musteri');
    LQuery.ParamByName('TCKN').AsString := LJson.GetValue<string>('tcknVkn', '');
    LQuery.ParamByName('VergiDairesi').AsString := LJson.GetValue<string>('vergiDairesi', '');
    LQuery.ParamByName('Email').AsString := LJson.GetValue<string>('email', '');
    LQuery.ParamByName('WhatsApp').AsString := LJson.GetValue<string>('whatsAppTelefon', '');
    LQuery.Open;

    LNewID := LQuery.FieldByName('NewID').AsInteger;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('cariId', TJSONNumber.Create(LNewID));
    Result.AddPair('message', 'Cari basariyla olusturuldu');
  finally
    LQuery.Free;
    LJson.Free;
  end;
end;

function TSmCari.UpdateCari(ACariID: Integer; ACariJson: string): TJSONObject;
var
  LQuery: TFDQuery;
  LJson: TJSONObject;
begin
  Result := TJSONObject.Create;
  LJson := TJSONObject.ParseJSONValue(ACariJson) as TJSONObject;
  if LJson = nil then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz JSON');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE Cari SET ' +
      '  CariAdi = :CariAdi, CariUnvani = :CariUnvani, CariTip = :CariTip, ' +
      '  TCKN_VKN = :TCKN, VergiDairesi = :VergiDairesi, Email = :Email, ' +
      '  WhatsAppTelefon = :WhatsApp ' +
      'WHERE CariID = :CariID';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.ParamByName('CariAdi').AsString := LJson.GetValue<string>('cariAdi', '');
    LQuery.ParamByName('CariUnvani').AsString := LJson.GetValue<string>('cariUnvani', '');
    LQuery.ParamByName('CariTip').AsString := LJson.GetValue<string>('cariTip', '');
    LQuery.ParamByName('TCKN').AsString := LJson.GetValue<string>('tcknVkn', '');
    LQuery.ParamByName('VergiDairesi').AsString := LJson.GetValue<string>('vergiDairesi', '');
    LQuery.ParamByName('Email').AsString := LJson.GetValue<string>('email', '');
    LQuery.ParamByName('WhatsApp').AsString := LJson.GetValue<string>('whatsAppTelefon', '');
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Cari guncellendi');
  finally
    LQuery.Free;
    LJson.Free;
  end;
end;

function TSmCari.GetCariAdresler(ACariID: Integer): TJSONObject;
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
      'SELECT * FROM CariAdres WHERE CariID = :CariID AND Aktif = 1 ORDER BY Varsayilan DESC';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('adresId', TJSONNumber.Create(LQuery.FieldByName('CariAdresID').AsInteger));
      LObj.AddPair('adresTipi', LQuery.FieldByName('AdresTipi').AsString);
      LObj.AddPair('adresSatiri', LQuery.FieldByName('AdresSatiri').AsString);
      LObj.AddPair('il', LQuery.FieldByName('Il').AsString);
      LObj.AddPair('ilce', LQuery.FieldByName('Ilce').AsString);
      LObj.AddPair('mahalle', LQuery.FieldByName('Mahalle').AsString);
      LObj.AddPair('caddeSokak', LQuery.FieldByName('CaddeSokak').AsString);
      LObj.AddPair('binaNo', LQuery.FieldByName('BinaNo').AsString);
      LObj.AddPair('daireNo', LQuery.FieldByName('DaireNo').AsString);
      LObj.AddPair('kat', LQuery.FieldByName('Kat').AsString);
      LObj.AddPair('kapiKodu', LQuery.FieldByName('KapiKodu').AsString);
      LObj.AddPair('adresTarifi', LQuery.FieldByName('AdresTarifi').AsString);
      LObj.AddPair('varsayilan', TJSONBool.Create(LQuery.FieldByName('Varsayilan').AsBoolean));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.GetCariTelefonlar(ACariID: Integer): TJSONObject;
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
      'SELECT * FROM CariTelefon WHERE CariID = :CariID AND Aktif = 1 ORDER BY Varsayilan DESC';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('telefonId', TJSONNumber.Create(LQuery.FieldByName('CariTelefonID').AsInteger));
      LObj.AddPair('telefonTipi', LQuery.FieldByName('TelefonTipi').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('varsayilan', TJSONBool.Create(LQuery.FieldByName('Varsayilan').AsBoolean));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.GetCariBakiye(ACariID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT ISNULL(SUM(Borc), 0) AS ToplamBorc, ISNULL(SUM(Alacak), 0) AS ToplamAlacak, ' +
      '  ISNULL(SUM(Borc), 0) - ISNULL(SUM(Alacak), 0) AS Bakiye ' +
      'FROM CariHareket WHERE CariID = :CariID';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('toplamBorc', TJSONNumber.Create(LQuery.FieldByName('ToplamBorc').AsCurrency));
    Result.AddPair('toplamAlacak', TJSONNumber.Create(LQuery.FieldByName('ToplamAlacak').AsCurrency));
    Result.AddPair('bakiye', TJSONNumber.Create(LQuery.FieldByName('Bakiye').AsCurrency));
  finally
    LQuery.Free;
  end;
end;

function TSmCari.GetCariHareketler(ACariID: Integer; APage, APageSize: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
  LOffset: Integer;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  if APage < 1 then APage := 1;
  if APageSize < 1 then APageSize := 20;
  LOffset := (APage - 1) * APageSize;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT * FROM CariHareket WHERE CariID = :CariID ' +
      'ORDER BY Tarih DESC ' +
      'OFFSET :Offset ROWS FETCH NEXT :PageSize ROWS ONLY';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.ParamByName('Offset').AsInteger := LOffset;
    LQuery.ParamByName('PageSize').AsInteger := APageSize;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('hareketId', TJSONNumber.Create(LQuery.FieldByName('CariHareketID').AsLargeInt));
      LObj.AddPair('tarih', DateToISO8601(LQuery.FieldByName('Tarih').AsDateTime));
      LObj.AddPair('belgeTipi', LQuery.FieldByName('BelgeTipi').AsString);
      LObj.AddPair('aciklama', LQuery.FieldByName('Aciklama').AsString);
      LObj.AddPair('borc', TJSONNumber.Create(LQuery.FieldByName('Borc').AsCurrency));
      LObj.AddPair('alacak', TJSONNumber.Create(LQuery.FieldByName('Alacak').AsCurrency));
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
