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
    function GetStokList(ASearch: string; APage, APageSize: Integer): TJSONObject;
    function GetHizliSiparisUrunler: TJSONObject;
    function GetStokById(AStokID: Integer): TJSONObject;
    function SearchStok(AArama: string): TJSONObject;
    function GetKategoriler: TJSONObject;
    function GetStokByKategori(AKategoriID: Integer): TJSONObject;
    function SaveStok(AStokJson: string): TJSONObject;
    function FindExistingID(AStokKod, ABarkod, AStokAdi: string): TJSONObject;
    function ListHareket(AStokID: Integer): TJSONObject;
    function PasifYap(AStokID: Integer): TJSONObject;
    function SetHizliSiparisAktif(AStokID, AActive: Integer): TJSONObject;
    function ListStockFlag(ASearch, AFlagField: string; AOnlyMarked: Integer): TJSONObject;
    function SetStockFlag(AStokID: Integer; AFlagField: string; AActive: Integer): TJSONObject;
    function StokGiris(AStokID, ADepoID: Integer; AMiktar, ABirimFiyat: Double; AAciklama: string): TJSONObject;
    function StokCikis(AStokID, ADepoID: Integer; AMiktar, ABirimFiyat: Double; AAciklama: string): TJSONObject;
    function Transfer(AStokID, AKaynakDepoID, AHedefDepoID: Integer; AMiktar: Double): TJSONObject;
    function GetAvailableQty(AStokID, ADepoID: Integer): TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

{$R *.dfm}

uses
  uDM, Data.DB;

{ ---- Helper procedures ---- }

procedure EnsureQuickSiparisColumn(AQuery: TFDQuery);
const
  COLS: array[0..4] of string = ('HizliSiparisAktif', 'YemeksepetiKod', 'GetirKod', 'WhatsUp', 'SantralStok');
var
  I: Integer;
begin
  for I := Low(COLS) to High(COLS) do
  begin
    if (COLS[I] = 'HizliSiparisAktif') or (COLS[I] = 'WhatsUp') or (COLS[I] = 'SantralStok') then
    begin
      AQuery.SQL.Text :=
        'IF col_length(''dbo.Stok'', ''' + COLS[I] + ''') IS NULL ' +
        'ALTER TABLE dbo.Stok ADD ' + COLS[I] + ' BIT NOT NULL DEFAULT(0)';
    end
    else
    begin
      AQuery.SQL.Text :=
        'IF col_length(''dbo.Stok'', ''' + COLS[I] + ''') IS NULL ' +
        'ALTER TABLE dbo.Stok ADD ' + COLS[I] + ' NVARCHAR(100) NULL';
    end;
    AQuery.ExecSQL;
  end;
end;

function NormalizeStockFlagField(const AField: string): string;
begin
  Result := '';
  if SameText(AField, 'HizliSiparisAktif') then Result := 'HizliSiparisAktif'
  else if SameText(AField, 'WhatsUp') then Result := 'WhatsUp'
  else if SameText(AField, 'SantralStok') then Result := 'SantralStok';
end;

function NextStokCode(AQuery: TFDQuery): string;
var
  LNextNo: Integer;
begin
  Result := '';
  AQuery.SQL.Text := 'SELECT isnull(MAX(CAST(REPLACE(StokKod, ''STK'', '''') AS INT)), 0) + 1 AS NextKod FROM Stok WHERE StokKod LIKE ''STK%''';
  AQuery.Open;
  LNextNo := AQuery.FieldByName('NextKod').AsInteger;
  AQuery.Close;
  repeat
    Result := 'STK' + FormatFloat('00000', LNextNo);
    AQuery.SQL.Text := 'SELECT TOP 1 1 FROM dbo.Stok WHERE StokKod = :StokKod';
    AQuery.ParamByName('StokKod').AsString := Result;
    AQuery.Open;
    if AQuery.IsEmpty then
    begin
      AQuery.Close;
      Break;
    end;
    AQuery.Close;
    Inc(LNextNo);
  until False;
end;

{ ---- TSmStok ---- }

