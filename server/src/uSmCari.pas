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
    function SearchCari(AQuery: string; APage, APageSize: Integer): TJSONObject;
    function FindCustomerByPhone(ATelefon: string): TJSONObject;
    function FindCustomerByName(AName: string): TJSONObject;
    function InsertNewCustomerFull(ACariAdi, ATelefon, AMahalle, ACadde,
      ABinaNo, ADaireNo, AKat, ABlok, ASite: string): TJSONObject;
    function CreateCariMobil(AAdSoyad, ATelefon, AAdres: string): TJSONObject;
    function ImportContacts(AContactsJson: string): TJSONObject;
    function ListCouriers: TJSONObject;
    function ListFastOrderStocks: TJSONObject;
    function ListQuickProducts: TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

{$R *.dfm}

uses
  uDM, System.StrUtils, System.DateUtils;

function NextCariCode(AQuery: TFDQuery): string;
var
  LNextNo: Integer;
begin
  Result := '';
  AQuery.SQL.Text := 'SELECT isnull(MAX(CariID), 0) + 1 AS NextNo FROM dbo.Cari';
  AQuery.Open;
  LNextNo := AQuery.FieldByName('NextNo').AsInteger;
  AQuery.Close;

  repeat
    Result := 'CAR' + FormatFloat('0000', LNextNo);
    AQuery.SQL.Text := 'SELECT TOP 1 1 FROM dbo.Cari WHERE CariKod = :CariKod';
    AQuery.ParamByName('CariKod').AsString := Result;
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

function NormalizePhone(const APhone: string): string;
begin
  Result := APhone;
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
  Result := StringReplace(Result, '(', '', [rfReplaceAll]);
  Result := StringReplace(Result, ')', '', [rfReplaceAll]);
  Result := StringReplace(Result, '+90', '', [rfReplaceAll]);
  if (Length(Result) > 10) and (Copy(Result, 1, 2) = '90') then
    Result := Copy(Result, 3, MaxInt);
end;

