unit uSmCallerID;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  Datasnap.DSServer, Datasnap.DSAuth, Datasnap.DSProviderDataModuleAdapter,
  FireDAC.Comp.Client;

type
  {$METHODINFO ON}
  TSmCallerID = class(TDSServerModule)
  public
    function ListIncomingCalls(ATarih: string): TJSONObject;
    function ListCallLogs(ATelefon: string): TJSONObject;
    function LogIncomingCall(ACallerId, ATelefon: string; ACariID: Integer;
      ACariAdi, ANotu, ASonuc: string): TJSONObject;
    function AddManualCall(ATelefon, ACariName: string): TJSONObject;
    function AttachCallToCustomer(AAramaLogID: Int64; ACariID: Integer): TJSONObject;
    function DeleteCall(AAramaLogID: Int64): TJSONObject;
    function LinkCallToOrder(AAramaLogID, ASiparisID: Int64): TJSONObject;
    function MergeCallWithExistingOrder(AAramaLogID, ASiparisID: Int64): TJSONObject;
    function GetCallerInfo(ATelefon: string): TJSONObject;
    function GetCariSonSiparisler(ACariID, ALimit: Integer): TJSONObject;
    function CreateQuickOrderFromCall(AAramaLogID: Int64; AStokID, ADagiticiKullaniciID: Integer;
      AMiktar, ABirimFiyat: Double): TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

{$R *.dfm}

uses
  uDM, System.DateUtils;

