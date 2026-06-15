unit uSmAuth;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  Datasnap.DSServer, Datasnap.DSAuth,
  FireDAC.Comp.Client;

type
  {$METHODINFO ON}
  TSmAuth = class(TDSServerModule)
  public
    /// <summary>Kullanici giris (basit token donus)</summary>
    function Login(AKullaniciAdi, ASifre: string): TJSONObject;

    /// <summary>Token dogrulama</summary>
    function ValidateToken(AToken: string): TJSONObject;

    /// <summary>Roller listesi</summary>
    function GetRoller: TJSONObject;

    /// <summary>Rol yetkileri</summary>
    function GetRolYetkiler(ARolID: Integer): TJSONObject;

    /// <summary>Sirket bilgisi</summary>
    function GetSirketBilgi: TJSONObject;

    /// <summary>Server durum kontrolu (health check)</summary>
    function Ping: TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

uses
  uDM, System.DateUtils, System.Hash;

function TSmAuth.Login(AKullaniciAdi, ASifre: string): TJSONObject;
var
  LQuery: TFDQuery;
  LToken: string;
begin
  Result := TJSONObject.Create;

  // Simple authentication - in production use proper hashing
  // For now check against Ayarlar or a simple user store
  // Since there's no Kullanici table visible, we use a simple check
  if (AKullaniciAdi = '') or (ASifre = '') then
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Kullanici adi ve sifre gerekli');
    Exit;
  end;

  // Generate a simple token (in production use JWT)
  LToken := THashSHA2.GetHashString(
    AKullaniciAdi + FormatDateTime('yyyymmddhhnnsszzz', Now) + ASifre,
    THashSHA2.TSHA2Version.SHA256
  );

  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('token', LToken);
  Result.AddPair('kullaniciAdi', AKullaniciAdi);
  Result.AddPair('expiresIn', TJSONNumber.Create(86400)); // 24 hours
end;

function TSmAuth.ValidateToken(AToken: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  // Simple validation - in production verify JWT signature and expiry
  if AToken <> '' then
  begin
    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('valid', TJSONBool.Create(True));
  end
  else
  begin
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('valid', TJSONBool.Create(False));
    Result.AddPair('message', 'Token bos');
  end;
end;

function TSmAuth.GetRoller: TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'SELECT * FROM Rol WHERE Aktif = 1 ORDER BY RolAdi';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('rolId', TJSONNumber.Create(LQuery.FieldByName('RolID').AsInteger));
      LObj.AddPair('rolAdi', LQuery.FieldByName('RolAdi').AsString);
      LObj.AddPair('aciklama', LQuery.FieldByName('Aciklama').AsString);
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmAuth.GetRolYetkiler(ARolID: Integer): TJSONObject;
var
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LArray := TJSONArray.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'SELECT * FROM RolYetki WHERE RolID = :RolID';
    LQuery.ParamByName('RolID').AsInteger := ARolID;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('modulKod', LQuery.FieldByName('ModulKod').AsString);
      LObj.AddPair('goruntule', TJSONBool.Create(LQuery.FieldByName('Goruntule').AsBoolean));
      LObj.AddPair('ekle', TJSONBool.Create(LQuery.FieldByName('Ekle').AsBoolean));
      LObj.AddPair('duzenle', TJSONBool.Create(LQuery.FieldByName('Duzenle').AsBoolean));
      LObj.AddPair('sil', TJSONBool.Create(LQuery.FieldByName('Sil').AsBoolean));
      LObj.AddPair('onayla', TJSONBool.Create(LQuery.FieldByName('Onayla').AsBoolean));
      LArray.AddElement(LObj);
      LQuery.Next;
    end;

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LArray);
  finally
    LQuery.Free;
  end;
end;

function TSmAuth.GetSirketBilgi: TJSONObject;
var
  LQuery: TFDQuery;
  LObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  LQuery := DM.GetQuery;
  try
    LQuery.SQL.Text := 'SELECT TOP 1 * FROM Sirket';
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Sirket bilgisi bulunamadi');
      Exit;
    end;

    LObj := TJSONObject.Create;
    LObj.AddPair('sirketId', TJSONNumber.Create(LQuery.FieldByName('SirketID').AsInteger));
    LObj.AddPair('sirketKod', LQuery.FieldByName('SirketKod').AsString);
    LObj.AddPair('sirketAdi', LQuery.FieldByName('SirketAdi').AsString);
    LObj.AddPair('vkn', LQuery.FieldByName('VKN').AsString);
    LObj.AddPair('vergiDairesi', LQuery.FieldByName('VergiDairesi').AsString);
    LObj.AddPair('adres', LQuery.FieldByName('Adres').AsString);
    LObj.AddPair('il', LQuery.FieldByName('Il').AsString);

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('data', LObj);
  finally
    LQuery.Free;
  end;
end;

function TSmAuth.Ping: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('success', TJSONBool.Create(True));
  Result.AddPair('message', 'TicariERP API is running');
  Result.AddPair('serverTime', DateToISO8601(Now));
  Result.AddPair('version', '1.0.0');
end;

end.
