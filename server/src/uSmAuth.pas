unit uSmAuth;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  Datasnap.DSServer, Datasnap.DSAuth, Datasnap.DSProviderDataModuleAdapter,
  FireDAC.Comp.Client;

type
  {$METHODINFO ON}
  TSmAuth = class(TDSServerModule)
  public
    /// <summary>Login - ERP_AUTH.AuthUser dogrulama, TenantDatabase bilgisi donus</summary>
    function Login(AKullaniciAdi, ASifre: string): TJSONObject;

    /// <summary>Token dogrulama</summary>
    function ValidateToken(AToken: string): TJSONObject;

    /// <summary>Roller listesi</summary>
    function GetRoller: TJSONObject;

    /// <summary>Rol yetkileri</summary>
    function GetRolYetkiler(ARolID: Integer): TJSONObject;

    /// <summary>Sirket bilgisi (tenant DB uzerinden)</summary>
    function GetSirketBilgi: TJSONObject;

    /// <summary>Server durum kontrolu (health check)</summary>
    function Ping: TJSONObject;
  end;
  {$METHODINFO OFF}

implementation

{$R *.dfm}

uses
  uDM, uDMAuth, System.DateUtils, System.Hash;

function TSmAuth.Login(AKullaniciAdi, ASifre: string): TJSONObject;
var
  LQuery: TFDQuery;
  LToken, LSifreHash: string;
  LUserObj, LTenantObj, LDbObj: TJSONObject;
  LTenantID, LRolID, LUserID: Integer;
  LAdSoyad: string;
  LKurye, LSistemAdmin: Boolean;