function TSmStok.GetStokList(ASearch: string; APage, APageSize: Integer): TJSONObject;
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
    EnsureQuickSiparisColumn(LQuery);

    LQuery.SQL.Text :=
      'SELECT S.StokID, S.StokKod, isnull(S.Barkod, '''') AS Barkod, S.StokAdi, ' +
      'isnull(S.Birim, ''Adet'') AS Birim, ' +
      'isnull(S.AlisFiyat, 0) AS AlisFiyat, isnull(S.SatisFiyat, 0) AS SatisFiyat, ' +
      'isnull(S.KDV, 0) AS KDV, isnull(S.MinStok, 0) AS MinStok, ' +
      'isnull(K.KategoriAdi, isnull(S.Kategori, '''')) AS Kategori, ' +
      'isnull(AK.AltKategoriAdi, isnull(S.AltKategori, '''')) AS AltKategori, ' +
      'isnull(M.MarkaAdi, isnull(S.Marka, '''')) AS Marka, ' +
      'isnull(MD.ModelAdi, isnull(S.Model, '''')) AS Model, ' +
      'isnull(S.ResimUrl, '''') AS ResimUrl, ' +
      'isnull(S.HizliSiparisAktif, 0) AS HizliSiparisAktif, ' +
      'isnull(S.YemeksepetiKod, '''') AS YemeksepetiKod, ' +
      'isnull(S.GetirKod, '''') AS GetirKod, ' +
      'isnull(S.WhatsUp, 0) AS WhatsUp, isnull(S.SantralStok, 0) AS SantralStok, ' +
      'isnull(DS.ToplamMiktar, 0) AS ToplamMiktar ' +
      'FROM dbo.Stok S ' +
      'LEFT JOIN dbo.StokKategori K ON K.KategoriID = S.KategoriID ' +
      'LEFT JOIN dbo.StokAltKategori AK ON AK.AltKategoriID = S.AltKategoriID ' +
      'LEFT JOIN dbo.StokMarka M ON M.MarkaID = S.MarkaID ' +
      'LEFT JOIN dbo.StokModel MD ON MD.ModelID = S.ModelID ' +
      'OUTER APPLY (SELECT SUM(isnull(SH.MiktarGiris, 0) - isnull(SH.MiktarCikis, 0)) AS ToplamMiktar FROM dbo.StokHareket SH WHERE SH.StokID = S.StokID) DS ' +
      'WHERE S.Aktif = 1 AND (:Arama = '''' OR S.StokAdi LIKE :LikeArama OR S.StokKod LIKE :LikeArama OR isnull(S.Barkod, '''') LIKE :LikeArama) ' +
      'ORDER BY S.StokAdi ' +
      'OFFSET :Offset ROWS FETCH NEXT :PageSize ROWS ONLY';
    LQuery.ParamByName('Arama').AsString := Trim(ASearch);
    LQuery.ParamByName('LikeArama').AsString := '%' + Trim(ASearch) + '%';
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
      LObj.AddPair('alisFiyat', TJSONNumber.Create(LQuery.FieldByName('AlisFiyat').AsCurrency));
      LObj.AddPair('satisFiyat', TJSONNumber.Create(LQuery.FieldByName('SatisFiyat').AsCurrency));
      LObj.AddPair('kdv', TJSONNumber.Create(LQuery.FieldByName('KDV').AsCurrency));
      LObj.AddPair('minStok', TJSONNumber.Create(LQuery.FieldByName('MinStok').AsCurrency));
      LObj.AddPair('kategori', LQuery.FieldByName('Kategori').AsString);
      LObj.AddPair('altKategori', LQuery.FieldByName('AltKategori').AsString);
      LObj.AddPair('marka', LQuery.FieldByName('Marka').AsString);
      LObj.AddPair('model', LQuery.FieldByName('Model').AsString);
      LObj.AddPair('resimUrl', LQuery.FieldByName('ResimUrl').AsString);
      LObj.AddPair('hizliSiparisAktif', TJSONBool.Create(LQuery.FieldByName('HizliSiparisAktif').AsInteger = 1));
      LObj.AddPair('yemeksepetiKod', LQuery.FieldByName('YemeksepetiKod').AsString);
      LObj.AddPair('getirKod', LQuery.FieldByName('GetirKod').AsString);
      LObj.AddPair('whatsUp', TJSONBool.Create(LQuery.FieldByName('WhatsUp').AsInteger = 1));
      LObj.AddPair('santralStok', TJSONBool.Create(LQuery.FieldByName('SantralStok').AsInteger = 1));
      LObj.AddPair('toplamMiktar', TJSONNumber.Create(LQuery.FieldByName('ToplamMiktar').AsCurrency));
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
    EnsureQuickSiparisColumn(LQuery);

    LQuery.SQL.Text :=
      'SELECT StokID, StokKod, StokAdi, Birim, SatisFiyat, KDV, Kategori, ResimUrl ' +
      'FROM Stok WHERE Aktif = 1 AND isnull(HizliSiparisAktif, 0) = 1 ' +
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
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    EnsureQuickSiparisColumn(LQuery);

    LQuery.SQL.Text :=
      'SELECT S.StokID, S.StokKod, isnull(S.Barkod, '''') AS Barkod, S.StokAdi, ' +
      'isnull(S.Birim, ''Adet'') AS Birim, ' +
      'isnull(S.AlisFiyat, 0) AS AlisFiyat, isnull(S.SatisFiyat, 0) AS SatisFiyat, ' +
      'isnull(S.KDV, 0) AS KDV, isnull(S.MinStok, 0) AS MinStok, ' +
      'isnull(K.KategoriAdi, isnull(S.Kategori, '''')) AS Kategori, ' +
      'isnull(AK.AltKategoriAdi, isnull(S.AltKategori, '''')) AS AltKategori, ' +
      'isnull(M.MarkaAdi, isnull(S.Marka, '''')) AS Marka, ' +
      'isnull(MD.ModelAdi, isnull(S.Model, '''')) AS Model, ' +
      'isnull(S.Renk, '''') AS Renk, isnull(S.BedenNo, '''') AS BedenNo, ' +
      'isnull(S.Cinsiyet, '''') AS Cinsiyet, isnull(S.Sezon, '''') AS Sezon, ' +
      'isnull(S.ResimUrl, '''') AS ResimUrl, S.Aktif, ' +
      'S.KategoriID, S.AltKategoriID, S.MarkaID, S.ModelID, ' +
      'isnull(S.HizliSiparisAktif, 0) AS HizliSiparisAktif, ' +
      'isnull(S.YemeksepetiKod, '''') AS YemeksepetiKod, ' +
      'isnull(S.GetirKod, '''') AS GetirKod, ' +
      'isnull(S.WhatsUp, 0) AS WhatsUp, isnull(S.SantralStok, 0) AS SantralStok, ' +
      'isnull(DS.ToplamMiktar, 0) AS ToplamMiktar ' +
      'FROM dbo.Stok S ' +
      'LEFT JOIN dbo.StokKategori K ON K.KategoriID = S.KategoriID ' +
      'LEFT JOIN dbo.StokAltKategori AK ON AK.AltKategoriID = S.AltKategoriID ' +
      'LEFT JOIN dbo.StokMarka M ON M.MarkaID = S.MarkaID ' +
      'LEFT JOIN dbo.StokModel MD ON MD.ModelID = S.ModelID ' +
      'OUTER APPLY (SELECT SUM(isnull(SH.MiktarGiris, 0) - isnull(SH.MiktarCikis, 0)) AS ToplamMiktar FROM dbo.StokHareket SH WHERE SH.StokID = S.StokID) DS ' +
      'WHERE S.StokID = :ID';
    LQuery.ParamByName('ID').AsInteger := AStokID;
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Stok bulunamadi');
      Exit;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    var LObj := TJSONObject.Create;
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
    LObj.AddPair('renk', LQuery.FieldByName('Renk').AsString);
    LObj.AddPair('bedenNo', LQuery.FieldByName('BedenNo').AsString);
    LObj.AddPair('cinsiyet', LQuery.FieldByName('Cinsiyet').AsString);
    LObj.AddPair('sezon', LQuery.FieldByName('Sezon').AsString);
    LObj.AddPair('resimUrl', LQuery.FieldByName('ResimUrl').AsString);
    LObj.AddPair('aktif', TJSONBool.Create(LQuery.FieldByName('Aktif').AsBoolean));
    LObj.AddPair('kategoriId', TJSONNumber.Create(LQuery.FieldByName('KategoriID').AsInteger));
    LObj.AddPair('altKategoriId', TJSONNumber.Create(LQuery.FieldByName('AltKategoriID').AsInteger));
    LObj.AddPair('markaId', TJSONNumber.Create(LQuery.FieldByName('MarkaID').AsInteger));
    LObj.AddPair('modelId', TJSONNumber.Create(LQuery.FieldByName('ModelID').AsInteger));
    LObj.AddPair('hizliSiparisAktif', TJSONBool.Create(LQuery.FieldByName('HizliSiparisAktif').AsInteger = 1));
    LObj.AddPair('yemeksepetiKod', LQuery.FieldByName('YemeksepetiKod').AsString);
    LObj.AddPair('getirKod', LQuery.FieldByName('GetirKod').AsString);
    LObj.AddPair('whatsUp', TJSONBool.Create(LQuery.FieldByName('WhatsUp').AsInteger = 1));
    LObj.AddPair('santralStok', TJSONBool.Create(LQuery.FieldByName('SantralStok').AsInteger = 1));
    LObj.AddPair('toplamMiktar', TJSONNumber.Create(LQuery.FieldByName('ToplamMiktar').AsCurrency));
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
      'SELECT S.StokID, S.StokKod, isnull(S.Barkod, '''') AS Barkod, S.StokAdi, ' +
      'isnull(S.Birim, ''Adet'') AS Birim, isnull(S.SatisFiyat, 0) AS SatisFiyat, ' +
      'isnull(K.KategoriAdi, isnull(S.Kategori, '''')) AS Kategori ' +
      'FROM Stok S ' +
      'LEFT JOIN dbo.StokKategori K ON K.KategoriID = S.KategoriID ' +
      'WHERE S.Aktif = 1 AND ' +
      '  (S.StokAdi LIKE :Arama OR S.StokKod LIKE :Arama OR isnull(S.Barkod, '''') LIKE :Arama) ' +
      'ORDER BY S.StokAdi';
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
      'SELECT StokID, StokKod, StokAdi, isnull(Birim, ''Adet'') AS Birim, ' +
      'isnull(SatisFiyat, 0) AS SatisFiyat, isnull(KDV, 0) AS KDV, isnull(ResimUrl, '''') AS ResimUrl ' +
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

