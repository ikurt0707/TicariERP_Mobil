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
    /// <summary>Gelen arama kaydet (CallerID event)</summary>
    function LogCallerIdEvent(ATelefon, ACallerId, AEventTipi: string): TJSONObject;

    /// <summary>Telefon ile musteri ve siparis bilgisi getir (popup icin)</summary>
    function GetCallerInfo(ATelefon: string): TJSONObject;

    /// <summary>Arama log kaydet</summary>
    function CreateAramaLog(AAramaJson: string): TJSONObject;

    /// <summary>Arama loglarini listele</summary>
    function GetAramaLoglar(APage, APageSize: Integer): TJSONObject;

    /// <summary>Son gelen aramalar</summary>
    function GetSonAramalar(ALimit: Integer): TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

{$R *.dfm}

uses
  uDM, System.DateUtils;

function TSmCallerID.LogCallerIdEvent(ATelefon, ACallerId, AEventTipi: string): TJSONObject;
var
  LQuery: TFDQuery;
  LCariAdi: string;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    // Find cari name by phone
    LQuery.SQL.Text :=
      'SELECT TOP 1 c.CariAdi FROM Cari c ' +
      'INNER JOIN CariTelefon ct ON ct.CariID = c.CariID ' +
      'WHERE ct.TelefonNormalize LIKE :Tel OR ct.Telefon LIKE :TelFull';
    LQuery.ParamByName('Tel').AsString := '%' + ATelefon;
    LQuery.ParamByName('TelFull').AsString := '%' + ATelefon + '%';
    LQuery.Open;

    if not LQuery.IsEmpty then
      LCariAdi := LQuery.FieldByName('CariAdi').AsString
    else
      LCariAdi := '';

    LQuery.Close;
    LQuery.SQL.Text :=
      'INSERT INTO CallerIdEvent (Telefon, CallerId, CariAdi, EventTipi, OlusmaTarih) ' +
      'VALUES (:Telefon, :CallerId, :CariAdi, :EventTipi, GETDATE())';
    LQuery.ParamByName('Telefon').AsString := ATelefon;
    LQuery.ParamByName('CallerId').AsString := ACallerId;
    LQuery.ParamByName('CariAdi').AsString := LCariAdi;
    LQuery.ParamByName('EventTipi').AsString := AEventTipi;
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('cariAdi', LCariAdi);
    Result.AddPair('kayitli', TJSONBool.Create(LCariAdi <> ''));
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.GetCallerInfo(ATelefon: string): TJSONObject;
var
  LQuery: TFDQuery;
  LCariObj, LSiparisObj: TJSONObject;
  LCariID: Integer;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    // Find customer by phone
    LQuery.SQL.Text :=
      'SELECT TOP 1 c.CariID, c.CariAdi, c.CariTip, ct.Telefon, ' +
      '  (SELECT TOP 1 AdresSatiri FROM CariAdres WHERE CariID = c.CariID AND Varsayilan = 1) AS Adres, ' +
      '  (SELECT COUNT(*) FROM TupSuSiparisBaslik WHERE CariID = c.CariID) AS SiparisSayisi ' +
      'FROM Cari c ' +
      'INNER JOIN CariTelefon ct ON ct.CariID = c.CariID ' +
      'WHERE ct.TelefonNormalize LIKE :Tel OR ct.Telefon LIKE :TelFull';
    LQuery.ParamByName('Tel').AsString := '%' + ATelefon;
    LQuery.ParamByName('TelFull').AsString := '%' + ATelefon + '%';
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
    LCariObj.AddPair('cariTip', LQuery.FieldByName('CariTip').AsString);
    LCariObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
    LCariObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
    LCariObj.AddPair('siparisSayisi', TJSONNumber.Create(LQuery.FieldByName('SiparisSayisi').AsInteger));

    // Get last order
    LQuery.Close;
    LQuery.SQL.Text :=
      'SELECT TOP 1 SiparisID, SiparisNo, Durum, GenelToplam, SiparisTarih ' +
      'FROM TupSuSiparisBaslik WHERE CariID = :CariID ORDER BY SiparisTarih DESC';
    LQuery.ParamByName('CariID').AsInteger := LCariID;
    LQuery.Open;

    LSiparisObj := nil;
    if not LQuery.IsEmpty then
    begin
      LSiparisObj := TJSONObject.Create;
      LSiparisObj.AddPair('siparisId', TJSONNumber.Create(LQuery.FieldByName('SiparisID').AsLargeInt));
      LSiparisObj.AddPair('siparisNo', LQuery.FieldByName('SiparisNo').AsString);
      LSiparisObj.AddPair('durum', LQuery.FieldByName('Durum').AsString);
      LSiparisObj.AddPair('genelToplam', TJSONNumber.Create(LQuery.FieldByName('GenelToplam').AsCurrency));
      LSiparisObj.AddPair('siparisTarih', DateToISO8601(LQuery.FieldByName('SiparisTarih').AsDateTime));
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('kayitli', TJSONBool.Create(True));
    Result.AddPair('musteri', LCariObj);
    if Assigned(LSiparisObj) then
      Result.AddPair('sonSiparis', LSiparisObj)
    else
      Result.AddPair('sonSiparis', TJSONNull.Create);
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.CreateAramaLog(AAramaJson: string): TJSONObject;
var
  LQuery: TFDQuery;
  LJson: TJSONObject;