function TSmCari.SearchCari(AQuery: string; APage, APageSize: Integer): TJSONObject;
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
      'SELECT C.CariID, C.CariKod, C.CariAdi, isnull(C.CariUnvani, '''') AS CariUnvani, ' +
      'isnull(P1.Telefon, '''') AS Telefon1, ' +
      'isnull(A1.AdresSatiri, '''') AS Adres, isnull(A1.Mahalle, '''') AS Mahalle, ' +
      'isnull((SELECT SUM(isnull(H.Borc, 0) - isnull(H.Alacak, 0)) FROM CariHareket H WHERE H.CariID = C.CariID), 0) AS CariBorc ' +
      'FROM Cari C ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 ORDER BY T.Varsayilan DESC, T.CariTelefonID) P1 ' +
      'OUTER APPLY (SELECT TOP 1 A.AdresSatiri, A.Mahalle FROM CariAdres A WHERE A.CariID = C.CariID AND A.Aktif = 1 ORDER BY A.Varsayilan DESC, A.CariAdresID) A1 ' +
      'WHERE C.Aktif = 1 AND (:Arama = '''' OR C.CariAdi LIKE :LikeArama OR C.CariKod LIKE :LikeArama ' +
      '  OR EXISTS (SELECT 1 FROM CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 AND T.Telefon LIKE :LikeArama)) ' +
      'ORDER BY C.CariID DESC ' +
      'OFFSET :Offset ROWS FETCH NEXT :PageSize ROWS ONLY';
    LQuery.ParamByName('Arama').AsString := Trim(AQuery);
    LQuery.ParamByName('LikeArama').AsString := '%' + Trim(AQuery) + '%';
    LQuery.ParamByName('Offset').AsInteger := LOffset;
    LQuery.ParamByName('PageSize').AsInteger := APageSize;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('cariId', TJSONNumber.Create(LQuery.FieldByName('CariID').AsInteger));
      LObj.AddPair('cariKod', LQuery.FieldByName('CariKod').AsString);
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('cariUnvani', LQuery.FieldByName('CariUnvani').AsString);
      LObj.AddPair('telefon1', LQuery.FieldByName('Telefon1').AsString);
      LObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
      LObj.AddPair('mahalle', LQuery.FieldByName('Mahalle').AsString);
      LObj.AddPair('cariBorc', TJSONNumber.Create(LQuery.FieldByName('CariBorc').AsCurrency));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.FindCustomerByPhone(ATelefon: string): TJSONObject;
var
  LQuery: TFDQuery;
  LNorm: string;
begin
  Result := TJSONObject.Create;
  LNorm := NormalizePhone(ATelefon);
  if LNorm = '' then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Telefon numarasi giriniz');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT TOP 1 C.CariID, C.CariAdi, isnull(C.CariUnvani, '''') AS CariUnvani, ' +
      'isnull(P1.Telefon, '''') AS Telefon1, isnull(P2.Telefon, '''') AS Telefon2, ' +
      'isnull(A1.AdresSatiri, '''') AS Adres, isnull(A1.Mahalle, '''') AS Mahalle, ' +
      'isnull(A1.Ilce, '''') AS Ilce, isnull(A1.Il, '''') AS Il, ' +
      'isnull((SELECT SUM(isnull(H.Borc, 0) - isnull(H.Alacak, 0)) FROM CariHareket H WHERE H.CariID = C.CariID), 0) AS CariBorc ' +
      'FROM Cari C ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 ORDER BY T.Varsayilan DESC, T.CariTelefonID) P1 ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 AND isnull(P1.Telefon, '''') <> isnull(T.Telefon, '''') ORDER BY T.Varsayilan DESC, T.CariTelefonID) P2 ' +
      'OUTER APPLY (SELECT TOP 1 A.AdresSatiri, A.Mahalle, A.Ilce, A.Il FROM CariAdres A WHERE A.CariID = C.CariID AND A.Aktif = 1 ORDER BY A.Varsayilan DESC, A.CariAdresID) A1 ' +
      'WHERE C.Aktif = 1 AND EXISTS ( ' +
      '  SELECT 1 FROM CariTelefon T ' +
      '  WHERE T.CariID = C.CariID AND T.Aktif = 1 AND isnull(T.TelefonNormalize, '''') LIKE :P) ' +
      'ORDER BY C.CariID DESC';
    LQuery.ParamByName('P').AsString := '%' + LNorm + '%';
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('found', TJSONBool.Create(False));
      Exit;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('found', TJSONBool.Create(True));
    Result.AddPair('cariId', TJSONNumber.Create(LQuery.FieldByName('CariID').AsInteger));
    Result.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
    Result.AddPair('cariUnvani', LQuery.FieldByName('CariUnvani').AsString);
    Result.AddPair('telefon1', LQuery.FieldByName('Telefon1').AsString);
    Result.AddPair('telefon2', LQuery.FieldByName('Telefon2').AsString);
    Result.AddPair('adres', LQuery.FieldByName('Adres').AsString);
    Result.AddPair('mahalle', LQuery.FieldByName('Mahalle').AsString);
    Result.AddPair('ilce', LQuery.FieldByName('Ilce').AsString);
    Result.AddPair('il', LQuery.FieldByName('Il').AsString);
    Result.AddPair('cariBorc', TJSONNumber.Create(LQuery.FieldByName('CariBorc').AsCurrency));
  finally
    LQuery.Free;
  end;
end;

function TSmCari.FindCustomerByName(AName: string): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  if Trim(AName) = '' then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Musteri adi giriniz');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT TOP 1 C.CariID, C.CariAdi, isnull(C.CariUnvani, '''') AS CariUnvani, ' +
      'isnull(P1.Telefon, '''') AS Telefon1, isnull(P2.Telefon, '''') AS Telefon2, ' +
      'isnull(A1.AdresSatiri, '''') AS Adres, isnull(A1.Mahalle, '''') AS Mahalle, ' +
      'isnull(A1.Ilce, '''') AS Ilce, isnull(A1.Il, '''') AS Il, ' +
      'isnull((SELECT SUM(isnull(H.Borc, 0) - isnull(H.Alacak, 0)) FROM CariHareket H WHERE H.CariID = C.CariID), 0) AS CariBorc ' +
      'FROM Cari C ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM dbo.CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 ORDER BY T.Varsayilan DESC, T.CariTelefonID) P1 ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM dbo.CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 AND isnull(P1.Telefon, '''') <> isnull(T.Telefon, '''') ORDER BY T.Varsayilan DESC, T.CariTelefonID) P2 ' +
      'OUTER APPLY (SELECT TOP 1 A.AdresSatiri, A.Mahalle, A.Ilce, A.Il FROM dbo.CariAdres A WHERE A.CariID = C.CariID AND A.Aktif = 1 ORDER BY A.Varsayilan DESC, A.CariAdresID) A1 ' +
      'WHERE C.Aktif = 1 AND C.CariAdi LIKE :P ' +
      'ORDER BY C.CariID DESC';
    LQuery.ParamByName('P').AsString := '%' + Trim(AName) + '%';
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('found', TJSONBool.Create(False));
      Exit;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('found', TJSONBool.Create(True));
    Result.AddPair('cariId', TJSONNumber.Create(LQuery.FieldByName('CariID').AsInteger));
    Result.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
    Result.AddPair('cariUnvani', LQuery.FieldByName('CariUnvani').AsString);
    Result.AddPair('telefon1', LQuery.FieldByName('Telefon1').AsString);
    Result.AddPair('telefon2', LQuery.FieldByName('Telefon2').AsString);
    Result.AddPair('adres', LQuery.FieldByName('Adres').AsString);
    Result.AddPair('mahalle', LQuery.FieldByName('Mahalle').AsString);
    Result.AddPair('ilce', LQuery.FieldByName('Ilce').AsString);
    Result.AddPair('il', LQuery.FieldByName('Il').AsString);
    Result.AddPair('cariBorc', TJSONNumber.Create(LQuery.FieldByName('CariBorc').AsCurrency));
  finally
    LQuery.Free;
  end;