function TSmStok.SaveStok(AStokJson: string): TJSONObject;
var
  LQuery: TFDQuery;
  LJson: TJSONObject;
  LStokID, LNewID: Integer;
  LStokKod, LBarkod, LStokAdi, LBirim: string;
  LKategori, LAltKategori, LMarka, LModel: string;
  LRenk, LBedenNo, LCinsiyet, LSezon, LResimUrl: string;
  LYemeksepetiKod, LGetirKod: string;
  LKategoriID, LAltKategoriID, LMarkaID, LModelID: Integer;
  LAlisFiyat, LSatisFiyat, LKDV, LMinStok: Double;
  LHizliSiparisAktif: Boolean;
begin
  Result := TJSONObject.Create;
  LJson := TJSONObject.ParseJSONValue(AStokJson) as TJSONObject;
  if LJson = nil then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz JSON');
    Exit;
  end;

  try
    LStokID := LJson.GetValue<Integer>('stokId', 0);
    LStokKod := LJson.GetValue<string>('stokKod', '');
    LBarkod := LJson.GetValue<string>('barkod', '');
    LStokAdi := LJson.GetValue<string>('stokAdi', '');
    LBirim := LJson.GetValue<string>('birim', 'Adet');
    LKategori := LJson.GetValue<string>('kategori', '');
    LAltKategori := LJson.GetValue<string>('altKategori', '');
    LMarka := LJson.GetValue<string>('marka', '');
    LModel := LJson.GetValue<string>('model', '');
    LRenk := LJson.GetValue<string>('renk', '');
    LBedenNo := LJson.GetValue<string>('bedenNo', '');
    LCinsiyet := LJson.GetValue<string>('cinsiyet', '');
    LSezon := LJson.GetValue<string>('sezon', '');
    LResimUrl := LJson.GetValue<string>('resimUrl', '');
    LKategoriID := LJson.GetValue<Integer>('kategoriId', 0);
    LAltKategoriID := LJson.GetValue<Integer>('altKategoriId', 0);
    LMarkaID := LJson.GetValue<Integer>('markaId', 0);
    LModelID := LJson.GetValue<Integer>('modelId', 0);
    LAlisFiyat := LJson.GetValue<Double>('alisFiyat', 0);
    LSatisFiyat := LJson.GetValue<Double>('satisFiyat', 0);
    LKDV := LJson.GetValue<Double>('kdv', 0);
    LMinStok := LJson.GetValue<Double>('minStok', 0);
    LHizliSiparisAktif := LJson.GetValue<Boolean>('hizliSiparisAktif', False);
    LYemeksepetiKod := LJson.GetValue<string>('yemeksepetiKod', '');
    LGetirKod := LJson.GetValue<string>('getirKod', '');

    if Trim(LStokAdi) = '' then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Stok adi bos olamaz');
      Exit;
    end;

    LQuery := DM.GetQuery;
    try
      EnsureQuickSiparisColumn(LQuery);

      { -- Barcode duplicate check -- }
      if Trim(LBarkod) <> '' then
      begin
        LQuery.SQL.Text :=
          'SELECT TOP 1 StokAdi FROM dbo.Stok WHERE Barkod = :Barkod AND StokID <> :StokID AND Aktif = 1';
        LQuery.ParamByName('Barkod').AsString := Trim(LBarkod);
        LQuery.ParamByName('StokID').AsInteger := LStokID;
        LQuery.Open;
        if not LQuery.IsEmpty then
        begin
          Result.AddPair('success', TJSONBool.Create(False));
          Result.AddPair('message', 'Bu barkod "' + LQuery.Fields[0].AsString + '" stokunda kayitli');
          Exit;
        end;
        LQuery.Close;
      end;

      { -- Auto-generate StokKod if empty -- }
      if Trim(LStokKod) = '' then
        LStokKod := NextStokCode(LQuery);

      { -- Insert or Update -- }
      if LStokID = 0 then
        LQuery.SQL.Text :=
          'INSERT INTO Stok (StokKod, Barkod, StokAdi, Birim, Kategori, AltKategori, Marka, Model, ' +
          '  KategoriID, AltKategoriID, MarkaID, ModelID, Renk, BedenNo, Cinsiyet, Sezon, ResimUrl, ' +
          '  AlisFiyat, SatisFiyat, KDV, MinStok, HizliSiparisAktif, YemeksepetiKod, GetirKod, Aktif, OlusturmaTarih) ' +
          'VALUES (:StokKod, :Barkod, :StokAdi, :Birim, :Kategori, :AltKategori, :Marka, :Model, ' +
          '  :KategoriID, :AltKategoriID, :MarkaID, :ModelID, :Renk, :BedenNo, :Cinsiyet, :Sezon, :ResimUrl, ' +
          '  :AlisFiyat, :SatisFiyat, :KDV, :MinStok, :HizliSiparisAktif, :YemeksepetiKod, :GetirKod, 1, GETDATE()); ' +
          'SELECT CAST(SCOPE_IDENTITY() AS INT) AS StokID'
      else
        LQuery.SQL.Text :=
          'UPDATE Stok SET StokKod = :StokKod, Barkod = :Barkod, StokAdi = :StokAdi, Birim = :Birim, ' +
          '  Kategori = :Kategori, AltKategori = :AltKategori, Marka = :Marka, Model = :Model, ' +
          '  KategoriID = :KategoriID, AltKategoriID = :AltKategoriID, MarkaID = :MarkaID, ModelID = :ModelID, ' +
          '  Renk = :Renk, BedenNo = :BedenNo, Cinsiyet = :Cinsiyet, Sezon = :Sezon, ResimUrl = :ResimUrl, ' +
          '  AlisFiyat = :AlisFiyat, SatisFiyat = :SatisFiyat, KDV = :KDV, MinStok = :MinStok, ' +
          '  HizliSiparisAktif = :HizliSiparisAktif, YemeksepetiKod = :YemeksepetiKod, GetirKod = :GetirKod ' +
          'WHERE StokID = :StokID; ' +
          'SELECT :StokID AS StokID';

      LQuery.ParamByName('StokKod').AsString := Trim(LStokKod);
      LQuery.ParamByName('Barkod').DataType := ftString;
      if Trim(LBarkod) <> '' then
        LQuery.ParamByName('Barkod').AsString := Trim(LBarkod)
      else
        LQuery.ParamByName('Barkod').Clear;
      LQuery.ParamByName('StokAdi').AsString := Trim(LStokAdi);
      LQuery.ParamByName('Birim').AsString := Trim(LBirim);
      LQuery.ParamByName('Kategori').AsString := Trim(LKategori);
      LQuery.ParamByName('AltKategori').AsString := Trim(LAltKategori);
      LQuery.ParamByName('Marka').AsString := Trim(LMarka);
      LQuery.ParamByName('Model').AsString := Trim(LModel);
      LQuery.ParamByName('KategoriID').DataType := ftInteger;
      if LKategoriID > 0 then LQuery.ParamByName('KategoriID').AsInteger := LKategoriID else LQuery.ParamByName('KategoriID').Clear;
      LQuery.ParamByName('AltKategoriID').DataType := ftInteger;
      if LAltKategoriID > 0 then LQuery.ParamByName('AltKategoriID').AsInteger := LAltKategoriID else LQuery.ParamByName('AltKategoriID').Clear;
      LQuery.ParamByName('MarkaID').DataType := ftInteger;
      if LMarkaID > 0 then LQuery.ParamByName('MarkaID').AsInteger := LMarkaID else LQuery.ParamByName('MarkaID').Clear;
      LQuery.ParamByName('ModelID').DataType := ftInteger;
      if LModelID > 0 then LQuery.ParamByName('ModelID').AsInteger := LModelID else LQuery.ParamByName('ModelID').Clear;
      LQuery.ParamByName('Renk').AsString := Trim(LRenk);
      LQuery.ParamByName('BedenNo').AsString := Trim(LBedenNo);
      LQuery.ParamByName('Cinsiyet').AsString := Trim(LCinsiyet);
      LQuery.ParamByName('Sezon').AsString := Trim(LSezon);
      LQuery.ParamByName('ResimUrl').AsString := Trim(LResimUrl);
      LQuery.ParamByName('AlisFiyat').AsCurrency := LAlisFiyat;
      LQuery.ParamByName('SatisFiyat').AsCurrency := LSatisFiyat;
      LQuery.ParamByName('KDV').AsCurrency := LKDV;
      LQuery.ParamByName('MinStok').AsCurrency := LMinStok;
      LQuery.ParamByName('HizliSiparisAktif').AsBoolean := LHizliSiparisAktif;
      LQuery.ParamByName('YemeksepetiKod').AsString := Trim(LYemeksepetiKod);
      LQuery.ParamByName('GetirKod').AsString := Trim(LGetirKod);
      if LStokID <> 0 then
        LQuery.ParamByName('StokID').AsInteger := LStokID;
      LQuery.Open;

      LNewID := LQuery.FieldByName('StokID').AsInteger;
      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('stokId', TJSONNumber.Create(LNewID));
      Result.AddPair('stokKod', LStokKod);
      if LStokID = 0 then
        Result.AddPair('message', 'Stok olusturuldu')
      else
        Result.AddPair('message', 'Stok guncellendi');
    finally
      LQuery.Free;
    end;
  finally
    LJson.Free;
  end;