begin
  Result := TJSONObject.Create;
  LJson := TJSONObject.ParseJSONValue(AAramaJson) as TJSONObject;
  if LJson = nil then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Gecersiz JSON');
    Exit;
  end;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'INSERT INTO TupSuAramaLog (CallerId, Telefon, CariID, CariAdi, CagriSayisi, Notu, Sonuc, AramaTarih) ' +
      'VALUES (:CallerId, :Telefon, :CariID, :CariAdi, :CagriSayisi, :Notu, :Sonuc, GETDATE())';
    LQuery.ParamByName('CallerId').AsString := LJson.GetValue<string>('callerId', '');
    LQuery.ParamByName('Telefon').AsString := LJson.GetValue<string>('telefon', '');
    LQuery.ParamByName('CariID').AsInteger := LJson.GetValue<Integer>('cariId', 0);
    LQuery.ParamByName('CariAdi').AsString := LJson.GetValue<string>('cariAdi', '');
    LQuery.ParamByName('CagriSayisi').AsInteger := LJson.GetValue<Integer>('cagriSayisi', 1);
    LQuery.ParamByName('Notu').AsString := LJson.GetValue<string>('notu', '');
    LQuery.ParamByName('Sonuc').AsString := LJson.GetValue<string>('sonuc', '');
    LQuery.ExecSQL;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('message', 'Arama logu kaydedildi');
  finally
    LQuery.Free;
    LJson.Free;
  end;
end;

function TSmCallerID.GetAramaLoglar(APage, APageSize: Integer): TJSONObject;
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
      'SELECT * FROM TupSuAramaLog ' +
      'ORDER BY AramaTarih DESC ' +
      'OFFSET :Offset ROWS FETCH NEXT :PageSize ROWS ONLY';
    LQuery.ParamByName('Offset').AsInteger := LOffset;
    LQuery.ParamByName('PageSize').AsInteger := APageSize;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('aramaLogId', TJSONNumber.Create(LQuery.FieldByName('AramaLogID').AsLargeInt));
      LObj.AddPair('callerId', LQuery.FieldByName('CallerId').AsString);
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('cagriSayisi', TJSONNumber.Create(LQuery.FieldByName('CagriSayisi').AsInteger));
      LObj.AddPair('sonuc', LQuery.FieldByName('Sonuc').AsString);
      LObj.AddPair('aramaTarih', DateToISO8601(LQuery.FieldByName('AramaTarih').AsDateTime));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmCallerID.GetSonAramalar(ALimit: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  if ALimit < 1 then ALimit := 10;

  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text :=
      'SELECT TOP(:Limit) * FROM CallerIdEvent ORDER BY OlusmaTarih DESC';
    LQuery.ParamByName('Limit').AsInteger := ALimit;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('eventId', TJSONNumber.Create(LQuery.FieldByName('EventID').AsLargeInt));
      LObj.AddPair('telefon', LQuery.FieldByName('Telefon').AsString);
      LObj.AddPair('callerId', LQuery.FieldByName('CallerId').AsString);
      LObj.AddPair('cariAdi', LQuery.FieldByName('CariAdi').AsString);
      LObj.AddPair('eventTipi', LQuery.FieldByName('EventTipi').AsString);
      LObj.AddPair('tarih', DateToISO8601(LQuery.FieldByName('OlusmaTarih').AsDateTime));
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
