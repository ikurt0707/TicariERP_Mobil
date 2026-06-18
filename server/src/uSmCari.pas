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
    function FindByID(ACariID: Integer): TJSONObject;
    function FindCustomerByPhone(ATelefon: string): TJSONObject;
    function FindCustomerByName(AName: string): TJSONObject;
    function ListPhones(ACariID: Integer): TJSONObject;
    function ListAddresses(ACariID: Integer): TJSONObject;
    function ListHareket(ACariID: Integer): TJSONObject;
    function ListIller: TJSONObject;
    function ListIlceler(AIl: string): TJSONObject;
    function ListMahalleler(AIl, AIlce: string): TJSONObject;
    function ListSokaklar(AIl, AIlce, AMahalle: string): TJSONObject;
    function SaveCari(ACariJson: string): TJSONObject;
    function InsertNewCustomerFull(ACariAdi, ATelefon, AMahalle, ACadde,
      ABinaNo, ADaireNo, AKat, ABlok, ASite: string): TJSONObject;
    function CreateCariMobil(AAdSoyad, ATelefon, AAdres: string): TJSONObject;
    function ImportContacts(AContactsJson: string): TJSONObject;
    function LinkPhoneToCari(ACariID: Integer; ATelefon, ATelefonTipi: string;
      ASetPrimary: Integer): TJSONObject;
    function PasifYap(ACariID: Integer): TJSONObject;
    function TahsilatOdeme(ACariID, AKasaID: Integer; AIslemTipi, AAciklama: string;
      ATutar: Double): TJSONObject;
    function ListCouriers: TJSONObject;
    function ListFastOrderStocks: TJSONObject;
    function ListQuickProducts: TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

{$R *.dfm}

uses
  uDM, uDMAuth, System.StrUtils, System.DateUtils, Data.DB;

{ ---- Helper functions ---- }

function NormalizePhone(const AValue: string): string;
begin
  Result := Trim(AValue);
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
  Result := StringReplace(Result, '(', '', [rfReplaceAll]);
  Result := StringReplace(Result, ')', '', [rfReplaceAll]);
  Result := StringReplace(Result, '+90', '', [rfReplaceAll]);
  if (Length(Result) > 10) and (Copy(Result, 1, 2) = '90') then
    Delete(Result, 1, 2);
  if (Length(Result) = 11) and (Copy(Result, 1, 1) = '0') then
    Delete(Result, 1, 1);
end;

function NormalizeText(const AValue: string): string;
begin
  Result := Trim(UpperCase(AValue));
  Result := StringReplace(Result, '.', ' ', [rfReplaceAll]);
  Result := StringReplace(Result, ',', ' ', [rfReplaceAll]);
  Result := StringReplace(Result, ':', ' ', [rfReplaceAll]);
  Result := StringReplace(Result, ';', ' ', [rfReplaceAll]);
  Result := StringReplace(Result, '/', ' ', [rfReplaceAll]);
  Result := StringReplace(Result, '\', ' ', [rfReplaceAll]);
  Result := StringReplace(Result, ' MAH.', ' MAHALLE ', [rfReplaceAll]);
  Result := StringReplace(Result, ' MAH ', ' MAHALLE ', [rfReplaceAll]);
  Result := StringReplace(Result, ' MH ', ' MAHALLE ', [rfReplaceAll]);
  Result := StringReplace(Result, ' SK.', ' SOKAK ', [rfReplaceAll]);
  Result := StringReplace(Result, ' SK ', ' SOKAK ', [rfReplaceAll]);
  Result := StringReplace(Result, ' CAD.', ' CADDE ', [rfReplaceAll]);
  Result := StringReplace(Result, ' CAD ', ' CADDE ', [rfReplaceAll]);
  while Pos('  ', Result) > 0 do
    Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]);
end;

function BuildAddressLine(const AAdres, AIl, AIlce, AMahalle, ACaddeSokak,
  ABinaNo, ADaireNo, AKat, ABlok, ASiteApartmanAdi, AKapiKodu, AAdresTarifi: string): string;
begin
  Result := Trim(AAdres);
  if Result = '' then
  begin
    Result := Trim(
      IfThen(Trim(AMahalle) <> '', Trim(AMahalle) + ' ', '') +
      IfThen(Trim(ACaddeSokak) <> '', Trim(ACaddeSokak) + ' ', '') +
      IfThen(Trim(ABinaNo) <> '', 'No:' + Trim(ABinaNo) + ' ', '') +
      IfThen(Trim(ADaireNo) <> '', 'D:' + Trim(ADaireNo) + ' ', '') +
      IfThen(Trim(AKat) <> '', 'Kat:' + Trim(AKat) + ' ', '') +
      IfThen(Trim(ABlok) <> '', 'Blok:' + Trim(ABlok) + ' ', '') +
      IfThen(Trim(ASiteApartmanAdi) <> '', Trim(ASiteApartmanAdi) + ' ', '') +
      IfThen(Trim(AIlce) <> '', Trim(AIlce) + ' ', '') +
      IfThen(Trim(AIl) <> '', Trim(AIl), '')
    );
  end;
  if Trim(AAdresTarifi) <> '' then
    Result := Trim(Result + ' | ' + Trim(AAdresTarifi));
  if Trim(AKapiKodu) <> '' then
    Result := Trim(Result + ' | Kapi:' + Trim(AKapiKodu));