function TSmCallerID.ListIncomingCalls(ATarih: string): TJSONObject;
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
      'SELECT L.AramaLogID, isnull(L.CallerId, '''') AS CallerId, isnull(L.Telefon, '''') AS Telefon, ' +
      'isnull(L.CagriSayisi, 1) AS CagriSayisi, ' +
      'isnull(C.CariID, 0) AS CariID, isnull(C.CariAdi, '''') AS CariAdi, L.AramaTarih, ' +
      'isnull(A1.AdresSatiri, '''') AS VarsayilanAdres, isnull(A1.Mahalle, '''') AS VarsayilanMahalle, ' +
      'CASE WHEN isnull(C.CariID, 0) > 0 THEN 1 ELSE 0 END AS HasCari, ' +
      'isnull(L.Sonuc, '''') AS Sonuc, isnull(L.Notu, '''') AS Notu, ' +
      'isnull(L.SiparisID, 0) AS SiparisID, isnull(B.Durum, '''') AS SiparisDurum, isnull(B.SiparisNo, '''') AS SiparisNo, ' +
      'isnull(P.SiparisID, 0) AS PendingSiparisID, P.SiparisTarih AS PendingSiparisTarih, ' +
      'isnull(P.UrunOzet, '''') AS PendingUrun, isnull(P.GenelToplam, 0) AS PendingTutar, ' +
      'isnull(R.SiparisID, 0) AS LastSiparisID, R.SiparisTarih AS LastSiparisTarih, ' +
      'isnull(R.UrunOzet, '''') AS LastUrun, isnull(R.GenelToplam, 0) AS LastTutar ' +
      'FROM TupSuAramaLog L ' +
      'OUTER APPLY ( ' +
      '  SELECT TOP 1 C2.CariID, C2.CariAdi ' +
      '  FROM Cari C2 ' +
      '  WHERE C2.Aktif = 1 AND ( ' +
      '    (isnull(L.CariID, 0) > 0 AND C2.CariID = L.CariID) OR ' +
      '    (isnull(L.CariID, 0) = 0 AND isnull(L.Telefon, '''') <> '''' AND EXISTS ( ' +
      '      SELECT 1 FROM dbo.CariTelefon T ' +
      '      WHERE T.CariID = C2.CariID AND T.Aktif = 1 AND RIGHT(isnull(T.TelefonNormalize, ''''), 10) = RIGHT(' +
      '        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(isnull(L.Telefon, ''''), ' +
      '        '' '', ''''), ''-'', ''''), ''('', ''''), '')'', ''''), ''+90'', ''''), ''90'', ''''), 10))) ' +
      '  ) ' +
      '  ORDER BY CASE WHEN C2.CariID = isnull(L.CariID, 0) THEN 0 ELSE 1 END, C2.CariID DESC ' +
      ') C ' +
      'OUTER APPLY (SELECT TOP 1 A.AdresSatiri, A.Mahalle FROM dbo.CariAdres A WHERE A.CariID = C.CariID AND A.Aktif = 1 ORDER BY A.Varsayilan DESC, A.CariAdresID) A1 ' +
      'LEFT JOIN TupSuSiparisBaslik B ON B.SiparisID = L.SiparisID ' +
      'OUTER APPLY ( ' +
      '  SELECT TOP 1 B2.SiparisID, B2.SiparisTarih, B2.GenelToplam, ' +
      '    isnull(stuff((SELECT char(10) + cast(cast(D2.Miktar AS decimal(18,2)) AS varchar(32)) + ' +
      '    '' x '' + isnull(D2.UrunAdi, '''') + '' - '' + cast(cast(D2.SatirToplam AS decimal(18,2)) AS varchar(32)) + '' TL'' ' +
      '    FROM TupSuSiparisDetay D2 WHERE D2.SiparisID = B2.SiparisID ' +
      '    ORDER BY D2.SiparisDetayID FOR XML PATH(''''), TYPE).value(''.'', ''nvarchar(max)''), 1, 1, ''''), ''Siparis'') AS UrunOzet ' +
      '  FROM TupSuSiparisBaslik B2 ' +
      '  WHERE ((isnull(C.CariID, 0) > 0 AND B2.CariID = C.CariID) OR ' +
      '    (isnull(C.CariID, 0) = 0 AND isnull(L.Telefon, '''') <> '''' AND RIGHT(' +
      '      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(isnull(B2.Telefon, ''''), ' +
      '      '' '', ''''), ''-'', ''''), ''('', ''''), '')'', ''''), ''+90'', ''''), ''90'', ''''), 10) = RIGHT(' +
      '      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(isnull(L.Telefon, ''''), ' +
      '      '' '', ''''), ''-'', ''''), ''('', ''''), '')'', ''''), ''+90'', ''''), ''90'', ''''), 10))) ' +
      '    AND B2.Durum NOT IN (''Teslim Edildi'', ''Iptal'') ' +
      '  ORDER BY B2.SiparisTarih DESC, B2.SiparisID DESC ' +
      ') P ' +
      'OUTER APPLY ( ' +
      '  SELECT TOP 1 B2.SiparisID, B2.SiparisTarih, B2.GenelToplam, ' +
      '    isnull(stuff((SELECT char(10) + cast(cast(D2.Miktar AS decimal(18,2)) AS varchar(32)) + ' +
      '    '' x '' + isnull(D2.UrunAdi, '''') + '' - '' + cast(cast(D2.SatirToplam AS decimal(18,2)) AS varchar(32)) + '' TL'' ' +
      '    FROM TupSuSiparisDetay D2 WHERE D2.SiparisID = B2.SiparisID ' +
      '    ORDER BY D2.SiparisDetayID FOR XML PATH(''''), TYPE).value(''.'', ''nvarchar(max)''), 1, 1, ''''), ''Siparis'') AS UrunOzet ' +
      '  FROM TupSuSiparisBaslik B2 ' +
      '  WHERE ((isnull(C.CariID, 0) > 0 AND B2.CariID = C.CariID) OR ' +
      '    (isnull(C.CariID, 0) = 0 AND isnull(L.Telefon, '''') <> '''' AND RIGHT(' +
      '      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(isnull(B2.Telefon, ''''), ' +
      '      '' '', ''''), ''-'', ''''), ''('', ''''), '')'', ''''), ''+90'', ''''), ''90'', ''''), 10) = RIGHT(' +
      '      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(isnull(L.Telefon, ''''), ' +
      '      '' '', ''''), ''-'', ''''), ''('', ''''), '')'', ''''), ''+90'', ''''), ''90'', ''''), 10))) ' +
      '  ORDER BY B2.SiparisTarih DESC, B2.SiparisID DESC ' +
      ') R ' +
      'WHERE isnull(L.SiparisID, 0) = 0 ' +
      'ORDER BY L.AramaTarih DESC, L.AramaLogID DESC';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('aramaLogId', TJSONNumber.Create(LQuery.FieldByName('AramaLogID').AsLargeInt));
      LObj.AddPair('callerId', LQuery.FieldByName('CallerId').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('cagriSayisi', TJSONNumber.Create(LQuery.FieldByName('CagriSayisi').AsInteger));
      LObj.AddPair('cariId', TJSONNumber.Create(LQuery.FieldByName('CariID').AsInteger));
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('aramaTarih', DateToISO8601(LQuery.FieldByName('AramaTarih').AsDateTime));
      LObj.AddPair('varsayilanAdres', LQuery.FieldByName('VarsayilanAdres').AsString);
      LObj.AddPair('varsayilanMahalle', LQuery.FieldByName('VarsayilanMahalle').AsString);
      LObj.AddPair('hasCari', TJSONBool.Create(LQuery.FieldByName('HasCari').AsInteger = 1));
      LObj.AddPair('sonuc', LQuery.FieldByName('Sonuc').AsString);
      LObj.AddPair('notu', LQuery.FieldByName('Notu').AsString);
      LObj.AddPair('siparisId', TJSONNumber.Create(LQuery.FieldByName('SiparisID').AsLargeInt));
      LObj.AddPair('siparisDurum', LQuery.FieldByName('SiparisDurum').AsString);
      LObj.AddPair('siparisNo', LQuery.FieldByName('SiparisNo').AsString);
      LObj.AddPair('pendingSiparisId', TJSONNumber.Create(LQuery.FieldByName('PendingSiparisID').AsLargeInt));
      if not LQuery.FieldByName('PendingSiparisTarih').IsNull then
        LObj.AddPair('pendingSiparisTarih', DateToISO8601(LQuery.FieldByName('PendingSiparisTarih').AsDateTime))
      else
        LObj.AddPair('pendingSiparisTarih', '');
      LObj.AddPair('pendingUrun', LQuery.FieldByName('PendingUrun').AsString);
      LObj.AddPair('pendingTutar', TJSONNumber.Create(LQuery.FieldByName('PendingTutar').AsCurrency));
      LObj.AddPair('lastSiparisId', TJSONNumber.Create(LQuery.FieldByName('LastSiparisID').AsLargeInt));
      if not LQuery.FieldByName('LastSiparisTarih').IsNull then
        LObj.AddPair('lastSiparisTarih', DateToISO8601(LQuery.FieldByName('LastSiparisTarih').AsDateTime))
      else
        LObj.AddPair('lastSiparisTarih', '');
      LObj.AddPair('lastUrun', LQuery.FieldByName('LastUrun').AsString);
      LObj.AddPair('lastTutar', TJSONNumber.Create(LQuery.FieldByName('LastTutar').AsCurrency));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.ListCallLogs(ATelefon: string): TJSONObject;
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
      'SELECT TOP 50 AramaTarih, CallerId, Telefon, CariAdi, Sonuc, Notu ' +
      'FROM TupSuAramaLog ' +
      'WHERE (:Telefon = '''' OR Telefon LIKE :LikeTelefon) ' +
      'ORDER BY AramaTarih DESC, AramaLogID DESC';
    LQuery.ParamByName('Telefon').AsString := Trim(ATelefon);
    LQuery.ParamByName('LikeTelefon').AsString := '%' + Trim(ATelefon) + '%';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('aramaTarih', DateToISO8601(LQuery.FieldByName('AramaTarih').AsDateTime));
      LObj.AddPair('callerId', LQuery.FieldByName('CallerId').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('sonuc', LQuery.FieldByName('Sonuc').AsString);
      LObj.AddPair('notu', LQuery.FieldByName('Notu').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.LogIncomingCall(ACallerId, ATelefon: string; ACariID: Integer;
  ACariAdi, ANotu, ASonuc: string): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'DECLARE @ExistingID BIGINT; ' +
      'SELECT TOP 1 @ExistingID = AramaLogID FROM TupSuAramaLog ' +
      'WHERE isnull(SiparisID, 0) = 0 AND isnull(Telefon, '''') = :Telefon; ' +
      'IF isnull(@ExistingID, 0) > 0 ' +
      'BEGIN ' +
      '  UPDATE TupSuAramaLog SET ' +
      '    CallerId = :CallerId, Telefon = :Telefon, ' +
      '    CariID = CASE WHEN :CariID > 0 THEN :CariID ELSE CariID END, ' +
      '    CariAdi = CASE WHEN :CariAdi <> '''' THEN :CariAdi ELSE CariAdi END, ' +
      '    Notu = :Notu, Sonuc = :Sonuc, AramaTarih = GETDATE(), ' +
      '    CagriSayisi = isnull(CagriSayisi, 1) + 1 ' +
      '  WHERE AramaLogID = @ExistingID; ' +
      '  UPDATE B SET SiparisTarih = GETDATE() ' +
      '  FROM dbo.TupSuSiparisBaslik B ' +
      '  INNER JOIN dbo.TupSuAramaLog L ON L.SiparisID = B.SiparisID ' +
      '  WHERE L.AramaLogID = @ExistingID AND isnull(B.Durum, '''') <> ''Teslim Edildi''; ' +
      'END ' +
      'ELSE ' +
      'BEGIN ' +
      '  INSERT INTO TupSuAramaLog (CallerId, Telefon, CariID, CariAdi, CagriSayisi, Notu, Sonuc) ' +
      '  VALUES (:CallerId, :Telefon, :CariID, :CariAdi, 1, :Notu, :Sonuc); ' +
      'END';
    LQuery.ParamByName('CallerId').AsString := Trim(ACallerId);
    LQuery.ParamByName('Telefon').AsString := Trim(ATelefon);
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.ParamByName('CariAdi').AsString := Trim(ACariAdi);
    LQuery.ParamByName('Notu').AsString := Trim(ANotu);
    LQuery.ParamByName('Sonuc').AsString := Trim(ASonuc);
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Arama logu kaydedildi');
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.AddManualCall(ATelefon, ACariName: string): TJSONObject;
var
  LQuery: TFDQuery;
  LCariID: Integer;
  LCariAdi, LPhone: string;
begin
  Result := TJSONObject.Create;
  LPhone := Trim(ATelefon);
  LCariID := 0;
  LCariAdi := Trim(ACariName);

  LQuery := DM.GetQuery;
  try
    // Try to find customer by phone or name
    if LPhone <> '' then
    begin
      LQuery.SQL.Text :=
        'SELECT TOP 1 C.CariID, C.CariAdi FROM Cari C ' +
        'INNER JOIN CariTelefon T ON T.CariID = C.CariID AND T.Aktif = 1 ' +
        'WHERE C.Aktif = 1 AND isnull(T.TelefonNormalize, '''') LIKE :P';
      LQuery.ParamByName('P').AsString := '%' +
        LPhone.Replace(' ', '').Replace('-', '').Replace('(', '').Replace(')', '').Replace('+90', '').Replace('90', '') + '%';
      LQuery.Open;
      if not LQuery.IsEmpty then
      begin
        LCariID := LQuery.FieldByName('CariID').AsInteger;
        LCariAdi := LQuery.FieldByName('CariAdi').AsString;
      end;
      LQuery.Close;
    end
    else if LCariAdi <> '' then
    begin
      LQuery.SQL.Text :=
        'SELECT TOP 1 C.CariID, C.CariAdi FROM Cari C ' +
        'WHERE C.Aktif = 1 AND C.CariAdi LIKE :Arama ORDER BY C.CariID DESC';
      LQuery.ParamByName('Arama').AsString := '%' + LCariAdi + '%';
      LQuery.Open;
      if not LQuery.IsEmpty then
      begin
        LCariID := LQuery.FieldByName('CariID').AsInteger;
        LCariAdi := LQuery.FieldByName('CariAdi').AsString;
      end;
      LQuery.Close;
    end;

    LQuery.SQL.Text :=
      'DECLARE @ExistingID BIGINT; ' +
      'SELECT TOP 1 @ExistingID = AramaLogID FROM TupSuAramaLog ' +
      'WHERE isnull(SiparisID, 0) = 0 AND ' +
      '((:Telefon <> '''' AND isnull(Telefon, '''') = :Telefon) OR ' +
      ' (:Telefon = '''' AND :CariAdi <> '''' AND isnull(CariAdi, '''') = :CariAdi)); ' +
      'IF isnull(@ExistingID, 0) > 0 ' +
      'BEGIN ' +
      '  UPDATE TupSuAramaLog SET ' +
      '    CallerId = ''MANUAL'', ' +
      '    CariID = CASE WHEN :CariID > 0 THEN :CariID ELSE CariID END, ' +
      '    CariAdi = CASE WHEN :CariAdi <> '''' THEN :CariAdi ELSE CariAdi END, ' +
      '    Telefon = CASE WHEN :Telefon <> '''' THEN :Telefon ELSE Telefon END, ' +
      '    Notu = ''Manuel cagri'', Sonuc = ''Bekliyor'', ' +
      '    AramaTarih = GETDATE(), CagriSayisi = isnull(CagriSayisi, 1) + 1 ' +
      '  WHERE AramaLogID = @ExistingID; ' +
      'END ' +
      'ELSE ' +
      'BEGIN ' +
      '  INSERT INTO TupSuAramaLog (CallerId, Telefon, CariID, CariAdi, CagriSayisi, Notu, Sonuc) ' +
      '  VALUES (''MANUAL'', :Telefon, :CariID, :CariAdi, 1, ''Manuel cagri'', ''Bekliyor''); ' +
      'END';
    LQuery.ParamByName('Telefon').AsString := LPhone;
    LQuery.ParamByName('CariID').AsInteger := LCariID;
    LQuery.ParamByName('CariAdi').AsString := LCariAdi;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Manuel cagri eklendi');
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.AttachCallToCustomer(AAramaLogID: Int64; ACariID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  if (AAramaLogID <= 0) or (ACariID <= 0) then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz parametre');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE L SET ' +
      '  L.CariID = C.CariID, ' +
      '  L.CariAdi = C.CariAdi, ' +
      '  L.Telefon = CASE WHEN isnull(L.Telefon, '''') = '''' THEN isnull(P1.Telefon, '''') ELSE L.Telefon END, ' +
      '  L.Sonuc = CASE WHEN isnull(L.SiparisID, 0) > 0 THEN ''Siparis Girildi'' ELSE ''Cari Secildi'' END, ' +
      '  L.Notu = ''Cari karti ile eslestirildi'' ' +
      'FROM TupSuAramaLog L ' +
      'INNER JOIN Cari C ON C.CariID = :CariID ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM dbo.CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 ORDER BY T.Varsayilan DESC, T.CariTelefonID) P1 ' +
      'WHERE L.AramaLogID = :AramaLogID';
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.ParamByName('AramaLogID').AsLargeInt := AAramaLogID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Cagri musteri ile eslesti');
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.DeleteCall(AAramaLogID: Int64): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  if AAramaLogID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz AramaLogID');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'DELETE FROM TupSuAramaLog WHERE AramaLogID = :AramaLogID AND isnull(SiparisID, 0) = 0';
    LQuery.ParamByName('AramaLogID').AsLargeInt := AAramaLogID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Cagri silindi');
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.LinkCallToOrder(AAramaLogID, ASiparisID: Int64): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  if AAramaLogID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz AramaLogID');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE TupSuAramaLog SET SiparisID = :SiparisID, Sonuc = ''Siparise Baglandi'', Notu = '''' ' +
      'WHERE AramaLogID = :AramaLogID';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.ParamByName('AramaLogID').AsLargeInt := AAramaLogID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Cagri siparise baglandi');
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.MergeCallWithExistingOrder(AAramaLogID, ASiparisID: Int64): TJSONObject;
var
  LQuery: TFDQuery;
begin
  Result := TJSONObject.Create;
  if AAramaLogID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz AramaLogID');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE TupSuAramaLog SET SiparisID = :SiparisID, Sonuc = ''Siparis Girildi'', Notu = ''Mevcut siparis ile birlestirildi'' ' +
      'WHERE AramaLogID = :AramaLogID';
    LQuery.ParamByName('SiparisID').AsLargeInt := ASiparisID;
    LQuery.ParamByName('AramaLogID').AsLargeInt := AAramaLogID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Cagri siparis ile birlestirildi');
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.GetCallerInfo(ATelefon: string): TJSONObject;
var
  LQuery: TFDQuery;
  LCariObj: TJSONObject;
  LCariID: Integer;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT TOP 1 C.CariID, C.CariAdi, isnull(C.CariUnvani, '''') AS CariUnvani, ' +
      'isnull(P1.Telefon, '''') AS Telefon1, isnull(P2.Telefon, '''') AS Telefon2, ' +
      'isnull(A1.AdresSatiri, '''') AS Adres, isnull(A1.Mahalle, '''') AS Mahalle, ' +
      'isnull((SELECT SUM(isnull(H.Borc, 0) - isnull(H.Alacak, 0)) FROM CariHareket H WHERE H.CariID = C.CariID), 0) AS CariBorc ' +
      'FROM Cari C ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 ORDER BY T.Varsayilan DESC, T.CariTelefonID) P1 ' +
      'OUTER APPLY (SELECT TOP 1 T.Telefon FROM CariTelefon T WHERE T.CariID = C.CariID AND T.Aktif = 1 AND isnull(P1.Telefon, '''') <> isnull(T.Telefon, '''') ORDER BY T.Varsayilan DESC, T.CariTelefonID) P2 ' +
      'OUTER APPLY (SELECT TOP 1 A.AdresSatiri, A.Mahalle, A.Ilce, A.Il FROM CariAdres A WHERE A.CariID = C.CariID AND A.Aktif = 1 ORDER BY A.Varsayilan DESC, A.CariAdresID) A1 ' +
      'WHERE C.Aktif = 1 AND EXISTS ( ' +
      '  SELECT 1 FROM CariTelefon T ' +
      '  WHERE T.CariID = C.CariID AND T.Aktif = 1 AND isnull(T.TelefonNormalize, '''') LIKE :P) ' +
      'ORDER BY C.CariID DESC';
    LQuery.ParamByName('P').AsString := '%' +
      ATelefon.Replace(' ', '').Replace('-', '').Replace('(', '').Replace(')', '').Replace('+90', '').Replace('90', '') + '%';
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('kayitli', TJSONBool.Create(False));
      Result.AddPair('telefon', ATelefon);
      Exit;
    end;

    LCariID := LQuery.FieldByName('CariID').AsInteger;
    LCariObj := TJSONObject.Create;
    LCariObj.AddPair('cariId', TJSONNumber.Create(LCariID));
    LCariObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
    LCariObj.AddPair('cariUnvani', LQuery.FieldByName('CariUnvani').AsString);
    LCariObj.AddPair('telefon1', LQuery.FieldByName('Telefon1').AsString);
    LCariObj.AddPair('telefon2', LQuery.FieldByName('Telefon2').AsString);
    LCariObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
    LCariObj.AddPair('mahalle', LQuery.FieldByName('Mahalle').AsString);
    LCariObj.AddPair('cariBorc', TJSONNumber.Create(LQuery.FieldByName('CariBorc').AsCurrency));

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('kayitli', TJSONBool.Create(True));
    Result.AddPair('musteri', LCariObj);
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.GetCariSonSiparisler(ACariID, ALimit: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  if ALimit < 1 then ALimit := 2;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT TOP(:Limit) s.SiparisID, s.SiparisNo, s.Durum, s.GenelToplam, s.SiparisTarih, ' +
      'isnull(s.OdemeTipi, '''') AS OdemeTipi, ' +
      'isnull(stuff((SELECT char(10) + cast(cast(D.Miktar AS decimal(18,2)) AS varchar(32)) + ' +
      ''' x '' + isnull(D.UrunAdi, '''') FROM TupSuSiparisDetay D WHERE D.SiparisID = s.SiparisID ' +
      'ORDER BY D.SiparisDetayID FOR XML PATH(''''), TYPE).value(''.'', ''nvarchar(max)''), 1, 1, ''''), ''Siparis'') AS UrunOzet ' +
      'FROM TupSuSiparisBaslik s ' +
      'WHERE s.CariID = :CariID ' +
      'ORDER BY s.SiparisTarih DESC';
    LQuery.ParamByName('Limit').AsInteger := ALimit;
    LQuery.ParamByName('CariID').AsInteger := ACariID;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('siparisId', TJSONNumber.Create(LQuery.FieldByName('SiparisID').AsLargeInt));
      LObj.AddPair('siparisNo', LQuery.FieldByName('SiparisNo').AsString);
      LObj.AddPair('durum', LQuery.FieldByName('Durum').AsString);
      LObj.AddPair('genelToplam', TJSONNumber.Create(LQuery.FieldByName('GenelToplam').AsCurrency));
      LObj.AddPair('siparisTarih', DateToISO8601(LQuery.FieldByName('SiparisTarih').AsDateTime));
      LObj.AddPair('odemeTipi', LQuery.FieldByName('OdemeTipi').AsString);
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

function TSmCallerID.CreateQuickOrderFromCall(AAramaLogID: Int64; AStokID, ADagiticiKullaniciID: Integer;
  AMiktar, ABirimFiyat: Double): TJSONObject;
var
  LQuery: TFDQuery;
  LSiparisID: Int64;
  LSiparisNo: string;
  LCariID: Integer;
  LCariAdi, LTelefon, LAdres, LMahalle, LCallerId, LUrunAdi: string;
  LBirimFiyat, LMiktar, LToplam: Currency;
begin
  Result := TJSONObject.Create;
  if AAramaLogID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz cagri kaydi');
    Exit;
  end;
  if AStokID <= 0 then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Stok seciniz');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    // Get call info
    LQuery.SQL.Text :=
      'SELECT L.*, isnull(C.CariID, 0) AS ResCariID, isnull(C.CariAdi, '''') AS ResCariAdi, ' +
      'isnull(A1.AdresSatiri, '''') AS ResAdres, isnull(A1.Mahalle, '''') AS ResMahalle ' +
      'FROM TupSuAramaLog L ' +
      'OUTER APPLY (SELECT TOP 1 C2.CariID, C2.CariAdi FROM Cari C2 WHERE C2.Aktif = 1 AND ' +
      '  ((isnull(L.CariID, 0) > 0 AND C2.CariID = L.CariID) OR ' +
      '   (isnull(L.CariID, 0) = 0 AND isnull(L.Telefon, '''') <> '''' AND EXISTS ( ' +
      '    SELECT 1 FROM CariTelefon T WHERE T.CariID = C2.CariID AND T.Aktif = 1 AND ' +
      '    isnull(T.TelefonNormalize, '''') LIKE ''%'' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(' +
      '    isnull(L.Telefon, ''''), '' '', ''''), ''-'', ''''), ''('', ''''), '')'', ''''), ''+90'', ''''), ''90'', '''') + ''%''))) ' +
      'ORDER BY CASE WHEN C2.CariID = isnull(L.CariID, 0) THEN 0 ELSE 1 END) C ' +
      'OUTER APPLY (SELECT TOP 1 A.AdresSatiri, A.Mahalle FROM CariAdres A WHERE A.CariID = C.CariID AND A.Aktif = 1 ORDER BY A.Varsayilan DESC) A1 ' +
      'WHERE L.AramaLogID = :AramaLogID';
    LQuery.ParamByName('AramaLogID').AsLargeInt := AAramaLogID;
    LQuery.Open;
    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Cagri kaydi bulunamadi');
      Exit;
    end;

    LCariID := LQuery.FieldByName('ResCariID').AsInteger;
    if LCariID <= 0 then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Bu cagri icin once musteri baglanmali');
      Exit;
    end;

    LCariAdi := LQuery.FieldByName('ResCariAdi').AsString;
    LTelefon := LQuery.FieldByName('Telefon').AsString;
    LAdres := LQuery.FieldByName('ResAdres').AsString;
    LMahalle := LQuery.FieldByName('ResMahalle').AsString;
    LCallerId := LQuery.FieldByName('CallerId').AsString;
    LQuery.Close;

    // Get stock info
    LQuery.SQL.Text := 'SELECT StokAdi, SatisFiyat FROM Stok WHERE StokID = :StokID AND Aktif = 1';
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.Open;
    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Stok bulunamadi');
      Exit;
    end;
    LUrunAdi := LQuery.FieldByName('StokAdi').AsString;
    LBirimFiyat := LQuery.FieldByName('SatisFiyat').AsCurrency;
    LQuery.Close;

    // Override price if provided
    if ABirimFiyat > 0 then
      LBirimFiyat := ABirimFiyat;
    LMiktar := AMiktar;
    if LMiktar <= 0 then
      LMiktar := 1;
    LToplam := LMiktar * LBirimFiyat;

    // Create order
    LSiparisNo := 'TS' + FormatDateTime('yymmddhhnnsszzz', Now) + IntToStr(Random(90) + 10);
    LQuery.SQL.Text :=
      'INSERT INTO TupSuSiparisBaslik ' +
      '(SiparisNo, AramaLogID, CariID, CariAdi, Telefon, Adres, Mahalle, CallerId, Durum, ' +
      ' SiparisKaynak, DagitimDurum, DagiticiKullaniciID, OdemeTipi, AraToplam, Indirim, GenelToplam) ' +
      'VALUES (:SiparisNo, :AramaLogID, :CariID, :CariAdi, :Telefon, :Adres, :Mahalle, :CallerId, ' +
      ' ''Beklemede'', ''CallerID'', ''Beklemede'', :DagiticiKullaniciID, ''Nakit'', :Toplam, 0, :Toplam); ' +
      'SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS SiparisID';
    LQuery.ParamByName('SiparisNo').AsString := LSiparisNo;
    LQuery.ParamByName('AramaLogID').AsLargeInt := AAramaLogID;
    LQuery.ParamByName('CariID').AsInteger := LCariID;
    LQuery.ParamByName('CariAdi').AsString := LCariAdi;
    LQuery.ParamByName('Telefon').AsString := LTelefon;
    LQuery.ParamByName('Adres').AsString := LAdres;
    LQuery.ParamByName('Mahalle').AsString := LMahalle;
    LQuery.ParamByName('CallerId').AsString := LCallerId;
    LQuery.ParamByName('DagiticiKullaniciID').DataType := ftInteger;
    if ADagiticiKullaniciID > 0 then
      LQuery.ParamByName('DagiticiKullaniciID').AsInteger := ADagiticiKullaniciID
    else
      LQuery.ParamByName('DagiticiKullaniciID').Clear;
    LQuery.ParamByName('Toplam').AsCurrency := LToplam;
    LQuery.Open;
    LSiparisID := LQuery.FieldByName('SiparisID').AsLargeInt;
    LQuery.Close;

    // Add detail line
    LQuery.SQL.Text :=
      'INSERT INTO TupSuSiparisDetay (SiparisID, StokID, UrunAdi, Miktar, BirimFiyat, SatirToplam) ' +
      'VALUES (:SiparisID, :StokID, :UrunAdi, :Miktar, :BirimFiyat, :SatirToplam)';
    LQuery.ParamByName('SiparisID').AsLargeInt := LSiparisID;
    LQuery.ParamByName('StokID').AsInteger := AStokID;
    LQuery.ParamByName('UrunAdi').AsString := LUrunAdi;
    LQuery.ParamByName('Miktar').AsCurrency := LMiktar;
    LQuery.ParamByName('BirimFiyat').AsCurrency := LBirimFiyat;
    LQuery.ParamByName('SatirToplam').AsCurrency := LToplam;
    LQuery.ExecSQL;

    // Link call to order
    LQuery.SQL.Text :=
      'UPDATE TupSuAramaLog SET SiparisID = :SiparisID, Sonuc = ''Siparis Olusturuldu'' ' +
      'WHERE AramaLogID = :AramaLogID';
    LQuery.ParamByName('SiparisID').AsLargeInt := LSiparisID;
    LQuery.ParamByName('AramaLogID').AsLargeInt := AAramaLogID;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('siparisId', TJSONNumber.Create(LSiparisID));
    Result.AddPair('siparisNo', LSiparisNo);
    Result.AddPair('message', 'Hizli siparis olusturuldu');
  finally
    LQuery.Free;
  end;
end;

end.
