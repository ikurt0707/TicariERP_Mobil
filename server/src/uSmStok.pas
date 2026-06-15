unit uSmStok;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  Datasnap.DSServer, Datasnap.DSAuth, Datasnap.DSProviderDataModuleAdapter,
  FireDAC.Comp.Client;

type
  {$METHODINFO ON}
  TSmStok = class(TDSServerModule)
  public
    /// <summary>Tum aktif stoklari listele</summary>
    function GetStokList(APage, APageSize: Integer): TJSONObject;

    /// <summary>Hizli siparis icin aktif urunler</summary>
    function GetHizliSiparisUrunler: TJSONObject;

    /// <summary>StokID ile stok detay</summary>
    function GetStokById(AStokID: Integer): TJSONObject;

    /// <summary>Stok ara (ad, barkod, kod)</summary>
    function SearchStok(AArama: string): TJSONObject;

    /// <summary>Kategorileri listele</summary>
    function GetKategoriler: TJSONObject;

    /// <summary>Kategoriye gore urunler</summary>
    function GetStokByKategori(AKategoriID: Integer): TJSONObject;

    /// <summary>Yeni stok ekle (otomatik kod)</summary>
    function CreateStok(AStokJson: string): TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

{$R *.dfm}

uses
  uDM;

function TSmStok.GetStokList(APage, APageSize: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
  LOffset: Integer;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  if APage < 1 then APage := 1;
  if APageSize < 1 then APageSize := 50;
  LOffset := (APage - 1) * APageSize;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT StokID, StokKod, Barkod, StokAdi, Birim, SatisFiyat, KDV, ' +
      '  Kategori, AltKategori, HizliSiparisAktif, ResimUrl ' +
      'FROM Stok WHERE Aktif = 1 ' +
      'ORDER BY StokAdi ' +
      'OFFSET :Offset ROWS FETCH NEXT :PageSize ROWS ONLY';
    LQuery.ParamByName('Offset').AsInteger := LOffset;
    LQuery.ParamByName('PageSize').AsInteger := APageSize;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
      LObj.AddPair('stokKod', LQuery.FieldByName('StokKod').AsString);
      LObj.AddPair('barkod', LQuery.FieldByName('Barkod').AsString);
      LObj.AddPair('stokAdi', LQuery.FieldByName('StokAdi').AsString);
      LObj.AddPair('birim', LQuery.FieldByName('Birim').AsString);
      LObj.AddPair('satisFiyat', TJSONNumber.Create(LQuery.FieldByName('SatisFiyat').AsCurrency));
      LObj.AddPair('kdv', TJSONNumber.Create(LQuery.FieldByName('KDV').AsCurrency));
      LObj.AddPair('kategori', LQuery.FieldByName('Kategori').AsString);
      LObj.AddPair('altKategori', LQuery.FieldByName('AltKategori').AsString);
      LObj.AddPair('hizliSiparisAktif', TJSONBool.Create(LQuery.FieldByName('HizliSiparisAktif').AsBoolean));
      LObj.AddPair('resimUrl', LQuery.FieldByName('ResimUrl').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmStok.GetHizliSiparisUrunler: TJSONObject;
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
      'SELECT StokID, StokKod, StokAdi, Birim, SatisFiyat, KDV, Kategori, ResimUrl ' +
      'FROM Stok WHERE Aktif = 1 AND HizliSiparisAktif = 1 ' +
      'ORDER BY StokAdi';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
      LObj.AddPair('stokKod', LQuery.FieldByName('StokKod').AsString);
      LObj.AddPair('stokAdi', LQuery.FieldByName('StokAdi').AsString);
      LObj.AddPair('birim', LQuery.FieldByName('Birim').AsString);
      LObj.AddPair('satisFiyat', TJSONNumber.Create(LQuery.FieldByName('SatisFiyat').AsCurrency));
      LObj.AddPair('kdv', TJSONNumber.Create(LQuery.FieldByName('KDV').AsCurrency));
      LObj.AddPair('kategori', LQuery.FieldByName('Kategori').AsString);
      LObj.AddPair('resimUrl', LQuery.FieldByName('ResimUrl').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmStok.GetStokById(AStokID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'SELECT * FROM Stok WHERE StokID = :ID';
    LQuery.ParamByName('ID').AsInteger := AStokID;
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Stok bulunamadi');
      Exit;
    end;

    LObj := TJSONObject.Create;
    LObj.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
    LObj.AddPair('stokKod', LQuery.FieldByName('StokKod').AsString);
    LObj.AddPair('barkod', LQuery.FieldByName('Barkod').AsString);
    LObj.AddPair('stokAdi', LQuery.FieldByName('StokAdi').AsString);
    LObj.AddPair('birim', LQuery.FieldByName('Birim').AsString);
    LObj.AddPair('alisFiyat', TJSONNumber.Create(LQuery.FieldByName('AlisFiyat').AsCurrency));
    LObj.AddPair('satisFiyat', TJSONNumber.Create(LQuery.FieldByName('SatisFiyat').AsCurrency));
    LObj.AddPair('kdv', TJSONNumber.Create(LQuery.FieldByName('KDV').AsCurrency));
    LObj.AddPair('minStok', TJSONNumber.Create(LQuery.FieldByName('MinStok').AsCurrency));
    LObj.AddPair('kategori', LQuery.FieldByName('Kategori').AsString);
    LObj.AddPair('altKategori', LQuery.FieldByName('AltKategori').AsString);
    LObj.AddPair('marka', LQuery.FieldByName('Marka').AsString);
    LObj.AddPair('model', LQuery.FieldByName('Model').AsString);
    LObj.AddPair('resimUrl', LQuery.FieldByName('ResimUrl').AsString);
    LObj.AddPair('hizliSiparisAktif', TJSONBool.Create(LQuery.FieldByName('HizliSiparisAktif').AsBoolean));
    LObj.AddPair('aktif', TJSONBool.Create(LQuery.FieldByName('Aktif').AsBoolean));

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LObj);
  finally
    LQuery.Free;
  end;
end;

function TSmStok.SearchStok(AArama: string): TJSONObject;
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
      'SELECT StokID, StokKod, Barkod, StokAdi, Birim, SatisFiyat, Kategori ' +
      'FROM Stok WHERE Aktif = 1 AND ' +
      '  (StokAdi LIKE :Arama OR StokKod LIKE :Arama OR Barkod LIKE :Arama) ' +
      'ORDER BY StokAdi';
    LQuery.ParamByName('Arama').AsString := '%' + AArama + '%';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
      LObj.AddPair('stokKod', LQuery.FieldByName('StokKod').AsString);
      LObj.AddPair('barkod', LQuery.FieldByName('Barkod').AsString);
      LObj.AddPair('stokAdi', LQuery.FieldByName('StokAdi').AsString);
      LObj.AddPair('birim', LQuery.FieldByName('Birim').AsString);
      LObj.AddPair('satisFiyat', TJSONNumber.Create(LQuery.FieldByName('SatisFiyat').AsCurrency));
      LObj.AddPair('kategori', LQuery.FieldByName('Kategori').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmStok.GetKategoriler: TJSONObject;
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
      'SELECT k.KategoriID, k.KategoriAdi, ' +
      '  (SELECT COUNT(*) FROM Stok s WHERE s.KategoriID = k.KategoriID AND s.Aktif = 1) AS UrunSayisi ' +
      'FROM StokKategori k WHERE k.Aktif = 1 ORDER BY k.KategoriAdi';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('kategoriId', TJSONNumber.Create(LQuery.FieldByName('KategoriID').AsInteger));
      LObj.AddPair('kategoriAdi', LQuery.FieldByName('KategoriAdi').AsString);
      LObj.AddPair('urunSayisi', TJSONNumber.Create(LQuery.FieldByName('UrunSayisi').AsInteger));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmStok.GetStokByKategori(AKategoriID: Integer): TJSONObject;
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
      'SELECT StokID, StokKod, StokAdi, Birim, SatisFiyat, KDV, ResimUrl ' +
      'FROM Stok WHERE KategoriID = :KatID AND Aktif = 1 ORDER BY StokAdi';
    LQuery.ParamByName('KatID').AsInteger := AKategoriID;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
      LObj.AddPair('stokKod', LQuery.FieldByName('StokKod').AsString);
      LObj.AddPair('stokAdi', LQuery.FieldByName('StokAdi').AsString);
      LObj.AddPair('birim', LQuery.FieldByName('Birim').AsString);
      LObj.AddPair('satisFiyat', TJSONNumber.Create(LQuery.FieldByName('SatisFiyat').AsCurrency));
      LObj.AddPair('kdv', TJSONNumber.Create(LQuery.FieldByName('KDV').AsCurrency));
      LObj.AddPair('resimUrl', LQuery.FieldByName('ResimUrl').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmStok.CreateStok(AStokJson: string): TJSONObject;
var
  LQuery: TFDQuery;
  LJson: TJSONObject;
  LNewID: Integer;
  LNewKod: string;
begin
  Result := TJSONObject.Create;
  LJson := TJSONObject.ParseJSONValue(AStokJson) as TJSONObject;
  if LJson = nil then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz JSON');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    // Otomatik StokKod olustur
    LQuery.SQL.Text := 'SELECT ISNULL(MAX(CAST(REPLACE(StokKod, ''STK'', '''') AS INT)), 0) + 1 AS NextKod FROM Stok WHERE StokKod LIKE ''STK%''';
    LQuery.Open;
    LNewKod := 'STK' + FormatFloat('00000', LQuery.FieldByName('NextKod').AsInteger);
    LQuery.Close;

    LQuery.SQL.Text :=
      'INSERT INTO Stok (StokKod, StokAdi, Birim, AlisFiyat, SatisFiyat, KDV, ' +
      '  Kategori, Aktif, OlusturmaTarih, HizliSiparisAktif) ' +
      'VALUES (:StokKod, :StokAdi, ''Adet'', :AlisFiyat, :SatisFiyat, 0, ' +
      '  :Kategori, 1, GETDATE(), 1); ' +
      'SELECT SCOPE_IDENTITY() AS NewID';
    LQuery.ParamByName('StokKod').AsString := LNewKod;
    LQuery.ParamByName('StokAdi').AsString := LJson.GetValue<string>('stokAdi', '');
    LQuery.ParamByName('AlisFiyat').AsCurrency := LJson.GetValue<Double>('alisFiyat', 0);
    LQuery.ParamByName('SatisFiyat').AsCurrency := LJson.GetValue<Double>('satisFiyat', 0);
    LQuery.ParamByName('Kategori').AsString := LJson.GetValue<string>('kategori', '');
    LQuery.Open;

    LNewID := LQuery.FieldByName('NewID').AsInteger;
    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('stokId', TJSONNumber.Create(LNewID));
    Result.AddPair('stokKod', LNewKod);
    Result.AddPair('message', 'Stok basariyla eklendi');
  finally
    LQuery.Free;
    LJson.Free;
  end;
end;

end.
