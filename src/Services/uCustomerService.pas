unit uCustomerService;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  uApiService, uCustomer;

type
  TCustomerService = class
  private
    FApiService: TApiService;
  public
    constructor Create(AApiService: TApiService);

    function GetCustomers(APage, APageSize: Integer): TCustomerList;
    function GetCustomerById(AId: Integer): TCustomer;
    function GetCustomerByPhone(const APhone: string): TCustomer;
    function SearchCustomers(const AQuery: string): TCustomerList;
    function CreateCustomer(ACustomer: TCustomer): TApiResponse;
    function UpdateCustomer(ACustomer: TCustomer): TApiResponse;
    function GetDebtors: TCustomerList;

    function ParseCustomerList(AJsonArray: TJSONArray): TCustomerList;
    function ParseCustomer(AJsonObj: TJSONObject): TCustomer;
  end;

var
  CustomerService: TCustomerService;

implementation

uses
  uConstants;

{ TCustomerService }

constructor TCustomerService.Create(AApiService: TApiService);
begin
  inherited Create;
  FApiService := AApiService;
end;

function TCustomerService.GetCustomers(APage, APageSize: Integer): TCustomerList;
var
  LResponse: TApiResponse;
  LArr: TJSONArray;
begin
  Result := TCustomerList.Create(True);
  LResponse := FApiService.Get(Format('customers?page=%d&pageSize=%d', [APage, APageSize]));
  try
    if LResponse.Success and Assigned(LResponse.Data) then
    begin
      if LResponse.Data is TJSONArray then
      begin
        Result.Free;
        Result := ParseCustomerList(TJSONArray(LResponse.Data));
      end
      else if (LResponse.Data is TJSONObject) and
              TJSONObject(LResponse.Data).TryGetValue<TJSONArray>('data', LArr) then
      begin
        Result.Free;
        Result := ParseCustomerList(LArr);
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

function TCustomerService.GetCustomerById(AId: Integer): TCustomer;
var
  LResponse: TApiResponse;
begin
  Result := nil;
  LResponse := FApiService.Get(Format('customers/%d', [AId]));
  try
    if LResponse.Success and Assigned(LResponse.Data) and (LResponse.Data is TJSONObject) then
      Result := ParseCustomer(TJSONObject(LResponse.Data));
  finally
    LResponse.Free;
  end;
end;

function TCustomerService.GetCustomerByPhone(const APhone: string): TCustomer;
var
  LResponse: TApiResponse;
begin
  Result := nil;
  LResponse := FApiService.Get(Format('customers/phone/%s', [APhone]));
  try
    if LResponse.Success and Assigned(LResponse.Data) and (LResponse.Data is TJSONObject) then
      Result := ParseCustomer(TJSONObject(LResponse.Data));
  finally
    LResponse.Free;
  end;
end;

function TCustomerService.SearchCustomers(const AQuery: string): TCustomerList;
var
  LResponse: TApiResponse;
  LArr: TJSONArray;
begin
  Result := TCustomerList.Create(True);
  LResponse := FApiService.Get(Format('customers/search?q=%s', [AQuery]));
  try
    if LResponse.Success and Assigned(LResponse.Data) then
    begin
      if LResponse.Data is TJSONArray then
      begin
        Result.Free;
        Result := ParseCustomerList(TJSONArray(LResponse.Data));
      end
      else if (LResponse.Data is TJSONObject) and
              TJSONObject(LResponse.Data).TryGetValue<TJSONArray>('data', LArr) then
      begin
        Result.Free;
        Result := ParseCustomerList(LArr);
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

function TCustomerService.CreateCustomer(ACustomer: TCustomer): TApiResponse;
var
  LBody: TJSONObject;
begin
  LBody := ACustomer.ToJSON;
  try
    Result := FApiService.Post('customers', LBody);
  finally
    LBody.Free;
  end;
end;

function TCustomerService.UpdateCustomer(ACustomer: TCustomer): TApiResponse;
var
  LBody: TJSONObject;
begin
  LBody := ACustomer.ToJSON;
  try
    Result := FApiService.Put(Format('customers/%d', [ACustomer.Id]), LBody);
  finally
    LBody.Free;
  end;
end;

function TCustomerService.GetDebtors: TCustomerList;
var
  LResponse: TApiResponse;
  LArr: TJSONArray;
begin
  Result := TCustomerList.Create(True);
  LResponse := FApiService.Get('customers/debtors');
  try
    if LResponse.Success and Assigned(LResponse.Data) then
    begin
      if LResponse.Data is TJSONArray then
      begin
        Result.Free;
        Result := ParseCustomerList(TJSONArray(LResponse.Data));
      end
      else if (LResponse.Data is TJSONObject) and
              TJSONObject(LResponse.Data).TryGetValue<TJSONArray>('data', LArr) then
      begin
        Result.Free;
        Result := ParseCustomerList(LArr);
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

function TCustomerService.ParseCustomerList(AJsonArray: TJSONArray): TCustomerList;
var
  I: Integer;
  LCustomer: TCustomer;
begin
  Result := TCustomerList.Create(True);
  for I := 0 to AJsonArray.Count - 1 do
  begin
    LCustomer := ParseCustomer(AJsonArray.Items[I] as TJSONObject);
    if Assigned(LCustomer) then
      Result.Add(LCustomer);
  end;
end;

function TCustomerService.ParseCustomer(AJsonObj: TJSONObject): TCustomer;
begin
  Result := TCustomer.Create;
  try
    Result.FromJSON(AJsonObj);
  except
    FreeAndNil(Result);
  end;
end;

initialization
  CustomerService := TCustomerService.Create(ApiService);

finalization
  CustomerService.Free;

end.