end;

function TSmCari.InsertNewCustomerFull(ACariAdi, ATelefon, AMahalle, ACadde,
  ABinaNo, ADaireNo, AKat, ABlok, ASite: string): TJSONObject;
var
  LQuery: TFDQuery;
  LCariAdi, LCariKod, LAdresSatiri: string;
  LCariID: Integer;
  LNormPhone: string;
begin
  Result := TJSONObject.Create;
  LCariAdi := Trim(ACariAdi);
  if LCariAdi = '' then
    LCariAdi := Trim(ATelefon);
  if LCariAdi = '' then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Musteri adi veya telefon giriniz');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LCariKod := NextCariCode(LQuery);

    // Build address line
    LAdresSatiri := Trim(AMahalle);
    if Trim(ACadde) <> '' then
      LAdresSatiri := LAdresSatiri + IfThen(LAdresSatiri <> '', ' ', '') + Trim(ACadde);
    if Trim(ABinaNo) <> '' then
      LAdresSatiri := LAdresSatiri + IfThen(LAdresSatiri <> '', ' ', '') + 'Bina:' + Trim(ABinaNo);
    if Trim(ADaireNo) <> '' then
      LAdresSatiri := LAdresSatiri + IfThen(LAdresSatiri <> '', ' ', '') + 'Daire:' + Trim(ADaireNo);
    if Trim(AKat) <> '' then
      LAdresSatiri := LAdresSatiri + IfThen(LAdresSatiri <> '', ' ', '') + 'Kat:' + Trim(AKat);
    if Trim(ABlok) <> '' then
      LAdresSatiri := LAdresSatiri + IfThen(LAdresSatiri <> '', ' ', '') + 'Blok:' + Trim(ABlok);
    if Trim(ASite) <> '' then
      LAdresSatiri := LAdresSatiri + IfThen(LAdresSatiri <> '', ' ', '') + 'Site:' + Trim(ASite);

    // Insert Cari
    LQuery.SQL.Text :=
      'INSERT INTO Cari (CariKod, CariAdi, CariUnvani, CariTip, Aktif) ' +
      'OUTPUT inserted.CariID VALUES (:CariKod, :CariAdi, :CariUnvani, N''Musteri'', 1)';
    LQuery.ParamByName('CariKod').AsString := LCariKod;
    LQuery.ParamByName('CariAdi').AsString := LCariAdi;
    LQuery.ParamByName('CariUnvani').AsString := LCariAdi;
    LQuery.Open;
    LCariID := LQuery.FieldByName('CariID').AsInteger;
    LQuery.Close;

    // Insert phone
    if Trim(ATelefon) <> '' then
    begin
      LNormPhone := NormalizePhone(ATelefon);
      LQuery.SQL.Text :=
        'INSERT INTO CariTelefon (CariID, Telefon, TelefonNormalize, TelefonTipi, Varsayilan, Aktif) ' +
        'VALUES (:CariID, :Telefon, :TelefonNormalize, N''Cep'', 1, 1)';
      LQuery.ParamByName('CariID').AsInteger := LCariID;
      LQuery.ParamByName('Telefon').AsString := Trim(ATelefon);
      LQuery.ParamByName('TelefonNormalize').AsString := LNormPhone;
      LQuery.ExecSQL;
    end;

    // Insert address
    if LAdresSatiri <> '' then
    begin
      LQuery.SQL.Text :=
        'INSERT INTO CariAdres (CariID, AdresSatiri, Mahalle, Varsayilan, Aktif) ' +
        'VALUES (:CariID, :AdresSatiri, :Mahalle, 1, 1)';
      LQuery.ParamByName('CariID').AsInteger := LCariID;
      LQuery.ParamByName('AdresSatiri').AsString := LAdresSatiri;
      LQuery.ParamByName('Mahalle').AsString := Trim(AMahalle);
      LQuery.ExecSQL;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('cariId', TJSONNumber.Create(LCariID));
    Result.AddPair('cariKod', LCariKod);
    Result.AddPair('message', 'Musteri olusturuldu');
  finally
    LQuery.Free;
  end;