begin
  Result := TJSONObject.Create;
  WriteLn('[Login] Giris istegi: KullaniciAdi=' + AKullaniciAdi);

  if (AKullaniciAdi = '') or (ASifre = '') then
  begin
    WriteLn('[Login] HATA: Bos kullanici adi veya sifre');
    Result.AddPair('success', TJSONBool.Create(False));
    Result.AddPair('message', 'Kullanici adi ve sifre gerekli');
    Exit;
  end;

  // Hash the password (SHA256)
  LSifreHash := THashSHA2.GetHashString(ASifre, THashSHA2.TSHA2Version.SHA256);
  WriteLn('[Login] SifreHash: ' + LSifreHash);

  LQuery := DMAuth.GetAuthQuery;
  try
    // Check user in ERP_AUTH.AuthUser
    LQuery.SQL.Text :=
      'SELECT au.AuthUserID, au.TenantID, au.KullaniciAdi, au.AdSoyad, au.RolID, ' +
      '  au.Aktif, au.SistemAdmin, au.Kurye ' +
      'FROM AuthUser au ' +
      'WHERE au.KullaniciAdi = :KulAdi AND au.SifreHash = :SifreHash AND au.Aktif = 1';
    LQuery.ParamByName('KulAdi').AsString := AKullaniciAdi;
    LQuery.ParamByName('SifreHash').AsString := LSifreHash;
    LQuery.Open;
    WriteLn('[Login] AuthUser sorgusu: ' + IntToStr(LQuery.RecordCount) + ' kayit');

    if LQuery.IsEmpty then
    begin
      WriteLn('[Login] HATA: Kullanici bulunamadi veya sifre hatali');
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Kullanici adi veya sifre hatali');
      Exit;
    end;

    LUserID := LQuery.FieldByName('AuthUserID').AsInteger;
    LTenantID := LQuery.FieldByName('TenantID').AsInteger;
    LAdSoyad := LQuery.FieldByName('AdSoyad').AsString;
    LRolID := LQuery.FieldByName('RolID').AsInteger;
    LKurye := LQuery.FieldByName('Kurye').AsBoolean;
    LSistemAdmin := LQuery.FieldByName('SistemAdmin').AsBoolean;

    // Get Tenant info
    LQuery.Close;
    LQuery.SQL.Text :=
      'SELECT TenantKod, TenantAdi, FaaliyetKonusu, LisansBitis FROM Tenant WHERE TenantID = :TID AND Aktif = 1';
    LQuery.ParamByName('TID').AsInteger := LTenantID;
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Tenant aktif degil veya bulunamadi');
      Exit;
    end;

    LTenantObj := TJSONObject.Create;
    LTenantObj.AddPair('tenantId', TJSONNumber.Create(LTenantID));
    LTenantObj.AddPair('tenantKod', LQuery.FieldByName('TenantKod').AsString);
    LTenantObj.AddPair('tenantAdi', LQuery.FieldByName('TenantAdi').AsString);
    LTenantObj.AddPair('faaliyetKonusu', LQuery.FieldByName('FaaliyetKonusu').AsString);

    // Get TenantDatabase connection info
    LQuery.Close;
    LQuery.SQL.Text :=
      'SELECT TenantDatabaseID, DbServer, DbName, DbUser, DbPassword, VarsayilanSirketID ' +
      'FROM TenantDatabase WHERE TenantID = :TID AND Aktif = 1';
    LQuery.ParamByName('TID').AsInteger := LTenantID;
    LQuery.Open;

    if LQuery.IsEmpty then
    begin
      Result.AddPair('success', TJSONBool.Create(False));
      Result.AddPair('message', 'Tenant veritabani yapilandirmasi bulunamadi');
      LTenantObj.Free;
      Exit;
    end;

    LDbObj := TJSONObject.Create;
    LDbObj.AddPair('dbServer', LQuery.FieldByName('DbServer').AsString);
    LDbObj.AddPair('dbName', LQuery.FieldByName('DbName').AsString);
    LDbObj.AddPair('dbUser', LQuery.FieldByName('DbUser').AsString);
    LDbObj.AddPair('dbPassword', LQuery.FieldByName('DbPassword').AsString);
    LDbObj.AddPair('varsayilanSirketId', TJSONNumber.Create(LQuery.FieldByName('VarsayilanSirketID').AsInteger));

    // Generate token
    LToken := THashSHA2.GetHashString(
      IntToStr(LUserID) + AKullaniciAdi + FormatDateTime('yyyymmddhhnnsszzz', Now),
      THashSHA2.TSHA2Version.SHA256
    );

    // Connect to tenant DB dynamically
    DM.ConnectToTenantDB(
      LQuery.FieldByName('DbServer').AsString,
      LQuery.FieldByName('DbName').AsString,
      LQuery.FieldByName('DbUser').AsString,
      LQuery.FieldByName('DbPassword').AsString
    );

    // Build user info
    LUserObj := TJSONObject.Create;
    LUserObj.AddPair('userId', TJSONNumber.Create(LUserID));
    LUserObj.AddPair('kullaniciAdi', AKullaniciAdi);
    LUserObj.AddPair('adSoyad', LAdSoyad);
    LUserObj.AddPair('rolId', TJSONNumber.Create(LRolID));
    LUserObj.AddPair('kurye', TJSONBool.Create(LKurye));
    LUserObj.AddPair('sistemAdmin', TJSONBool.Create(LSistemAdmin));

    WriteLn('[Login] BASARILI: ' + AKullaniciAdi + ' (UserID=' + IntToStr(LUserID) + ', TenantID=' + IntToStr(LTenantID) + ')');

    Result.AddPair('success', TJSONBool.Create(True));
    Result.AddPair('token', LToken);
    Result.AddPair('user', LUserObj);
    Result.AddPair('tenant', LTenantObj);
    Result.AddPair('database', LDbObj);
    Result.AddPair('expiresIn', TJSONNumber.Create(86400));
  finally
    LQuery.Free;
  end;
end;

function TSmAuth.ValidateToken(AToken: string): TJSONObject;
begin
  Result := TJSONObject.Create;
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
  LQuery := DMAuth.GetAuthQuery;
  try
    LQuery.SQL.Text := 'SELECT * FROM Rol WHERE Aktif = 1 ORDER BY RolAdi';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('rolId', TJSONNumber.Create(LQuery.FieldByName('RolID').AsInteger));
      LObj.AddPair('rolAdi', LQuery.FieldByName('RolAdi').AsString);
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
  LQuery := DMAuth.GetAuthQuery;
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
