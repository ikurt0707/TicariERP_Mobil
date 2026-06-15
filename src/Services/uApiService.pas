unit uApiService;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Net.HttpClient,
  System.Net.URLClient, System.Generics.Collections;

type
  TApiResponse = class
  private
    FSuccess: Boolean;
    FStatusCode: Integer;
    FData: TJSONValue;
    FErrorMessage: string;
  public
    constructor Create;
    destructor Destroy; override;

    property Success: Boolean read FSuccess write FSuccess;
    property StatusCode: Integer read FStatusCode write FStatusCode;
    property Data: TJSONValue read FData write FData;
    property ErrorMessage: string read FErrorMessage write FErrorMessage;
  end;

  TApiService = class
  private
    FBaseUrl: string;
    FToken: string;
    FTimeout: Integer;
    FHttpClient: THTTPClient;

    function BuildUrl(const AEndpoint: string): string;
    function GetHeaders: TArray<TNameValuePair>;
    function ParseResponse(AResponse: IHTTPResponse): TApiResponse;
  public
    constructor Create(const ABaseUrl: string);
    destructor Destroy; override;

    function Get(const AEndpoint: string): TApiResponse;
    function Post(const AEndpoint: string; ABody: TJSONObject): TApiResponse;
    function Put(const AEndpoint: string; ABody: TJSONObject): TApiResponse;
    function Delete(const AEndpoint: string): TApiResponse;

    procedure SetToken(const AToken: string);
    procedure ClearToken;
    function HasToken: Boolean;

    property BaseUrl: string read FBaseUrl write FBaseUrl;
    property Token: string read FToken;
    property Timeout: Integer read FTimeout write FTimeout;
  end;

var
  ApiService: TApiService;

implementation

uses
  uConstants;

{ TApiResponse }

constructor TApiResponse.Create;
begin
  inherited Create;
  FSuccess := False;
  FStatusCode := 0;
  FData := nil;
  FErrorMessage := '';
end;

destructor TApiResponse.Destroy;
begin
  if Assigned(FData) then
    FData.Free;
  inherited;
end;

{ TApiService }

constructor TApiService.Create(const ABaseUrl: string);
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
  FToken := '';
  FTimeout := API_TIMEOUT;
  FHttpClient := THTTPClient.Create;
  FHttpClient.ConnectionTimeout := FTimeout;
  FHttpClient.ResponseTimeout := FTimeout;
end;

destructor TApiService.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

function TApiService.BuildUrl(const AEndpoint: string): string;
begin
  Result := FBaseUrl;
  if not Result.EndsWith('/') then
    Result := Result + '/';
  if AEndpoint.StartsWith('/') then
    Result := Result + Copy(AEndpoint, 2, Length(AEndpoint) - 1)
  else
    Result := Result + AEndpoint;
end;

function TApiService.GetHeaders: TArray<TNameValuePair>;
begin
  SetLength(Result, 2);
  Result[0] := TNameValuePair.Create('Content-Type', 'application/json');
  if FToken <> '' then
    Result[1] := TNameValuePair.Create('Authorization', 'Bearer ' + FToken)
  else
    Result[1] := TNameValuePair.Create('Accept', 'application/json');
end;

function TApiService.ParseResponse(AResponse: IHTTPResponse): TApiResponse;
var
  LJson: TJSONValue;
  LObj: TJSONObject;
  LArr: TJSONArray;
begin
  Result := TApiResponse.Create;
  Result.StatusCode := AResponse.StatusCode;
  Result.Success := (AResponse.StatusCode >= 200) and (AResponse.StatusCode < 300);

  if AResponse.ContentAsString <> '' then
  begin
    try
      LJson := TJSONObject.ParseJSONValue(AResponse.ContentAsString);
      if Assigned(LJson) then
      begin
        // DataSnap wraps results as {"result": [<actual_data>]}
        if (LJson is TJSONObject) then
        begin
          LObj := TJSONObject(LJson);
          if LObj.TryGetValue<TJSONArray>('result', LArr) and (LArr.Count > 0) then
          begin
            Result.Data := LArr.Items[0].Clone as TJSONValue;
            LJson.Free;
          end
          else
            Result.Data := LJson;
        end
        else
          Result.Data := LJson;
      end;
    except
      on E: Exception do
        Result.ErrorMessage := E.Message;
    end;
  end;

  if not Result.Success then
  begin
    if (Result.Data is TJSONObject) then
    begin
      if TJSONObject(Result.Data).TryGetValue<string>('message', Result.FErrorMessage) then
        // message found
      else if TJSONObject(Result.Data).TryGetValue<string>('error', Result.FErrorMessage) then
        // error found
      else
        Result.ErrorMessage := Format('HTTP Error %d', [AResponse.StatusCode]);
    end
    else
      Result.ErrorMessage := Format('HTTP Error %d', [AResponse.StatusCode]);
  end;