end;

function TSmStok.FindExistingID(AStokKod, ABarkod, AStokAdi: string): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT TOP 1 StokID, StokKod, StokAdi FROM dbo.Stok WHERE Aktif = 1 AND (' +
      '  (:StokKod <> '''' AND StokKod = :StokKod) OR ' +
      '  (:Barkod <> '''' AND Barkod = :Barkod) OR ' +
      '  (:StokAdi <> '''' AND StokAdi = :StokAdi) ' +
      ')';
    LQuery.ParamByName('StokKod').AsString := Trim(AStokKod);
    LQuery.ParamByName('Barkod').AsString := Trim(ABarkod);
    LQuery.ParamByName('StokAdi').AsString := Trim(AStokAdi);
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('found', TJSONBool.Create(False));
      Exit;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('found', TJSONBool.Create(True));
    Result.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
    Result.AddPair('stokKod', LQuery.FieldByName('StokKod').AsString);
    Result.AddPair('stokAdi', LQuery.FieldByName('StokAdi').AsString);
  finally
    LQuery.Free;
  end;
end;

function TSmStok.ListHareket(AStokID: Integer): TJSONObject;
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
      'SELECT TOP 500 SH.StokHareketID, SH.DepoID, SH.IslemTipi, SH.BelgeTipi, SH.BelgeID, ' +
      'SH.MiktarGiris, SH.MiktarCikis, SH.BirimFiyat, SH.Aciklama, SH.IslemTarih ' +
      'FROM dbo.StokHareket SH WHERE SH.StokID = :StokID ORDER BY SH.IslemTarih DESC';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('stokHareketId', TJSONNumber.Create(LQuery.FieldByName('StokHareketID').AsLargeInt));
      LObj.AddPair('depoId', TJSONNumber.Create(LQuery.FieldByName('DepoID').AsInteger));
      LObj.AddPair('islemTipi', LQuery.FieldByName('IslemTipi').AsString);
      LObj.AddPair('belgeTipi', LQuery.FieldByName('BelgeTipi').AsString);
      LObj.AddPair('belgeId', TJSONNumber.Create(LQuery.FieldByName('BelgeID').AsLargeInt));
      LObj.AddPair('miktarGiris', TJSONNumber.Create(LQuery.FieldByName('MiktarGiris').AsCurrency));
      LObj.AddPair('miktarCikis', TJSONNumber.Create(LQuery.FieldByName('MiktarCikis').AsCurrency));
      LObj.AddPair('birimFiyat', TJSONNumber.Create(LQuery.FieldByName('BirimFiyat').AsCurrency));
      LObj.AddPair('aciklama', LQuery.FieldByName('Aciklama').AsString);
      LObj.AddPair('islemTarih', DateToISO8601(LQuery.FieldByName('IslemTarih').AsDateTime));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmStok.PasifYap(AStokID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  if AStokID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'StokID zorunludur');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'SELECT TOP 1 1 FROM dbo.StokHareket WHERE StokID = :StokID';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.Open;
    if not LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Bu stokta hareket var. Hareketli stok pasife alinamaz');
      Exit;
    end;
    LQuery.Close;

    LQuery.SQL.Text := 'UPDATE dbo.Stok SET Aktif = 0 WHERE StokID = :StokID';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Stok pasife alindi');
  finally
    LQuery.Free;
  end;
end;

function TSmStok.SetHizliSiparisAktif(AStokID, AActive: Integer): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    EnsureQuickSiparisColumn(LQuery);
    LQuery.SQL.Text := 'UPDATE dbo.Stok SET HizliSiparisAktif = :Val WHERE StokID = :StokID';
    LQuery.ParamByName('Val').AsBoolean := (AActive = 1);
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Guncellendi');
  finally
    LQuery.Free;
  end;
end;

function TSmStok.ListStockFlag(ASearch, AFlagField: string; AOnlyMarked: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
  LNorm: string;
begin
  Result := TJSONObject.Create;
  LNorm := NormalizeStockFlagField(AFlagField);
  if LNorm = '' then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz flag alani: ' + AFlagField);
    Exit;
  end;

  LArray := TJSONArray.Create;
  LQuery := DM.GetQuery;
  try
    EnsureQuickSiparisColumn(LQuery);

    LQuery.SQL.Text :=
      'SELECT S.StokID, S.StokKod, S.StokAdi, isnull(S.SatisFiyat, 0) AS SatisFiyat, ' +
      'isnull(S.' + LNorm + ', 0) AS FlagValue ' +
      'FROM dbo.Stok S WHERE S.Aktif = 1 ' +
      'AND (:Arama = '''' OR S.StokAdi LIKE :LikeArama OR S.StokKod LIKE :LikeArama) ' +
      'AND (:OnlyMarked = 0 OR isnull(S.' + LNorm + ', 0) = 1) ' +
      'ORDER BY S.StokAdi';
    LQuery.ParamByName('Arama').AsString := Trim(ASearch);
    LQuery.ParamByName('LikeArama').AsString := '%' + Trim(ASearch) + '%';
    LQuery.ParamByName('OnlyMarked').AsInteger := AOnlyMarked;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
      LObj.AddPair('stokKod', LQuery.FieldByName('StokKod').AsString);
      LObj.AddPair('stokAdi', LQuery.FieldByName('StokAdi').AsString);
      LObj.AddPair('satisFiyat', TJSONNumber.Create(LQuery.FieldByName('SatisFiyat').AsCurrency));
      LObj.AddPair('flagValue', TJSONBool.Create(LQuery.FieldByName('FlagValue').AsInteger = 1));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmStok.SetStockFlag(AStokID: Integer; AFlagField: string; AActive: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LNorm: string;
begin
  Result := TJSONObject.Create;
  LNorm := NormalizeStockFlagField(AFlagField);
  if LNorm = '' then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz flag alani: ' + AFlagField);
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    EnsureQuickSiparisColumn(LQuery);
    LQuery.SQL.Text := 'UPDATE dbo.Stok SET ' + LNorm + ' = :Val WHERE StokID = :StokID';
    LQuery.ParamByName('Val').AsBoolean := (AActive = 1);
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', LNorm + ' guncellendi');
  finally
    LQuery.Free;
  end;
end;

function TSmStok.StokGiris(AStokID, ADepoID: Integer; AMiktar, ABirimFiyat: Double; AAciklama: string): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  if (AStokID <= 0) or (AMiktar <= 0) then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'StokID ve miktar zorunludur');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'INSERT INTO dbo.StokHareket (StokID, DepoID, IslemTipi, BelgeTipi, BelgeID, ' +
      '  MiktarGiris, MiktarCikis, BirimFiyat, Aciklama, IslemTarih) ' +
      'VALUES (:StokID, :DepoID, ''Giris'', ''Manuel Giris'', 0, :Miktar, 0, :BirimFiyat, :Aciklama, SYSDATETIME())';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ParamByName('DepoID').AsInteger := ADepoID;
    LQuery.ParamByName('Miktar').AsCurrency := AMiktar;
    LQuery.ParamByName('BirimFiyat').AsCurrency := ABirimFiyat;
    LQuery.ParamByName('Aciklama').AsString := Trim(AAciklama);
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Stok girisi yapildi');
  finally
    LQuery.Free;
  end;
end;

function TSmStok.StokCikis(AStokID, ADepoID: Integer; AMiktar, ABirimFiyat: Double; AAciklama: string): TJSONObject;
var
  LQuery: TFDQuery;
  LAvail: Double;
begin
  Result := TJSONObject.Create;
  if (AStokID <= 0) or (AMiktar <= 0) then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'StokID ve miktar zorunludur');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT isnull(SUM(isnull(MiktarGiris, 0) - isnull(MiktarCikis, 0)), 0) AS Avail ' +
      'FROM dbo.StokHareket WHERE StokID = :StokID' +
      ' AND (:DepoID = 0 OR DepoID = :DepoID)';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ParamByName('DepoID').AsInteger := ADepoID;
    LQuery.Open;
    LAvail := LQuery.FieldByName('Avail').AsCurrency;
    LQuery.Close;

    if AMiktar > LAvail then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Yetersiz stok. Mevcut: ' + FloatToStr(LAvail));
      Exit;
    end;

    LQuery.SQL.Text :=
      'INSERT INTO dbo.StokHareket (StokID, DepoID, IslemTipi, BelgeTipi, BelgeID, ' +
      '  MiktarGiris, MiktarCikis, BirimFiyat, Aciklama, IslemTarih) ' +
      'VALUES (:StokID, :DepoID, ''Cikis'', ''Manuel Cikis'', 0, 0, :Miktar, :BirimFiyat, :Aciklama, SYSDATETIME())';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ParamByName('DepoID').AsInteger := ADepoID;
    LQuery.ParamByName('Miktar').AsCurrency := AMiktar;
    LQuery.ParamByName('BirimFiyat').AsCurrency := ABirimFiyat;
    LQuery.ParamByName('Aciklama').AsString := Trim(AAciklama);
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Stok cikisi yapildi');
  finally
    LQuery.Free;
  end;
