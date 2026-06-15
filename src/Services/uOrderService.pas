unit uOrderService;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  uApiService, uOrder;

type
  TOrderService = class
  private
    FApiService: TApiService;
  public
    constructor Create(AApiService: TApiService);

    function GetOrders(APage, APageSize: Integer): TOrderList;
    function GetOrderById(AId: Integer): TOrder;
    function GetOrdersByCustomer(ACustomerId: Integer): TOrderList;
    function GetOrdersByStatus(AStatus: TOrderStatus): TOrderList;
    function CreateOrder(AOrder: TOrder): TApiResponse;
    function UpdateOrderStatus(AOrderId: Integer; AStatus: TOrderStatus): TApiResponse;
    function CancelOrder(AOrderId: Integer): TApiResponse;
    function AssignCourier(AOrderId, ACourierId: Integer): TApiResponse;
    function GetRecentOrders(ACount: Integer): TOrderList;

    function ParseOrderList(AJsonArray: TJSONArray): TOrderList;
    function ParseOrder(AJsonObj: TJSONObject): TOrder;
  end;

var
  OrderService: TOrderService;

implementation

uses
  uConstants;

{ TOrderService }

constructor TOrderService.Create(AApiService: TApiService);
begin
  inherited Create;
  FApiService := AApiService;
end;

function TOrderService.GetOrders(APage, APageSize: Integer): TOrderList;
var
  LResponse: TApiResponse;
  LArr: TJSONArray;
begin
  Result := TOrderList.Create(True);
  LResponse := FApiService.Get(Format('orders?page=%d&pageSize=%d', [APage, APageSize]));
  try
    if LResponse.Success and Assigned(LResponse.Data) then
    begin
      if LResponse.Data is TJSONArray then
      begin
        Result.Free;
        Result := ParseOrderList(TJSONArray(LResponse.Data));
      end
      else if (LResponse.Data is TJSONObject) and
              TJSONObject(LResponse.Data).TryGetValue<TJSONArray>('data', LArr) then
      begin
        Result.Free;
        Result := ParseOrderList(LArr);
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

function TOrderService.GetOrderById(AId: Integer): TOrder;
var
  LResponse: TApiResponse;
begin
  Result := nil;
  LResponse := FApiService.Get(Format('orders/%d', [AId]));
  try
    if LResponse.Success and Assigned(LResponse.Data) and (LResponse.Data is TJSONObject) then
      Result := ParseOrder(TJSONObject(LResponse.Data));
  finally
    LResponse.Free;
  end;
end;

function TOrderService.GetOrdersByCustomer(ACustomerId: Integer): TOrderList;
var
  LResponse: TApiResponse;
  LArr: TJSONArray;
begin
  Result := TOrderList.Create(True);
  LResponse := FApiService.Get(Format('orders?customerId=%d', [ACustomerId]));
  try
    if LResponse.Success and Assigned(LResponse.Data) then
    begin
      if LResponse.Data is TJSONArray then
      begin
        Result.Free;
        Result := ParseOrderList(TJSONArray(LResponse.Data));
      end
      else if (LResponse.Data is TJSONObject) and
              TJSONObject(LResponse.Data).TryGetValue<TJSONArray>('data', LArr) then
      begin
        Result.Free;
        Result := ParseOrderList(LArr);
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

function TOrderService.GetOrdersByStatus(AStatus: TOrderStatus): TOrderList;
var
  LResponse: TApiResponse;
  LArr: TJSONArray;
begin
  Result := TOrderList.Create(True);
  LResponse := FApiService.Get(Format('orders?status=%d', [Ord(AStatus)]));
  try
    if LResponse.Success and Assigned(LResponse.Data) then
    begin
      if LResponse.Data is TJSONArray then
      begin
        Result.Free;
        Result := ParseOrderList(TJSONArray(LResponse.Data));
      end
      else if (LResponse.Data is TJSONObject) and
              TJSONObject(LResponse.Data).TryGetValue<TJSONArray>('data', LArr) then
      begin
        Result.Free;
        Result := ParseOrderList(LArr);
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

function TOrderService.CreateOrder(AOrder: TOrder): TApiResponse;
var
  LBody: TJSONObject;
begin
  LBody := AOrder.ToJSON;
  try
    Result := FApiService.Post('orders', LBody);
  finally
    LBody.Free;
  end;
end;

function TOrderService.UpdateOrderStatus(AOrderId: Integer; AStatus: TOrderStatus): TApiResponse;
var
  LBody: TJSONObject;
begin
  LBody := TJSONObject.Create;
  try
    LBody.AddPair('status', TJSONNumber.Create(Ord(AStatus)));
    Result := FApiService.Put(Format('orders/%d/status', [AOrderId]), LBody);
  finally
    LBody.Free;
  end;
end;

function TOrderService.CancelOrder(AOrderId: Integer): TApiResponse;
begin
  Result := UpdateOrderStatus(AOrderId, osIptal);
end;

function TOrderService.AssignCourier(AOrderId, ACourierId: Integer): TApiResponse;
var
  LBody: TJSONObject;
begin
  LBody := TJSONObject.Create;
  try
    LBody.AddPair('courierId', TJSONNumber.Create(ACourierId));
    Result := FApiService.Put(Format('orders/%d/courier', [AOrderId]), LBody);
  finally
    LBody.Free;
  end;
end;

function TOrderService.GetRecentOrders(ACount: Integer): TOrderList;
var
  LResponse: TApiResponse;
  LArr: TJSONArray;
begin
  Result := TOrderList.Create(True);
  LResponse := FApiService.Get(Format('orders/recent?count=%d', [ACount]));
  try
    if LResponse.Success and Assigned(LResponse.Data) then
    begin
      if LResponse.Data is TJSONArray then
      begin
        Result.Free;
        Result := ParseOrderList(TJSONArray(LResponse.Data));
      end
      else if (LResponse.Data is TJSONObject) and
              TJSONObject(LResponse.Data).TryGetValue<TJSONArray>('data', LArr) then
      begin
        Result.Free;
        Result := ParseOrderList(LArr);
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

function TOrderService.ParseOrderList(AJsonArray: TJSONArray): TOrderList;
var
  I: Integer;
  LOrder: TOrder;
begin
  Result := TOrderList.Create(True);
  for I := 0 to AJsonArray.Count - 1 do
  begin
    LOrder := ParseOrder(AJsonArray.Items[I] as TJSONObject);
    if Assigned(LOrder) then
      Result.Add(LOrder);
  end;
end;

function TOrderService.ParseOrder(AJsonObj: TJSONObject): TOrder;
begin
  Result := TOrder.Create;
  try
    Result.FromJSON(AJsonObj);
  except
    FreeAndNil(Result);
  end;
end;

initialization
  OrderService := TOrderService.Create(ApiService);

finalization
  OrderService.Free;

end.
