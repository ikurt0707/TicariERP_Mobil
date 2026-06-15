unit TestOrderService;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON,
  System.Generics.Collections,
  uOrder, uOrderService, uApiService;

type
  [TestFixture]
  TTestOrderServiceParsing = class
  private
    FService: TOrderService;
    FApiService: TApiService;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestParseOrder_ValidJSON;
    [Test]
    procedure TestParseOrder_MinimalJSON;
    [Test]
    procedure TestParseOrder_WithItems;
    [Test]
    procedure TestParseOrderList_Empty;
    [Test]
    procedure TestParseOrderList_SingleItem;
    [Test]
    procedure TestParseOrderList_MultipleItems;
    [Test]
    procedure TestParseOrder_InvalidJSON;
  end;

implementation

{ TTestOrderServiceParsing }

procedure TTestOrderServiceParsing.Setup;
begin
  FApiService := TApiService.Create('http://localhost:8080/api');
  FService := TOrderService.Create(FApiService);
end;

procedure TTestOrderServiceParsing.TearDown;
begin
  FService.Free;
  FApiService.Free;
end;

procedure TTestOrderServiceParsing.TestParseOrder_ValidJSON;
var
  LJSON: TJSONObject;
  LOrder: TOrder;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('id', TJSONNumber.Create(1));
    LJSON.AddPair('customerId', TJSONNumber.Create(5));
    LJSON.AddPair('musteriAdi', 'Ahmet Yilmaz');
    LJSON.AddPair('musteriTelefon', '0532 123 45 67');
    LJSON.AddPair('musteriAdres', 'Soguksu Mah. 123. Sk. No:5');
    LJSON.AddPair('durum', TJSONNumber.Create(2)); // osTeslimEdildi
    LJSON.AddPair('items', TJSONArray.Create);

    LOrder := FService.ParseOrder(LJSON);
    try
      Assert.IsNotNull(LOrder);
      Assert.AreEqual(1, LOrder.Id);
      Assert.AreEqual(5, LOrder.CustomerId);
      Assert.AreEqual('Ahmet Yilmaz', LOrder.MusteriAdi);
      Assert.IsTrue(LOrder.Durum = osTeslimEdildi);
    finally
      LOrder.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

procedure TTestOrderServiceParsing.TestParseOrder_MinimalJSON;
var
  LJSON: TJSONObject;
  LOrder: TOrder;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('id', TJSONNumber.Create(1));

    LOrder := FService.ParseOrder(LJSON);
    try
      Assert.IsNotNull(LOrder);
      Assert.AreEqual(1, LOrder.Id);
    finally
      LOrder.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

procedure TTestOrderServiceParsing.TestParseOrder_WithItems;
var
  LJSON: TJSONObject;
  LItems: TJSONArray;
  LItem: TJSONObject;
  LOrder: TOrder;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('id', TJSONNumber.Create(1));
    LJSON.AddPair('customerId', TJSONNumber.Create(5));
    LJSON.AddPair('musteriAdi', 'Test');

    LItems := TJSONArray.Create;
    LItem := TJSONObject.Create;
    LItem.AddPair('productId', TJSONNumber.Create(1));
    LItem.AddPair('urunAdi', 'Damacana Su');
    LItem.AddPair('miktar', TJSONNumber.Create(2));
    LItem.AddPair('birimFiyat', TJSONNumber.Create(60.00));
    LItems.AddElement(LItem);

    LItem := TJSONObject.Create;
    LItem.AddPair('productId', TJSONNumber.Create(2));
    LItem.AddPair('urunAdi', 'Su Pompasi');
    LItem.AddPair('miktar', TJSONNumber.Create(1));
    LItem.AddPair('birimFiyat', TJSONNumber.Create(150.00));
    LItems.AddElement(LItem);

    LJSON.AddPair('items', LItems);

    LOrder := FService.ParseOrder(LJSON);
    try
      Assert.IsNotNull(LOrder);
      Assert.AreEqual(2, LOrder.Items.Count);
      Assert.AreEqual('Damacana Su', LOrder.Items[0].UrunAdi);
      Assert.AreEqual('Su Pompasi', LOrder.Items[1].UrunAdi);
      Assert.AreEqual(Currency(270.00), LOrder.GetToplamTutar); // 120 + 150
    finally
      LOrder.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

procedure TTestOrderServiceParsing.TestParseOrderList_Empty;
var
  LArr: TJSONArray;
  LList: TOrderList;
begin
  LArr := TJSONArray.Create;
  try
    LList := FService.ParseOrderList(LArr);
    try
      Assert.AreEqual(0, LList.Count);
    finally
      LList.Free;
    end;
  finally
    LArr.Free;
  end;
end;

procedure TTestOrderServiceParsing.TestParseOrderList_SingleItem;
var
  LArr: TJSONArray;
  LObj: TJSONObject;
  LList: TOrderList;
begin
  LArr := TJSONArray.Create;
  try
    LObj := TJSONObject.Create;
    LObj.AddPair('id', TJSONNumber.Create(1));
    LObj.AddPair('musteriAdi', 'Test');
    LArr.AddElement(LObj);

    LList := FService.ParseOrderList(LArr);
    try
      Assert.AreEqual(1, LList.Count);
      Assert.AreEqual(1, LList[0].Id);
    finally
      LList.Free;
    end;
  finally
    LArr.Free;
  end;
end;

procedure TTestOrderServiceParsing.TestParseOrderList_MultipleItems;
var
  LArr: TJSONArray;
  LObj: TJSONObject;
  LList: TOrderList;
  I: Integer;
begin
  LArr := TJSONArray.Create;
  try
    for I := 1 to 5 do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('id', TJSONNumber.Create(I));
      LObj.AddPair('musteriAdi', Format('Musteri %d', [I]));
      LArr.AddElement(LObj);
    end;

    LList := FService.ParseOrderList(LArr);
    try
      Assert.AreEqual(5, LList.Count);
      for I := 0 to 4 do
        Assert.AreEqual(I + 1, LList[I].Id);
    finally
      LList.Free;
    end;
  finally
    LArr.Free;
  end;
end;

procedure TTestOrderServiceParsing.TestParseOrder_InvalidJSON;
var
  LJSON: TJSONObject;
  LOrder: TOrder;
begin
  LJSON := TJSONObject.Create;
  try
    // Empty JSON - should still create order with defaults
    LOrder := FService.ParseOrder(LJSON);
    try
      Assert.IsNotNull(LOrder);
      Assert.AreEqual(0, LOrder.Id);
    finally
      LOrder.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOrderServiceParsing);

end.