end;

function TSmCari.CreateCariMobil(AAdSoyad, ATelefon, AAdres: string): TJSONObject;
begin
  Result := InsertNewCustomerFull(AAdSoyad, ATelefon, '', '', '', '', '', '', '');
  if Trim(AAdres) <> '' then
  begin
    var LQuery := DM.GetQuery;
    try
      var LCariID := Result.GetValue<Integer>('cariId', 0);
      if LCariID > 0 then
      begin
        LQuery.SQL.Text :=
          'IF NOT EXISTS (SELECT 1 FROM CariAdres WHERE CariID = :CariID) ' +
          'INSERT INTO CariAdres (CariID, AdresSatiri, Varsayilan, Aktif) VALUES (:CariID, :Adres, 1, 1) ' +
          'ELSE UPDATE CariAdres SET AdresSatiri = :Adres WHERE CariID = :CariID AND Varsayilan = 1';
        LQuery.ParamByName('CariID').AsInteger := LCariID;
        LQuery.ParamByName('Adres').AsString := Trim(AAdres);
        LQuery.ExecSQL;
      end;
    finally
      LQuery.Free;
    end;
  end;
end;

function TSmCari.ImportContacts(AContactsJson: string): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LItem: TJSONObject;
  LImported, LSkipped, I: Integer;
  LName, LPhone, LNorm, LCariKod: string;