end;

function TSmStok.Transfer(AStokID, AKaynakDepoID, AHedefDepoID: Integer; AMiktar: Double): TJSONObject;
var
  LQuery: TFDQuery;
  LAvail: Double;
begin
  Result := TJSONObject.Create;
  if (AStokID <= 0) or (AMiktar <= 0) then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'StokID ve miktar zorunludur');
    Exit;
  end;
  if AKaynakDepoID = AHedefDepoID then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Kaynak ve hedef depo ayni olamaz');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT isnull(SUM(isnull(MiktarGiris, 0) - isnull(MiktarCikis, 0)), 0) AS Avail ' +
      'FROM dbo.StokHareket WHERE StokID = :StokID AND DepoID = :DepoID';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ParamByName('DepoID').AsInteger := AKaynakDepoID;
    LQuery.Open;
    LAvail := LQuery.FieldByName('Avail').AsCurrency;
    LQuery.Close;

    if AMiktar > LAvail then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Kaynak depoda yetersiz stok. Mevcut: ' + FloatToStr(LAvail));
      Exit;
    end;

    LQuery.Connection.StartTransaction;
    try
      LQuery.SQL.Text :=
        'INSERT INTO dbo.StokHareket (StokID, DepoID, IslemTipi, BelgeTipi, BelgeID, ' +
        '  MiktarGiris, MiktarCikis, BirimFiyat, Aciklama, IslemTarih) ' +
        'VALUES (:StokID, :DepoID, ''Cikis'', ''Transfer Cikis'', 0, 0, :Miktar, 0, :Aciklama, SYSDATETIME())';
      LQuery.ParamByName('StokID').AsInteger := AStokID;
      LQuery.ParamByName('DepoID').AsInteger := AKaynakDepoID;
      LQuery.ParamByName('Miktar').AsCurrency := AMiktar;
      LQuery.ParamByName('Aciklama').AsString := 'Transfer -> Depo ' + IntToStr(AHedefDepoID);
      LQuery.ExecSQL;

      LQuery.SQL.Text :=
        'INSERT INTO dbo.StokHareket (StokID, DepoID, IslemTipi, BelgeTipi, BelgeID, ' +
        '  MiktarGiris, MiktarCikis, BirimFiyat, Aciklama, IslemTarih) ' +
        'VALUES (:StokID, :DepoID, ''Giris'', ''Transfer Giris'', 0, :Miktar, 0, 0, :Aciklama, SYSDATETIME())';
      LQuery.ParamByName('StokID').AsInteger := AStokID;
      LQuery.ParamByName('DepoID').AsInteger := AHedefDepoID;
      LQuery.ParamByName('Miktar').AsCurrency := AMiktar;
      LQuery.ParamByName('Aciklama').AsString := 'Transfer <- Depo ' + IntToStr(AKaynakDepoID);
      LQuery.ExecSQL;

      LQuery.Connection.Commit;

      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('message', 'Transfer tamamlandi');
    except
      on E: Exception do
      begin
        if LQuery.Connection.InTransaction then
          LQuery.Connection.Rollback;
        Result.AddPair('success', TJSONBool.Create(False));
        Result.AddPair('message', 'Transfer hatasi: ' + E.Message);
      end;
    end;
  finally
    LQuery.Free;
  end;
end;

function TSmStok.GetAvailableQty(AStokID, ADepoID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT isnull(SUM(isnull(MiktarGiris, 0) - isnull(MiktarCikis, 0)), 0) AS Miktar ' +
      'FROM dbo.StokHareket WHERE StokID = :StokID' +
      ' AND (:DepoID = 0 OR DepoID = :DepoID)';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ParamByName('DepoID').AsInteger := ADepoID;
    LQuery.Open;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('miktar', TJSONNumber.Create(LQuery.FieldByName('Miktar').AsCurrency));
  finally
    LQuery.Free;
  end;
end;

end.
