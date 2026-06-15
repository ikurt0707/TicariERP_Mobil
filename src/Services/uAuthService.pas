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
    BayiName: string;
    ErrorMessage: string;
  end;

  TAuthService = class
  private
    FApiService: TApiService;
    FIsLoggedIn: Boolean;
    FUserId: Integer;
    FUserName: string;
    FBayiName: string;
  public
    constructor Create(AApiService: TApiService);

    function Login(const AUsername, APassword: string): TLoginResult;
    procedure Logout;
    function RefreshToken: Boolean;
    function IsAuthenticated: Boolean;

    property IsLoggedIn: Boolean read FIsLoggedIn;
    property UserId: Integer read FUserId;
    property UserName: string read FUserName;
    property BayiName: string read FBayiName;
  end;

var
  AuthService: TAuthService;

implementation

uses
  uConstants;

{ TAuthService }

constructor TAuthService.Create(AApiService: TApiService);
begin
  inherited Create;
  FApiService := AApiService;
  FIsLoggedIn := False;
  FUserId := 0;
  FUserName := '';
  FBayiName := '';
end;

function TAuthService.Login(const AUsername, APassword: string): TLoginResult;
var
  LBody: TJSONObject;
  LResponse: TApiResponse;
  LData: TJSONObject;
begin
  Result.Success := False;
  Result.Token := '';
  Result.UserId := 0;
  Result.UserName := '';
  Result.BayiName := '';
  Result.ErrorMessage := '';

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('username', AUsername);
    LBody.AddPair('password', APassword);

    LResponse := FApiService.Post('auth/login', LBody);
    try
      if LResponse.Success and Assigned(LResponse.Data) and (LResponse.Data is TJSONObject) then
      begin
        LData := TJSONObject(LResponse.Data);
        Result.Success := True;
        LData.TryGetValue<string>('token', Result.Token);
        LData.TryGetValue<Integer>('userId', Result.UserId);
        LData.TryGetValue<string>('userName', Result.UserName);
        LData.TryGetValue<string>('bayiName', Result.BayiName);

        FApiService.SetToken(Result.Token);
        FIsLoggedIn := True;
        FUserId := Result.UserId;
        FUserName := Result.UserName;
        FBayiName := Result.BayiName;
      end
      else
        Result.ErrorMessage := LResponse.ErrorMessage;
    finally
      LResponse.Free;
    end;
  finally
    LBody.Free;
  end;
end;

procedure TAuthService.Logout;
begin
  FApiService.ClearToken;
  FIsLoggedIn := False;
  FUserId := 0;
  FUserName := '';
  FBayiName := '';
end;

function TAuthService.RefreshToken: Boolean;
var
  LResponse: TApiResponse;
  LNewToken: string;
begin
  Result := False;
  LResponse := FApiService.Post('auth/refresh', TJSONObject.Create);
  try
    if LResponse.Success and Assigned(LResponse.Data) and (LResponse.Data is TJSONObject) then
    begin
      if TJSONObject(LResponse.Data).TryGetValue<string>('token', LNewToken) then
      begin
        FApiService.SetToken(LNewToken);
        Result := True;
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

function TAuthService.IsAuthenticated: Boolean;
begin
  Result := FIsLoggedIn and FApiService.HasToken;
end;

initialization
  AuthService := TAuthService.Create(ApiService);

finalization
  AuthService.Free;

end.