end;

function BuildAddressHash(const AIl, AIlce, AMahalle, ACaddeSokak, ABinaNo,
  ADaireNo, AKat, ABlok, ASiteApartmanAdi, AKapiKodu, AAdresTarifi: string): string;
begin
  Result := NormalizeText(
    AIl + '|' + AIlce + '|' + AMahalle + '|' + ACaddeSokak + '|' + ABinaNo + '|' +
    ADaireNo + '|' + AKat + '|' + ABlok + '|' + ASiteApartmanAdi + '|' +
    AKapiKodu + '|' + AAdresTarifi
  );
end;

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

procedure BindNullableStringParam(AQuery: TFDQuery; const AParamName, AValue: string);
begin
  AQuery.ParamByName(AParamName).DataType := ftString;
  if Trim(AValue) <> '' then
    AQuery.ParamByName(AParamName).AsString := Trim(AValue)
  else
    AQuery.ParamByName(AParamName).Clear;
end;

{ ---- TSmCari ---- }

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
      'SELECT C.CariID, C.CariKod, C.CariAdi, isnull(C.CariTip, '''') AS CariTip, ' +
      'isnull(P1.Telefon, '''') AS Telefon, ' +
      'isnull(A1.AdresSatiri, '''') AS Adres, ' +
      'isnull(b.Bakiye, 0) AS Bakiye ' +
      'FROM Cari C ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 ORDER BY T.Varsayilan DESC, T.CariTelefonID) P1 ' +
      'OUTER APPLY (SELECT TOP 1 A.AdresSatiri FROM CariAdres A WHERE A.CariID = C.CariID AND A.Aktif = 1 ORDER BY A.Varsayilan DESC, A.CariAdresID) A1 ' +
      'LEFT JOIN vCariBakiye b ON b.CariID = C.CariID ' +
      'WHERE C.Aktif = 1 AND (:Arama = '''' OR C.CariKod LIKE :LikeArama OR C.CariAdi LIKE :LikeArama ' +
      '  OR isnull(P1.Telefon, '''') LIKE :LikeArama OR isnull(A1.AdresSatiri, '''') LIKE :LikeArama) ' +
      'ORDER BY C.CariAdi ' +
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
      LObj.AddPair('cariTip', LQuery.FieldByName('CariTip').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
      LObj.AddPair('bakiye', TJSONNumber.Create(LQuery.FieldByName('Bakiye').AsCurrency));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.FindByID(ACariID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT C.CariID, C.CariKod, C.CariAdi, isnull(C.CariUnvani, '''') AS CariUnvani, ' +
      'isnull(C.CariTip, '''') AS CariTip, isnull(C.TCKN_VKN, '''') AS TCKN_VKN, ' +
      'isnull(C.VergiDairesi, '''') AS VergiDairesi, isnull(C.Email, '''') AS Email, ' +
      'isnull(C.RiskLimiti, 0) AS RiskLimiti, ' +
      'isnull(P1.Telefon, '''') AS Telefon1, isnull(P2.Telefon, '''') AS Telefon2, ' +
      'isnull(A1.AdresSatiri, '''') AS Adres, isnull(A1.Il, '''') AS Il, isnull(A1.Ilce, '''') AS Ilce, ' +
      'isnull(A1.Mahalle, '''') AS Mahalle, isnull(A1.CaddeSokak, '''') AS CaddeSokak, ' +
      'isnull(A1.BinaNo, '''') AS BinaNo, isnull(A1.DaireNo, '''') AS DaireNo, ' +
      'isnull(A1.Kat, '''') AS Kat, isnull(A1.Blok, '''') AS Blok, ' +
      'isnull(A1.SiteApartmanAdi, '''') AS SiteApartmanAdi, ' +
      'isnull(A1.KapiKodu, '''') AS KapiKodu, isnull(A1.AdresTarifi, '''') AS AdresTarifi ' +
      'FROM Cari C ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM dbo.CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 ORDER BY T.Varsayilan DESC, T.CariTelefonID) P1 ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM dbo.CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 AND isnull(P1.Telefon, '''') <> isnull(T.Telefon, '''') ORDER BY T.Varsayilan DESC, T.CariTelefonID) P2 ' +
      'OUTER APPLY (SELECT TOP 1 A.AdresSatiri, A.Il, A.Ilce, A.Mahalle, A.CaddeSokak, A.BinaNo, A.DaireNo, A.Kat, A.Blok, A.SiteApartmanAdi, A.KapiKodu, A.AdresTarifi ' +
      '             FROM dbo.CariAdres A WHERE A.CariID = C.CariID AND A.Aktif = 1 ORDER BY A.Varsayilan DESC, A.CariAdresID) A1 ' +
      'WHERE C.CariID = :CariID';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Cari bulunamadi');
      Exit;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('cariId', TJSONNumber.Create(LQuery.FieldByName('CariID').AsInteger));
    Result.AddPair('cariKod', LQuery.FieldByName('CariKod').AsString);
    Result.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
    Result.AddPair('cariUnvani', LQuery.FieldByName('CariUnvani').AsString);
    Result.AddPair('cariTip', LQuery.FieldByName('CariTip').AsString);
    Result.AddPair('tcknVkn', LQuery.FieldByName('TCKN_VKN').AsString);
    Result.AddPair('vergiDairesi', LQuery.FieldByName('VergiDairesi').AsString);
    Result.AddPair('email', LQuery.FieldByName('Email').AsString);
    Result.AddPair('riskLimiti', TJSONNumber.Create(LQuery.FieldByName('RiskLimiti').AsCurrency));
    Result.AddPair('telefon1', LQuery.FieldByName('Telefon1').AsString);
    Result.AddPair('telefon2', LQuery.FieldByName('Telefon2').AsString);
    Result.AddPair('adres', LQuery.FieldByName('Adres').AsString);
    Result.AddPair('il', LQuery.FieldByName('Il').AsString);
    Result.AddPair('ilce', LQuery.FieldByName('Ilce').AsString);
    Result.AddPair('mahalle', LQuery.FieldByName('Mahalle').AsString);
    Result.AddPair('caddeSokak', LQuery.FieldByName('CaddeSokak').AsString);
    Result.AddPair('binaNo', LQuery.FieldByName('BinaNo').AsString);
    Result.AddPair('daireNo', LQuery.FieldByName('DaireNo').AsString);
    Result.AddPair('kat', LQuery.FieldByName('Kat').AsString);
    Result.AddPair('blok', LQuery.FieldByName('Blok').AsString);
    Result.AddPair('siteApartmanAdi', LQuery.FieldByName('SiteApartmanAdi').AsString);
    Result.AddPair('kapiKodu', LQuery.FieldByName('KapiKodu').AsString);
    Result.AddPair('adresTarifi', LQuery.FieldByName('AdresTarifi').AsString);
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
      'SELECT TOP 1 C.CariID, C.CariKod, C.CariAdi, isnull(C.CariUnvani, '''') AS CariUnvani, ' +
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
      '  WHERE T.CariID = C.CariID AND T.Aktif = 1 AND isnull(T.TelefonNormalize, '''') = :P) ' +
      'ORDER BY C.CariID DESC';
    LQuery.ParamByName('P').AsString := LNorm;
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
    Result.AddPair('cariKod', LQuery.FieldByName('CariKod').AsString);
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
      'SELECT TOP 1 C.CariID, C.CariKod, C.CariAdi, isnull(C.CariUnvani, '''') AS CariUnvani, ' +
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
    Result.AddPair('cariKod', LQuery.FieldByName('CariKod').AsString);
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

function TSmCari.ListPhones(ACariID: Integer): TJSONObject;
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
      'SELECT CariTelefonID, isnull(TelefonTipi, '''') AS TelefonTipi, isnull(Telefon, '''') AS Telefon, ' +
      'isnull(TelefonNormalize, '''') AS TelefonNormalize, Varsayilan, Aktif ' +
      'FROM dbo.CariTelefon WHERE CariID = :CariID ORDER BY Varsayilan DESC, CariTelefonID';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('cariTelefonId', TJSONNumber.Create(LQuery.FieldByName('CariTelefonID').AsInteger));
      LObj.AddPair('telefonTipi', LQuery.FieldByName('TelefonTipi').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('telefonNormalize', LQuery.FieldByName('TelefonNormalize').AsString);
      LObj.AddPair('varsayilan', TJSONBool.Create(LQuery.FieldByName('Varsayilan').AsBoolean));
      LObj.AddPair('aktif', TJSONBool.Create(LQuery.FieldByName('Aktif').AsBoolean));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.ListAddresses(ACariID: Integer): TJSONObject;
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
      'SELECT CariAdresID, isnull(AdresTipi, '''') AS AdresTipi, isnull(AdresSatiri, '''') AS AdresSatiri, ' +
      'isnull(Il, '''') AS Il, isnull(Ilce, '''') AS Ilce, isnull(Mahalle, '''') AS Mahalle, ' +
      'isnull(CaddeSokak, '''') AS CaddeSokak, isnull(BinaNo, '''') AS BinaNo, ' +
      'isnull(DaireNo, '''') AS DaireNo, isnull(Kat, '''') AS Kat, isnull(Blok, '''') AS Blok, ' +
      'isnull(SiteApartmanAdi, '''') AS SiteApartmanAdi, isnull(KapiKodu, '''') AS KapiKodu, ' +
      'isnull(AdresTarifi, '''') AS AdresTarifi, isnull(AdresHash, '''') AS AdresHash, Varsayilan, Aktif ' +
      'FROM dbo.CariAdres WHERE CariID = :CariID ORDER BY Varsayilan DESC, CariAdresID';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('cariAdresId', TJSONNumber.Create(LQuery.FieldByName('CariAdresID').AsInteger));
      LObj.AddPair('adresTipi', LQuery.FieldByName('AdresTipi').AsString);
      LObj.AddPair('adresSatiri', LQuery.FieldByName('AdresSatiri').AsString);
      LObj.AddPair('il', LQuery.FieldByName('Il').AsString);
      LObj.AddPair('ilce', LQuery.FieldByName('Ilce').AsString);
      LObj.AddPair('mahalle', LQuery.FieldByName('Mahalle').AsString);
      LObj.AddPair('caddeSokak', LQuery.FieldByName('CaddeSokak').AsString);
      LObj.AddPair('binaNo', LQuery.FieldByName('BinaNo').AsString);
      LObj.AddPair('daireNo', LQuery.FieldByName('DaireNo').AsString);
      LObj.AddPair('kat', LQuery.FieldByName('Kat').AsString);
      LObj.AddPair('blok', LQuery.FieldByName('Blok').AsString);
      LObj.AddPair('siteApartmanAdi', LQuery.FieldByName('SiteApartmanAdi').AsString);
      LObj.AddPair('kapiKodu', LQuery.FieldByName('KapiKodu').AsString);
      LObj.AddPair('adresTarifi', LQuery.FieldByName('AdresTarifi').AsString);
      LObj.AddPair('adresHash', LQuery.FieldByName('AdresHash').AsString);
      LObj.AddPair('varsayilan', TJSONBool.Create(LQuery.FieldByName('Varsayilan').AsBoolean));
      LObj.AddPair('aktif', TJSONBool.Create(LQuery.FieldByName('Aktif').AsBoolean));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.ListHareket(ACariID: Integer): TJSONObject;
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
      'SELECT TOP 500 Tarih, BelgeTipi, BelgeID, Aciklama, Borc, Alacak ' +
      'FROM CariHareket WHERE CariID = :CariID ORDER BY Tarih DESC';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('tarih', DateToISO8601(LQuery.FieldByName('Tarih').AsDateTime));
      LObj.AddPair('belgeTipi', LQuery.FieldByName('BelgeTipi').AsString);
      LObj.AddPair('belgeId', TJSONNumber.Create(LQuery.FieldByName('BelgeID').AsLargeInt));
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

function TSmCari.ListIller: TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  LQuery := DMAuth.GetAuthQuery;
  try
    LQuery.SQL.Text :=
      'SELECT Ad FROM dbo.AdresIlMaster WHERE Aktif = 1 ORDER BY Ad';
    LQuery.Open;
    while not LQuery.Eof do
    begin
      LArray.AddElement(TJSONString.Create(LQuery.FieldByName('Ad').AsString));
      LQuery.Next;
    end;
    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.ListIlceler(AIl: string): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  LQuery := DMAuth.GetAuthQuery;
  try
    LQuery.SQL.Text :=
      'SELECT ILC.Ad ' +
      'FROM dbo.AdresIlceMaster ILC ' +
      'INNER JOIN dbo.AdresIlMaster IL ON IL.IlID = ILC.IlID ' +
      'WHERE ILC.Aktif = 1 AND IL.Aktif = 1 AND (:Il = '''' OR IL.Ad = :Il) ' +
      'ORDER BY ILC.Ad';
    LQuery.ParamByName('Il').AsString := Trim(AIl);
    LQuery.Open;
    while not LQuery.Eof do
    begin
      LArray.AddElement(TJSONString.Create(LQuery.FieldByName('Ad').AsString));
      LQuery.Next;
    end;
    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.ListMahalleler(AIl, AIlce: string): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  LQuery := DMAuth.GetAuthQuery;
  try
    LQuery.SQL.Text :=
      'SELECT MH.Ad ' +
      'FROM dbo.AdresMahalleMaster MH ' +
      'INNER JOIN dbo.AdresIlMaster IL ON IL.IlID = MH.IlID ' +
      'INNER JOIN dbo.AdresIlceMaster ILC ON ILC.IlceID = MH.IlceID ' +
      'WHERE MH.Aktif = 1 AND IL.Aktif = 1 AND ILC.Aktif = 1 ' +
      '  AND (:Il = '''' OR IL.Ad = :Il) ' +
      '  AND (:Ilce = '''' OR ILC.Ad = :Ilce) ' +
      'ORDER BY MH.Ad';
    LQuery.ParamByName('Il').AsString := Trim(AIl);
    LQuery.ParamByName('Ilce').AsString := Trim(AIlce);
    LQuery.Open;
    while not LQuery.Eof do
    begin
      LArray.AddElement(TJSONString.Create(LQuery.FieldByName('Ad').AsString));
      LQuery.Next;
    end;
    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.ListSokaklar(AIl, AIlce, AMahalle: string): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  LQuery := DMAuth.GetAuthQuery;
  try
    LQuery.SQL.Text :=
      'SELECT SK.Ad ' +
      'FROM dbo.AdresSokakMaster SK ' +
      'INNER JOIN dbo.AdresIlMaster IL ON IL.IlID = SK.IlID ' +
      'INNER JOIN dbo.AdresIlceMaster ILC ON ILC.IlceID = SK.IlceID ' +
      'INNER JOIN dbo.AdresMahalleMaster MH ON MH.MahalleID = SK.MahalleID ' +
      'WHERE SK.Aktif = 1 AND IL.Aktif = 1 AND ILC.Aktif = 1 AND MH.Aktif = 1 ' +
      '  AND (:Il = '''' OR IL.Ad = :Il) ' +
      '  AND (:Ilce = '''' OR ILC.Ad = :Ilce) ' +
      '  AND (:Mahalle = '''' OR MH.Ad = :Mahalle) ' +
      'ORDER BY SK.Ad';
    LQuery.ParamByName('Il').AsString := Trim(AIl);
    LQuery.ParamByName('Ilce').AsString := Trim(AIlce);
    LQuery.ParamByName('Mahalle').AsString := Trim(AMahalle);
    LQuery.Open;
    while not LQuery.Eof do
    begin
      LArray.AddElement(TJSONString.Create(LQuery.FieldByName('Ad').AsString));
      LQuery.Next;
    end;
    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCari.SaveCari(ACariJson: string): TJSONObject;
var
  LJson: TJSONObject;
  LQuery: TFDQuery;
  LCariID, LNewCariID: Integer;
  LCariKod, LCariAdi, LCariUnvani, LCariTip: string;
  LTCKN_VKN, LVergiDairesi, LEmail: string;
  LTelefon1, LTelefon2: string;
  LAdres, LIl, LIlce, LMahalle, LCaddeSokak: string;
  LBinaNo, LDaireNo, LKat, LBlok, LSiteApartmanAdi, LKapiKodu, LAdresTarifi: string;
  LRiskLimiti: Double;
  LAdresSatiri, LAdresHash: string;
  LNorm1, LNorm2: string;
begin
  Result := TJSONObject.Create;
  LJson := TJSONObject.ParseJSONValue(ACariJson) as TJSONObject;
  if LJson = nil then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz JSON');
    Exit;
  end;

  try
    LCariID := LJson.GetValue<Integer>('cariId', 0);
    LCariKod := LJson.GetValue<string>('cariKod', '');
    LCariAdi := LJson.GetValue<string>('cariAdi', '');
    LCariUnvani := LJson.GetValue<string>('cariUnvani', '');
    LCariTip := LJson.GetValue<string>('cariTip', 'Musteri');
    LTCKN_VKN := LJson.GetValue<string>('tcknVkn', '');
    LVergiDairesi := LJson.GetValue<string>('vergiDairesi', '');
    LEmail := LJson.GetValue<string>('email', '');
    LTelefon1 := LJson.GetValue<string>('telefon1', '');
    LTelefon2 := LJson.GetValue<string>('telefon2', '');
    LAdres := LJson.GetValue<string>('adres', '');
    LIl := LJson.GetValue<string>('il', '');
    LIlce := LJson.GetValue<string>('ilce', '');
    LMahalle := LJson.GetValue<string>('mahalle', '');
    LCaddeSokak := LJson.GetValue<string>('caddeSokak', '');
    LBinaNo := LJson.GetValue<string>('binaNo', '');
    LDaireNo := LJson.GetValue<string>('daireNo', '');
    LKat := LJson.GetValue<string>('kat', '');
    LBlok := LJson.GetValue<string>('blok', '');
    LSiteApartmanAdi := LJson.GetValue<string>('siteApartmanAdi', '');
    LKapiKodu := LJson.GetValue<string>('kapiKodu', '');
    LAdresTarifi := LJson.GetValue<string>('adresTarifi', '');
    LRiskLimiti := LJson.GetValue<Double>('riskLimiti', 0);

    if Trim(LCariAdi) = '' then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Cari adi bos olamaz');
      Exit;
    end;

    LAdresSatiri := BuildAddressLine(LAdres, LIl, LIlce, LMahalle, LCaddeSokak,
      LBinaNo, LDaireNo, LKat, LBlok, LSiteApartmanAdi, LKapiKodu, LAdresTarifi);
    LAdresHash := BuildAddressHash(LIl, LIlce, LMahalle, LCaddeSokak, LBinaNo,
      LDaireNo, LKat, LBlok, LSiteApartmanAdi, LKapiKodu, LAdresTarifi);

    LNorm1 := NormalizePhone(LTelefon1);
    LNorm2 := NormalizePhone(LTelefon2);

    LQuery := DM.GetQuery;
    try
      { -- Validate phone duplicates -- }
      if LNorm1 <> '' then
      begin
        LQuery.SQL.Text :=
          'SELECT TOP 1 C.CariAdi FROM dbo.CariTelefon T ' +
          'INNER JOIN dbo.Cari C ON C.CariID = T.CariID ' +
          'WHERE T.Aktif = 1 AND isnull(T.TelefonNormalize, '''') = :Telefon AND T.CariID <> :CariID';
        LQuery.ParamByName('Telefon').AsString := LNorm1;
        LQuery.ParamByName('CariID').AsInteger := LCariID;
        LQuery.Open;
        if not LQuery.IsEmpty then
        begin
          Result.AddPair('success', TJSONBool.Create(False));
          Result.AddPair('message', 'Bu telefon "' + LQuery.Fields[0].AsString + '" carisine kayitli');
          Exit;
        end;
        LQuery.Close;
      end;

      if (LNorm2 <> '') and (LNorm2 <> LNorm1) then
      begin
        LQuery.SQL.Text :=
          'SELECT TOP 1 C.CariAdi FROM dbo.CariTelefon T ' +
          'INNER JOIN dbo.Cari C ON C.CariID = T.CariID ' +
          'WHERE T.Aktif = 1 AND isnull(T.TelefonNormalize, '''') = :Telefon AND T.CariID <> :CariID';
        LQuery.ParamByName('Telefon').AsString := LNorm2;
        LQuery.ParamByName('CariID').AsInteger := LCariID;
        LQuery.Open;
        if not LQuery.IsEmpty then
        begin
          Result.AddPair('success', TJSONBool.Create(False));
          Result.AddPair('message', 'Ikinci telefon "' + LQuery.Fields[0].AsString + '" carisine kayitli');
          Exit;
        end;
        LQuery.Close;
      end;

      { -- Auto-generate CariKod if empty -- }
      if Trim(LCariKod) = '' then
        LCariKod := NextCariCode(LQuery);

      { -- Insert or Update Cari -- }
      if LCariID = 0 then
        LQuery.SQL.Text :=
          'INSERT INTO Cari (CariKod, CariAdi, CariUnvani, CariTip, TCKN_VKN, VergiDairesi, Email, RiskLimiti, Aktif) ' +
          'VALUES (:CariKod, :CariAdi, :CariUnvani, :CariTip, :TCKN_VKN, :VergiDairesi, :Email, :RiskLimiti, 1); ' +
          'SELECT CAST(SCOPE_IDENTITY() AS INT) AS CariID'
      else
        LQuery.SQL.Text :=
          'UPDATE Cari SET CariKod = :CariKod, CariAdi = :CariAdi, CariUnvani = :CariUnvani, CariTip = :CariTip, ' +
          'TCKN_VKN = :TCKN_VKN, VergiDairesi = :VergiDairesi, Email = :Email, RiskLimiti = :RiskLimiti WHERE CariID = :CariID; ' +
          'SELECT :CariID AS CariID';

      LQuery.ParamByName('CariKod').AsString := Trim(LCariKod);
      LQuery.ParamByName('CariAdi').AsString := Trim(UpperCase(LCariAdi));
      LQuery.ParamByName('CariUnvani').AsString := Trim(UpperCase(IfThen(LCariUnvani <> '', LCariUnvani, LCariAdi)));
      LQuery.ParamByName('CariTip').AsString := Trim(LCariTip);
      BindNullableStringParam(LQuery, 'TCKN_VKN', LTCKN_VKN);
      BindNullableStringParam(LQuery, 'VergiDairesi', LVergiDairesi);
      BindNullableStringParam(LQuery, 'Email', LEmail);
      LQuery.ParamByName('RiskLimiti').DataType := ftCurrency;
      if LRiskLimiti > 0 then
        LQuery.ParamByName('RiskLimiti').AsCurrency := LRiskLimiti
      else
        LQuery.ParamByName('RiskLimiti').Clear;
      if LCariID <> 0 then
        LQuery.ParamByName('CariID').AsInteger := LCariID;
      LQuery.Open;
      LNewCariID := LQuery.FieldByName('CariID').AsInteger;
      LQuery.Close;

      { -- Save phones (delete + re-insert) -- }
      LQuery.SQL.Text := 'DELETE FROM dbo.CariTelefon WHERE CariID = :CariID';
      LQuery.ParamByName('CariID').AsInteger := LNewCariID;
      LQuery.ExecSQL;

      if LNorm1 <> '' then
      begin
        LQuery.SQL.Text :=
          'INSERT INTO dbo.CariTelefon (CariID, TelefonTipi, Telefon, TelefonNormalize, Varsayilan, Aktif) ' +
          'VALUES (:CariID, :Tip, :Telefon, :Norm, 1, 1)';
        LQuery.ParamByName('CariID').AsInteger := LNewCariID;
        LQuery.ParamByName('Tip').AsString := 'Cep';
        LQuery.ParamByName('Telefon').AsString := Trim(LTelefon1);
        LQuery.ParamByName('Norm').AsString := LNorm1;
        LQuery.ExecSQL;
      end;

      if (LNorm2 <> '') and (LNorm2 <> LNorm1) then
      begin
        LQuery.SQL.Text :=
          'INSERT INTO dbo.CariTelefon (CariID, TelefonTipi, Telefon, TelefonNormalize, Varsayilan, Aktif) ' +
          'VALUES (:CariID, :Tip, :Telefon, :Norm, 0, 1)';
        LQuery.ParamByName('CariID').AsInteger := LNewCariID;
        LQuery.ParamByName('Tip').AsString := 'Diger';
        LQuery.ParamByName('Telefon').AsString := Trim(LTelefon2);
        LQuery.ParamByName('Norm').AsString := LNorm2;
        LQuery.ExecSQL;
      end;

      { -- Save address (delete + re-insert) -- }
      LQuery.SQL.Text := 'DELETE FROM dbo.CariAdres WHERE CariID = :CariID';
      LQuery.ParamByName('CariID').AsInteger := LNewCariID;
      LQuery.ExecSQL;

      if (Trim(LAdresSatiri) <> '') or (Trim(LCaddeSokak) <> '') or (Trim(LMahalle) <> '') then
      begin
        LQuery.SQL.Text :=
          'INSERT INTO dbo.CariAdres (CariID, AdresTipi, AdresSatiri, Il, Ilce, Mahalle, CaddeSokak, BinaNo, DaireNo, Kat, Blok, SiteApartmanAdi, KapiKodu, AdresTarifi, AdresHash, Varsayilan, Aktif) ' +
          'VALUES (:CariID, :AdresTipi, :AdresSatiri, :Il, :Ilce, :Mahalle, :CaddeSokak, :BinaNo, :DaireNo, :Kat, :Blok, :SiteApartmanAdi, :KapiKodu, :AdresTarifi, :AdresHash, 1, 1)';
        LQuery.ParamByName('CariID').AsInteger := LNewCariID;
        LQuery.ParamByName('AdresTipi').AsString := 'Ev';
        BindNullableStringParam(LQuery, 'AdresSatiri', LAdresSatiri);
        BindNullableStringParam(LQuery, 'Il', LIl);
        BindNullableStringParam(LQuery, 'Ilce', LIlce);
        BindNullableStringParam(LQuery, 'Mahalle', LMahalle);
        BindNullableStringParam(LQuery, 'CaddeSokak', LCaddeSokak);
        BindNullableStringParam(LQuery, 'BinaNo', LBinaNo);
        BindNullableStringParam(LQuery, 'DaireNo', LDaireNo);
        BindNullableStringParam(LQuery, 'Kat', LKat);
        BindNullableStringParam(LQuery, 'Blok', LBlok);
        BindNullableStringParam(LQuery, 'SiteApartmanAdi', LSiteApartmanAdi);
        BindNullableStringParam(LQuery, 'KapiKodu', LKapiKodu);
        BindNullableStringParam(LQuery, 'AdresTarifi', LAdresTarifi);
        BindNullableStringParam(LQuery, 'AdresHash', LAdresHash);
        LQuery.ExecSQL;
      end;

      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('cariId', TJSONNumber.Create(LNewCariID));
      Result.AddPair('cariKod', LCariKod);
      if LCariID = 0 then
        Result.AddPair('message', 'Cari olusturuldu')
      else
        Result.AddPair('message', 'Cari guncellendi');
    finally
      LQuery.Free;
    end;
  finally
    LJson.Free;
  end;
end;

function TSmCari.InsertNewCustomerFull(ACariAdi, ATelefon, AMahalle, ACadde,
  ABinaNo, ADaireNo, AKat, ABlok, ASite: string): TJSONObject;
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('cariId', TJSONNumber.Create(0));
    LJson.AddPair('cariAdi', IfThen(Trim(ACariAdi) <> '', Trim(ACariAdi), Trim(ATelefon)));
    LJson.AddPair('cariTip', 'Musteri');
    LJson.AddPair('telefon1', Trim(ATelefon));
    LJson.AddPair('mahalle', Trim(AMahalle));
    LJson.AddPair('caddeSokak', Trim(ACadde));
    LJson.AddPair('binaNo', Trim(ABinaNo));
    LJson.AddPair('daireNo', Trim(ADaireNo));
    LJson.AddPair('kat', Trim(AKat));
    LJson.AddPair('blok', Trim(ABlok));
    LJson.AddPair('siteApartmanAdi', Trim(ASite));
    Result := SaveCari(LJson.ToString);
  finally
    LJson.Free;
  end;
end;

function TSmCari.CreateCariMobil(AAdSoyad, ATelefon, AAdres: string): TJSONObject;
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('cariId', TJSONNumber.Create(0));
    LJson.AddPair('cariAdi', IfThen(Trim(AAdSoyad) <> '', Trim(AAdSoyad), Trim(ATelefon)));
    LJson.AddPair('cariTip', 'Musteri');
    LJson.AddPair('telefon1', Trim(ATelefon));
    LJson.AddPair('adres', Trim(AAdres));
    Result := SaveCari(LJson.ToString);
  finally
    LJson.Free;
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

      if LNorm <> '' then
      begin
        LQuery.SQL.Text :=
          'SELECT TOP 1 1 FROM CariTelefon WHERE Aktif = 1 AND isnull(TelefonNormalize, '''') = :P';
        LQuery.ParamByName('P').AsString := LNorm;
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
      LQuery.ParamByName('CariAdi').AsString := UpperCase(IfThen(LName <> '', LName, LPhone));
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
    Result.AddPair('message', IntToStr(LImported) + ' kisi eklendi, ' + IntToStr(LSkipped) + ' atlandi');
  finally
    LQuery.Free;
    LArray.Free;
  end;
end;

function TSmCari.LinkPhoneToCari(ACariID: Integer; ATelefon, ATelefonTipi: string;
  ASetPrimary: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LNorm: string;
  LPrimary: Boolean;
begin
  Result := TJSONObject.Create;
  LNorm := NormalizePhone(ATelefon);
  LPrimary := (ASetPrimary = 1);

  if (ACariID <= 0) or (LNorm = '') then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'CariID ve Telefon zorunludur');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    { -- Validate duplicate -- }
    LQuery.SQL.Text :=
      'SELECT TOP 1 C.CariAdi FROM dbo.CariTelefon T ' +
      'INNER JOIN dbo.Cari C ON C.CariID = T.CariID ' +
      'WHERE T.Aktif = 1 AND isnull(T.TelefonNormalize, '''') = :Telefon AND T.CariID <> :CariID';
    LQuery.ParamByName('Telefon').AsString := LNorm;
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;
    if not LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Bu telefon "' + LQuery.Fields[0].AsString + '" carisine kayitli');
      Exit;
    end;
    LQuery.Close;

    if LPrimary then
    begin
      LQuery.SQL.Text := 'UPDATE dbo.CariTelefon SET Varsayilan = 0 WHERE CariID = :CariID';
      LQuery.ParamByName('CariID').AsInteger := ACariID;
      LQuery.ExecSQL;
    end;

    LQuery.SQL.Text :=
      'IF EXISTS (SELECT 1 FROM dbo.CariTelefon WHERE CariID = :CariID AND TelefonNormalize = :TelefonNormalize) ' +
      '  UPDATE dbo.CariTelefon SET Telefon = :Telefon, TelefonTipi = :TelefonTipi, Varsayilan = :Varsayilan, Aktif = 1 WHERE CariID = :CariID AND TelefonNormalize = :TelefonNormalize ' +
      'ELSE ' +
      '  INSERT INTO dbo.CariTelefon (CariID, TelefonTipi, Telefon, TelefonNormalize, Varsayilan, Aktif) VALUES (:CariID, :TelefonTipi, :Telefon, :TelefonNormalize, :Varsayilan, 1)';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.ParamByName('TelefonTipi').AsString := Trim(ATelefonTipi);
    LQuery.ParamByName('Telefon').AsString := Trim(ATelefon);
    LQuery.ParamByName('TelefonNormalize').AsString := LNorm;
    LQuery.ParamByName('Varsayilan').AsBoolean := LPrimary;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Telefon eklendi');
  finally
    LQuery.Free;
  end;
end;

function TSmCari.PasifYap(ACariID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  if ACariID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'CariID zorunludur');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'SELECT TOP 1 1 FROM CariHareket WHERE CariID = :CariID';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;
    if not LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Bu caride hareket var. Hareketli cari pasife alinamaz');
      Exit;
    end;
    LQuery.Close;

    LQuery.SQL.Text := 'UPDATE Cari SET Aktif = 0 WHERE CariID = :CariID';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Cari pasife alindi');
  finally
    LQuery.Free;
  end;
end;

function TSmCari.TahsilatOdeme(ACariID, AKasaID: Integer; AIslemTipi, AAciklama: string;
  ATutar: Double): TJSONObject;
var
  LQuery: TFDQuery;
  LKasaIslemTipi, LBelgeTipi: string;
begin
  Result := TJSONObject.Create;

  if ACariID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Cari secimi zorunludur');
    Exit;
  end;
  if AKasaID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Kasa secimi zorunludur');
    Exit;
  end;
  if ATutar <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Tutar sifirdan buyuk olmalidir');
    Exit;
  end;
  if not SameText(AIslemTipi, 'Tahsilat') and not SameText(AIslemTipi, 'Odeme') then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Islem tipi Tahsilat veya Odeme olmalidir');
    Exit;
  end;

  if SameText(AIslemTipi, 'Tahsilat') then
  begin
    LKasaIslemTipi := 'Giris';
    LBelgeTipi := 'Cari Tahsilat';
  end
  else
  begin
    LKasaIslemTipi := 'Cikis';
    LBelgeTipi := 'Cari Odeme';
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.Connection.StartTransaction;
    try
      LQuery.SQL.Text :=
        'INSERT INTO CariHareket (CariID, Tarih, BelgeTipi, BelgeID, Aciklama, Borc, Alacak, KasaID) ' +
        'VALUES (:CariID, SYSDATETIME(), :BelgeTipi, 0, :Aciklama, :Borc, :Alacak, :KasaID)';
      LQuery.ParamByName('CariID').AsInteger := ACariID;
      LQuery.ParamByName('BelgeTipi').AsString := LBelgeTipi;
      LQuery.ParamByName('Aciklama').AsString := Trim(AAciklama);
      if SameText(AIslemTipi, 'Tahsilat') then
      begin
        LQuery.ParamByName('Borc').AsCurrency := 0;
        LQuery.ParamByName('Alacak').AsCurrency := ATutar;
      end
      else
      begin
        LQuery.ParamByName('Borc').AsCurrency := ATutar;
        LQuery.ParamByName('Alacak').AsCurrency := 0;
      end;
      LQuery.ParamByName('KasaID').AsInteger := AKasaID;
      LQuery.ExecSQL;

      LQuery.SQL.Text :=
        'INSERT INTO KasaHareket (KasaID, Tarih, IslemTipi, BelgeTipi, Tutar, Aciklama) ' +
        'VALUES (:KasaID, SYSDATETIME(), :IslemTipi, :BelgeTipi, :Tutar, :Aciklama)';
      LQuery.ParamByName('KasaID').AsInteger := AKasaID;
      LQuery.ParamByName('IslemTipi').AsString := LKasaIslemTipi;
      LQuery.ParamByName('BelgeTipi').AsString := LBelgeTipi;
      LQuery.ParamByName('Tutar').AsCurrency := ATutar;
      LQuery.ParamByName('Aciklama').AsString := Trim(AAciklama);
      LQuery.ExecSQL;

      LQuery.Connection.Commit;

      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('message', AIslemTipi + ' basariyla kaydedildi');
    except
      on E: Exception do
      begin
        if LQuery.Connection.InTransaction then
          LQuery.Connection.Rollback;
        Result.AddPair('success', TJSONBool.Create(False));
        Result.AddPair('message', 'Hata: ' + E.Message);
      end;
    end;
  finally
    LQuery.Free;
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
      'SELECT StokID, StokKod, StokAdi, isnull(Birim, ''Adet'') AS Birim, ' +
      '  isnull(SatisFiyat, 0) AS SatisFiyat, isnull(KDV, 0) AS KDV ' +
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