begin
  Result := TJSONObject.Create;
  LArray := TJSONObject.ParseJSONValue(AContactsJson) as TJSONArray;
  if LArray = nil then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz JSON');
    Exit;
  end;

  LImported := 0;
  LSkipped := 0;
  LQuery := DM.GetQuery;
  try
    for I := 0 to LArray.Count - 1 do
    begin
      LItem := LArray.Items[I] as TJSONObject;
      LName := LItem.GetValue<string>('name', '');
      LPhone := LItem.GetValue<string>('phone', '');
      if (LName = '') and (LPhone = '') then
      begin
        Inc(LSkipped);
        Continue;
      end;

      LNorm := NormalizePhone(LPhone);

      // Check if phone already exists
      if LNorm <> '' then
      begin
        LQuery.SQL.Text :=
          'SELECT TOP 1 1 FROM CariTelefon WHERE Aktif = 1 AND isnull(TelefonNormalize, '''') LIKE :P';
        LQuery.ParamByName('P').AsString := '%' + LNorm + '%';
        LQuery.Open;
        if not LQuery.IsEmpty then
        begin
          LQuery.Close;
          Inc(LSkipped);
          Continue;
        end;
        LQuery.Close;
      end;

      LCariKod := NextCariCode(LQuery);

      LQuery.SQL.Text :=
        'INSERT INTO Cari (CariKod, CariAdi, CariUnvani, CariTip, Aktif) ' +
        'OUTPUT inserted.CariID VALUES (:CariKod, :CariAdi, :CariAdi, N''Musteri'', 1)';
      LQuery.ParamByName('CariKod').AsString := LCariKod;
      LQuery.ParamByName('CariAdi').AsString := IfThen(LName <> '', LName, LPhone);
      LQuery.Open;
      var LCariID := LQuery.FieldByName('CariID').AsInteger;
      LQuery.Close;

      if (LNorm <> '') and (LCariID > 0) then
      begin
        LQuery.SQL.Text :=
          'INSERT INTO CariTelefon (CariID, Telefon, TelefonNormalize, TelefonTipi, Varsayilan, Aktif) ' +
          'VALUES (:CariID, :Telefon, :TelefonNormalize, N''Cep'', 1, 1)';
        LQuery.ParamByName('CariID').AsInteger := LCariID;
        LQuery.ParamByName('Telefon').AsString := LPhone;
        LQuery.ParamByName('TelefonNormalize').AsString := LNorm;
        LQuery.ExecSQL;
      end;

      Inc(LImported);
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('imported', TJSONNumber.Create(LImported));
    Result.AddPair('skipped', TJSONNumber.Create(LSkipped));
    Result.AddPair('message', IntToStr(LImported) + ' kisi eklendi, ' + IntToStr(LSkipped) + ' atlandı');
  finally
    LQuery.Free;
    LArray.Free;
  end;
end;

function TSmCari.ListCouriers: TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  LQuery := DM.GetQuery;
  try
    // Ensure Kurye column exists
    LQuery.SQL.Text :=
      'IF NOT EXISTS ( ' +
      '  SELECT 1 FROM ERP_AUTH.sys.columns c ' +
      '  INNER JOIN ERP_AUTH.sys.objects o ON o.object_id = c.object_id ' +
      '  WHERE o.name = ''AuthUser'' AND c.name = ''Kurye'' ' +
      ') ' +
      'BEGIN ' +
      '  ALTER TABLE ERP_AUTH.dbo.AuthUser ADD Kurye BIT NOT NULL CONSTRAINT DF_AuthUser_Kurye DEFAULT(0); ' +
      'END';
    LQuery.ExecSQL;

    LQuery.SQL.Text :=
      'SELECT AU.AuthUserID AS KullaniciID, ' +
      '  CASE WHEN isnull(AU.AdSoyad, '''') <> '''' THEN AU.AdSoyad ELSE AU.KullaniciAdi END AS KuryeAdi ' +
      'FROM ERP_AUTH.dbo.AuthUser AU ' +
      'WHERE AU.Aktif = 1 AND isnull(AU.Kurye, 0) = 1 ' +
      'ORDER BY CASE WHEN isnull(AU.AdSoyad, '''') <> '''' THEN AU.AdSoyad ELSE AU.KullaniciAdi END';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('kullaniciId', TJSONNumber.Create(LQuery.FieldByName('KullaniciID').AsInteger));
      LObj.AddPair('kuryeAdi', LQuery.FieldByName('KuryeAdi').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.ListFastOrderStocks: TJSONObject;
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
      'IF col_length(''dbo.Stok'', ''HizliSiparisAktif'') IS NULL ' +
      'ALTER TABLE dbo.Stok ADD HizliSiparisAktif BIT NOT NULL CONSTRAINT DF_Stok_HizliSiparisAktif DEFAULT(0); ' +
      'SELECT StokID, StokAdi, isnull(SatisFiyat, 0) AS SatisFiyat, isnull(HizliSiparisAktif, 0) AS HizliSiparisAktif ' +
      'FROM Stok ' +
      'WHERE Aktif = 1 AND isnull(HizliSiparisAktif, 0) = 1 ' +
      'ORDER BY StokAdi';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
      LObj.AddPair('stokAdi', LQuery.FieldByName('StokAdi').AsString);
      LObj.AddPair('satisFiyat', TJSONNumber.Create(LQuery.FieldByName('SatisFiyat').AsCurrency));
      LObj.AddPair('hizliSiparisAktif', TJSONBool.Create(LQuery.FieldByName('HizliSiparisAktif').AsInteger = 1));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.ListQuickProducts: TJSONObject;
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
      'IF col_length(''dbo.Stok'', ''HizliSiparisAktif'') IS NULL ' +
      'ALTER TABLE dbo.Stok ADD HizliSiparisAktif BIT NOT NULL CONSTRAINT DF_Stok_HizliSiparisAktif DEFAULT(0); ' +
      'SELECT StokID, StokAdi, isnull(Barkod, '''') AS Barkod, isnull(SatisFiyat, 0) AS SatisFiyat ' +
      'FROM Stok ' +
      'WHERE Aktif = 1 AND isnull(HizliSiparisAktif, 0) = 1 ' +
      'ORDER BY StokAdi';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('stokId', TJSONNumber.Create(LQuery.FieldByName('StokID').AsInteger));
      LObj.AddPair('stokAdi', LQuery.FieldByName('StokAdi').AsString);
      LObj.AddPair('barkod', LQuery.FieldByName('Barkod').AsString);
      LObj.AddPair('satisFiyat', TJSONNumber.Create(LQuery.FieldByName('SatisFiyat').AsCurrency));
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