end;

function TApiService.Get(const AEndpoint: string): TApiResponse;
var
  LResponse: IHTTPResponse;
  LHeaders: TArray<TNameValuePair>;
begin
  try
    LHeaders := GetHeaders;
    LResponse := FHttpClient.Get(BuildUrl(AEndpoint), nil, LHeaders);
    Result := ParseResponse(LResponse);
  except
    on E: Exception do
    begin
      Result := TApiResponse.Create;
      Result.Success := False;
      Result.ErrorMessage := 'Ba' + Chr($011F) + 'lant' + Chr($0131) + ' hatas' + Chr($0131) + ': ' + E.Message;
    end;
  end;
end;

function TApiService.Post(const AEndpoint: string; ABody: TJSONObject): TApiResponse;
var
  LResponse: IHTTPResponse;
  LStream: TStringStream;
  LHeaders: TArray<TNameValuePair>;
begin
  try
    LHeaders := GetHeaders;
    LStream := TStringStream.Create(ABody.ToJSON, TEncoding.UTF8);
    try
      LResponse := FHttpClient.Post(BuildUrl(AEndpoint), LStream, nil, LHeaders);
      Result := ParseResponse(LResponse);
    finally
      LStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result := TApiResponse.Create;
      Result.Success := False;
      Result.ErrorMessage := 'Ba' + Chr($011F) + 'lant' + Chr($0131) + ' hatas' + Chr($0131) + ': ' + E.Message;
    end;
  end;
end;

function TApiService.Put(const AEndpoint: string; ABody: TJSONObject): TApiResponse;
var
  LResponse: IHTTPResponse;
  LStream: TStringStream;
  LHeaders: TArray<TNameValuePair>;
begin
  try
    LHeaders := GetHeaders;
    LStream := TStringStream.Create(ABody.ToJSON, TEncoding.UTF8);
    try
      LResponse := FHttpClient.Put(BuildUrl(AEndpoint), LStream, nil, LHeaders);
      Result := ParseResponse(LResponse);
    finally
      LStream.Free;
    end;
  except
    on E: Exception do
    begin
      Result := TApiResponse.Create;
      Result.Success := False;
      Result.ErrorMessage := 'Ba' + Chr($011F) + 'lant' + Chr($0131) + ' hatas' + Chr($0131) + ': ' + E.Message;
    end;
  end;
end;

function TApiService.Delete(const AEndpoint: string): TApiResponse;
var
  LResponse: IHTTPResponse;
  LHeaders: TArray<TNameValuePair>;
begin
  try
    LHeaders := GetHeaders;
    LResponse := FHttpClient.Delete(BuildUrl(AEndpoint), nil, LHeaders);
    Result := ParseResponse(LResponse);
  except
    on E: Exception do
    begin
      Result := TApiResponse.Create;
      Result.Success := False;
      Result.ErrorMessage := 'Ba' + Chr($011F) + 'lant' + Chr($0131) + ' hatas' + Chr($0131) + ': ' + E.Message;
    end;
  end;
end;

procedure TApiService.SetToken(const AToken: string);
begin
  FToken := AToken;
end;

procedure TApiService.ClearToken;
begin
  FToken := '';
end;

function TApiService.HasToken: Boolean;
begin
  Result := FToken <> '';
end;

initialization
  ApiService := TApiService.Create(API_BASE_URL);

finalization
  ApiService.Free;

end.
