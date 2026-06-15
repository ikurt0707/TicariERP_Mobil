unit uAuthService;

interface

uses
  System.SysUtils, System.Classes, System.JSON, uApiService;

type
  TLoginResult = record
    Success: Boolean;
    Token: string;
    UserId: Integer;
    UserName: string;
    AdSoyad: string;
    BayiName: string;
    RolID: Integer;
    IsKurye: Boolean;
    TenantID: Integer;
    TenantAdi: string;
    ErrorMessage: string;
  end;

  TAuthService = class
  private
    FApiService: TApiService;
    FIsLoggedIn: Boolean;
    FUserId: Integer;
    FUserName: string;
    FAdSoyad: string;
    FBayiName: string;
    FRolID: Integer;
    FIsKurye: Boolean;
    FTenantID: Integer;
    FTenantAdi: string;
  public
    constructor Create(AApiService: TApiService);

    function Login(const AUsername, APassword: string): TLoginResult;
    procedure Logout;
    function IsAuthenticated: Boolean;

    procedure SetUserInfo(AUserID: Integer; const AKullaniciAdi, AAdSoyad: string;
      ARolID: Integer; AKurye: Boolean);
    procedure SetTenantInfo(ATenantID: Integer; const ATenantAdi: string);

    property IsLoggedIn: Boolean read FIsLoggedIn;
    property UserId: Integer read FUserId;
    property UserName: string read FUserName;
    property AdSoyad: string read FAdSoyad;
    property BayiName: string read FBayiName;
    property RolID: Integer read FRolID;
    property IsKurye: Boolean read FIsKurye;
    property TenantID: Integer read FTenantID;
    property TenantAdi: string read FTenantAdi;
  end;

var
  AuthService: TAuthService;

implementation

uses
  uConstants;

constructor TAuthService.Create(AApiService: TApiService);
begin
  inherited Create;
  FApiService := AApiService;
  FIsLoggedIn := False;
  FUserId := 0;
  FUserName := '';
  FAdSoyad := '';
  FBayiName := '';
  FRolID := 0;
  FIsKurye := False;
  FTenantID := 0;
  FTenantAdi := '';
end;

function TAuthService.Login(const AUsername, APassword: string): TLoginResult;
var
  LResponse: TApiResponse;
  LData, LUser, LTenant: TJSONObject;
begin
  Result.Success := False;
  Result.Token := '';
  Result.UserId := 0;
  Result.UserName := '';
  Result.AdSoyad := '';
  Result.BayiName := '';
  Result.RolID := 0;
  Result.IsKurye := False;
  Result.TenantID := 0;
  Result.TenantAdi := '';
  Result.ErrorMessage := '';

  LResponse := FApiService.Get('rest/TSmAuth/Login/' + AUsername + '/' + APassword);
  try
    if not LResponse.Success then
    begin
      Result.ErrorMessage := LResponse.ErrorMessage;
      Exit;
    end;

    if not (LResponse.Data is TJSONObject) then
    begin
      Result.ErrorMessage := 'Gecersiz sunucu yaniti';
      Exit;
    end;

    LData := TJSONObject(LResponse.Data);
    if not LData.GetValue<Boolean>('success', False) then
    begin
      Result.ErrorMessage := LData.GetValue<string>('message', 'Giris basarisiz');
      Exit;
    end;

    Result.Success := True;
    Result.Token := LData.GetValue<string>('token', '');

    LUser := LData.GetValue<TJSONObject>('user');
    if Assigned(LUser) then
    begin
      Result.UserId := LUser.GetValue<Integer>('userId', 0);
      Result.UserName := LUser.GetValue<string>('kullaniciAdi', '');
      Result.AdSoyad := LUser.GetValue<string>('adSoyad', '');
      Result.RolID := LUser.GetValue<Integer>('rolId', 0);
      Result.IsKurye := LUser.GetValue<Boolean>('kurye', False);
    end;

    LTenant := LData.GetValue<TJSONObject>('tenant');
    if Assigned(LTenant) then
    begin
      Result.TenantID := LTenant.GetValue<Integer>('tenantId', 0);
      Result.TenantAdi := LTenant.GetValue<string>('tenantAdi', '');
      Result.BayiName := LTenant.GetValue<string>('tenantAdi', '');
    end;

    // Apply auth
    FApiService.SetToken(Result.Token);
    FIsLoggedIn := True;
    FUserId := Result.UserId;
    FUserName := Result.UserName;
    FAdSoyad := Result.AdSoyad;
    FBayiName := Result.BayiName;
    FRolID := Result.RolID;
    FIsKurye := Result.IsKurye;
    FTenantID := Result.TenantID;
    FTenantAdi := Result.TenantAdi;
  finally
    LResponse.Free;
  end;
end;

procedure TAuthService.Logout;
begin
  FApiService.ClearToken;
  FIsLoggedIn := False;
  FUserId := 0;
  FUserName := '';
  FAdSoyad := '';
  FBayiName := '';
  FRolID := 0;
  FIsKurye := False;
  FTenantID := 0;
  FTenantAdi := '';
end;

function TAuthService.IsAuthenticated: Boolean;
begin
  Result := FIsLoggedIn and FApiService.HasToken;
end;

procedure TAuthService.SetUserInfo(AUserID: Integer; const AKullaniciAdi, AAdSoyad: string;
  ARolID: Integer; AKurye: Boolean);
begin
  FIsLoggedIn := True;
  FUserId := AUserID;
  FUserName := AKullaniciAdi;
  FAdSoyad := AAdSoyad;
  FRolID := ARolID;
  FIsKurye := AKurye;
end;

procedure TAuthService.SetTenantInfo(ATenantID: Integer; const ATenantAdi: string);
begin
  FTenantID := ATenantID;
  FTenantAdi := ATenantAdi;
  FBayiName := ATenantAdi;
end;

initialization
  AuthService := TAuthService.Create(ApiService);

finalization
  AuthService.Free;

end.
