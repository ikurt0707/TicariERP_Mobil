unit TestOrder;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON,
  uOrder;

type
  [TestFixture]
  TTestOrderItem = class
  private
    FItem: TOrderItem;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateDefault;
    [Test]
    procedure TestCreateWithParams;
    [Test]
    procedure TestGetToplam;
    [Test]
    procedure TestGetToplam_ZeroMiktar;
    [Test]
    procedure TestGetFormattedToplam;
    [Test]
    procedure TestGetOzet;
    [Test]
    procedure TestToJSON;
    [Test]
    procedure TestFromJSON;
  end;

  [TestFixture]
  TTestOrder = class
  private
    FOrder: TOrder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateDefault;
    [Test]
    procedure TestAddItem;
    [Test]
    procedure TestRemoveItem;
    [Test]
    procedure TestClearItems;
    [Test]
    procedure TestGetToplamTutar_Empty;
    [Test]
    procedure TestGetToplamTutar_SingleItem;
    [Test]
    procedure TestGetToplamTutar_MultipleItems;
    [Test]
    procedure TestGetDurumText_Hazirlaniyor;
    [Test]
    procedure TestGetDurumText_Yolda;
    [Test]
    procedure TestGetDurumText_TeslimEdildi;
    [Test]
    procedure TestGetDurumText_Iptal;
    [Test]
    procedure TestGetDurumColor;
    [Test]
    procedure TestGetFormattedTarih;
    [Test]
    procedure TestGetItemsSummary_Empty;
    [Test]
    procedure TestGetItemsSummary_Single;
    [Test]
    procedure TestGetItemsSummary_Multiple;
    [Test]
    procedure TestToJSON;
    [Test]
    procedure TestFromJSON;
    [Test]
    procedure TestJSONRoundTrip;
    [Test]
    procedure TestRemoveItem_InvalidIndex;
  end;

implementation

uses
  System.DateUtils;

{ TTestOrderItem }

procedure TTestOrderItem.Setup;
begin
  FItem := TOrderItem.Create;
end;

procedure TTestOrderItem.TearDown;
begin
  FItem.Free;
end;

procedure TTestOrderItem.TestCreateDefault;
begin
  Assert.AreEqual(0, FItem.ProductId);
  Assert.AreEqual('', FItem.UrunAdi);
  Assert.AreEqual(0, FItem.Miktar);
  Assert.AreEqual(Currency(0), FItem.BirimFiyat);
end;

procedure TTestOrderItem.TestCreateWithParams;
var
  LItem: TOrderItem;
begin
  LItem := TOrderItem.Create(1, 'Damacana Su', 2, 60.00);
  try
    Assert.AreEqual(1, LItem.ProductId);
    Assert.AreEqual('Damacana Su', LItem.UrunAdi);
    Assert.AreEqual(2, LItem.Miktar);
    Assert.AreEqual(Currency(60.00), LItem.BirimFiyat);
  finally
    LItem.Free;
  end;
end;

procedure TTestOrderItem.TestGetToplam;
begin
  FItem.Miktar := 3;
  FItem.BirimFiyat := 60.00;
  Assert.AreEqual(Currency(180.00), FItem.GetToplam);
end;

procedure TTestOrderItem.TestGetToplam_ZeroMiktar;
begin
  FItem.Miktar := 0;
  FItem.BirimFiyat := 60.00;
  Assert.AreEqual(Currency(0), FItem.GetToplam);
end;

procedure TTestOrderItem.TestGetFormattedToplam;
begin
  FItem.Miktar := 2;
  FItem.BirimFiyat := 60.00;
  Assert.IsNotEmpty(FItem.GetFormattedToplam);
  Assert.Contains(FItem.GetFormattedToplam, '120');
end;

procedure TTestOrderItem.TestGetOzet;
begin
  FItem.Miktar := 2;
  FItem.UrunAdi := 'Damacana Su';
  Assert.AreEqual('2 Damacana Su', FItem.GetOzet);
end;

procedure TTestOrderItem.TestToJSON;
var
  LJSON: TJSONObject;
begin
  FItem.ProductId := 1;
  FItem.UrunAdi := 'Test';
  FItem.Miktar := 5;
  FItem.BirimFiyat := 10;

  LJSON := FItem.ToJSON;
  try
    Assert.AreEqual(1, LJSON.GetValue<Integer>('productId'));
    Assert.AreEqual('Test', LJSON.GetValue<string>('urunAdi'));
    Assert.AreEqual(5, LJSON.GetValue<Integer>('miktar'));
  finally
    LJSON.Free;
  end;
end;

procedure TTestOrderItem.TestFromJSON;
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('productId', TJSONNumber.Create(2));
    LJSON.AddPair('urunAdi', 'Su Pompasi');
    LJSON.AddPair('miktar', TJSONNumber.Create(1));
    LJSON.AddPair('birimFiyat', TJSONNumber.Create(150.00));

    FItem.FromJSON(LJSON);

    Assert.AreEqual(2, FItem.ProductId);
    Assert.AreEqual('Su Pompasi', FItem.UrunAdi);
    Assert.AreEqual(1, FItem.Miktar);
  finally
    LJSON.Free;
  end;
end;

{ TTestOrder }

procedure TTestOrder.Setup;
begin
  FOrder := TOrder.Create;
end;

procedure TTestOrder.TearDown;
begin
  FOrder.Free;
end;

procedure TTestOrder.TestCreateDefault;
begin
  Assert.AreEqual(0, FOrder.Id);
  Assert.AreEqual(0, FOrder.CustomerId);
  Assert.AreEqual('', FOrder.MusteriAdi);
  Assert.AreEqual(0, FOrder.Items.Count);
  Assert.IsTrue(FOrder.Durum = osHazirlaniyor);
end;

procedure TTestOrder.TestAddItem;
var
  LItem: TOrderItem;
begin
  LItem := TOrderItem.Create(1, 'Damacana Su', 2, 60.00);
  FOrder.AddItem(LItem);
  Assert.AreEqual(1, FOrder.Items.Count);
  Assert.AreEqual('Damacana Su', FOrder.Items[0].UrunAdi);
end;

procedure TTestOrder.TestRemoveItem;
var
  LItem1, LItem2: TOrderItem;
begin
  LItem1 := TOrderItem.Create(1, 'Damacana Su', 2, 60.00);
  LItem2 := TOrderItem.Create(2, 'Su Pompasi', 1, 150.00);
  FOrder.AddItem(LItem1);
  FOrder.AddItem(LItem2);

  FOrder.RemoveItem(0);
  Assert.AreEqual(1, FOrder.Items.Count);
  Assert.AreEqual('Su Pompasi', FOrder.Items[0].UrunAdi);
end;

procedure TTestOrder.TestClearItems;
begin
  FOrder.AddItem(TOrderItem.Create(1, 'A', 1, 10));
  FOrder.AddItem(TOrderItem.Create(2, 'B', 2, 20));
  FOrder.ClearItems;
  Assert.AreEqual(0, FOrder.Items.Count);
end;

procedure TTestOrder.TestGetToplamTutar_Empty;
begin
  Assert.AreEqual(Currency(0), FOrder.GetToplamTutar);
end;

procedure TTestOrder.TestGetToplamTutar_SingleItem;
begin
  FOrder.AddItem(TOrderItem.Create(1, 'Damacana Su', 2, 60.00));
  Assert.AreEqual(Currency(120.00), FOrder.GetToplamTutar);
end;

procedure TTestOrder.TestGetToplamTutar_MultipleItems;
begin
  FOrder.AddItem(TOrderItem.Create(1, 'Damacana Su', 2, 60.00));    // 120
  FOrder.AddItem(TOrderItem.Create(2, 'Su Pompasi', 1, 150.00));    // 150
  FOrder.AddItem(TOrderItem.Create(3, 'Bardak Su', 5, 1.00));       // 5
  Assert.AreEqual(Currency(275.00), FOrder.GetToplamTutar);
end;

procedure TTestOrder.TestGetDurumText_Hazirlaniyor;
begin
  FOrder.Durum := osHazirlaniyor;
  Assert.IsNotEmpty(FOrder.GetDurumText);
end;

procedure TTestOrder.TestGetDurumText_Yolda;
begin
  FOrder.Durum := osYolda;
  Assert.AreEqual('Yolda', FOrder.GetDurumText);
end;

procedure TTestOrder.TestGetDurumText_TeslimEdildi;
begin
  FOrder.Durum := osTeslimEdildi;
  Assert.AreEqual('Teslim Edildi', FOrder.GetDurumText);
end;

procedure TTestOrder.TestGetDurumText_Iptal;
begin
  FOrder.Durum := osIptal;
  Assert.IsNotEmpty(FOrder.GetDurumText);
end;

procedure TTestOrder.TestGetDurumColor;
begin
  FOrder.Durum := osHazirlaniyor;
  Assert.AreEqual(Cardinal($FFFF9800), FOrder.GetDurumColor);

  FOrder.Durum := osYolda;
  Assert.AreEqual(Cardinal($FF2196F3), FOrder.GetDurumColor);

  FOrder.Durum := osTeslimEdildi;
  Assert.AreEqual(Cardinal($FF4CAF50), FOrder.GetDurumColor);

  FOrder.Durum := osIptal;
  Assert.AreEqual(Cardinal($FFF44336), FOrder.GetDurumColor);
end;

procedure TTestOrder.TestGetFormattedTarih;
begin
  FOrder.OlusturmaTarihi := EncodeDate(2024, 5, 12);
  Assert.AreEqual('12.05.2024', FOrder.GetFormattedTarih);
end;

procedure TTestOrder.TestGetItemsSummary_Empty;
begin
  Assert.AreEqual('', FOrder.GetItemsSummary);
end;

procedure TTestOrder.TestGetItemsSummary_Single;
begin
  FOrder.AddItem(TOrderItem.Create(1, 'Damacana Su', 2, 60.00));
  Assert.AreEqual('2 Damacana Su', FOrder.GetItemsSummary);
end;

procedure TTestOrder.TestGetItemsSummary_Multiple;
begin
  FOrder.AddItem(TOrderItem.Create(1, 'Damacana Su', 2, 60.00));
  FOrder.AddItem(TOrderItem.Create(2, 'Pompa', 1, 150.00));
  Assert.AreEqual('2 Damacana Su + 1 Pompa', FOrder.GetItemsSummary);
end;

procedure TTestOrder.TestToJSON;
var
  LJSON: TJSONObject;
begin
  FOrder.Id := 1;
  FOrder.CustomerId := 5;
  FOrder.MusteriAdi := 'Test Musteri';
  FOrder.AddItem(TOrderItem.Create(1, 'Damacana Su', 2, 60.00));

  LJSON := FOrder.ToJSON;
  try
    Assert.AreEqual(1, LJSON.GetValue<Integer>('id'));
    Assert.AreEqual(5, LJSON.GetValue<Integer>('customerId'));
    Assert.AreEqual('Test Musteri', LJSON.GetValue<string>('musteriAdi'));
    Assert.IsTrue(LJSON.GetValue<TJSONArray>('items').Count = 1);
  finally
    LJSON.Free;
  end;
end;

procedure TTestOrder.TestFromJSON;
var
  LJSON: TJSONObject;
  LItems: TJSONArray;
  LItem: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('id', TJSONNumber.Create(10));
    LJSON.AddPair('customerId', TJSONNumber.Create(3));
    LJSON.AddPair('musteriAdi', 'From JSON');
    LJSON.AddPair('durum', TJSONNumber.Create(1)); // osYolda
    LJSON.AddPair('olusturmaTarihi', DateToISO8601(EncodeDate(2024, 5, 12)));

    LItems := TJSONArray.Create;
    LItem := TJSONObject.Create;
    LItem.AddPair('productId', TJSONNumber.Create(1));
    LItem.AddPair('urunAdi', 'Damacana Su');
    LItem.AddPair('miktar', TJSONNumber.Create(2));
    LItem.AddPair('birimFiyat', TJSONNumber.Create(60.00));
    LItems.AddElement(LItem);
    LJSON.AddPair('items', LItems);

    FOrder.FromJSON(LJSON);

    Assert.AreEqual(10, FOrder.Id);
    Assert.AreEqual(3, FOrder.CustomerId);
    Assert.AreEqual('From JSON', FOrder.MusteriAdi);
    Assert.IsTrue(FOrder.Durum = osYolda);
    Assert.AreEqual(1, FOrder.Items.Count);
  finally
    LJSON.Free;
  end;
end;

procedure TTestOrder.TestJSONRoundTrip;
var
  LJSON: TJSONObject;
  LRestored: TOrder;
begin
  FOrder.Id := 42;
  FOrder.CustomerId := 7;
  FOrder.MusteriAdi := 'Round Trip';
  FOrder.Durum := osTeslimEdildi;
  FOrder.AddItem(TOrderItem.Create(1, 'Damacana Su', 3, 60.00));
  FOrder.AddItem(TOrderItem.Create(2, 'Pompa', 1, 150.00));

  LJSON := FOrder.ToJSON;
  try
    LRestored := TOrder.Create;
    try
      LRestored.FromJSON(LJSON);
      Assert.AreEqual(FOrder.Id, LRestored.Id);
      Assert.AreEqual(FOrder.CustomerId, LRestored.CustomerId);
      Assert.AreEqual(FOrder.Items.Count, LRestored.Items.Count);
      Assert.AreEqual(FOrder.GetToplamTutar, LRestored.GetToplamTutar);
    finally
      LRestored.Free;
    end;
  finally
    LJSON.Free;
  end;
end;

procedure TTestOrder.TestRemoveItem_InvalidIndex;
begin
  FOrder.AddItem(TOrderItem.Create(1, 'Test', 1, 10));
  FOrder.RemoveItem(-1);
  FOrder.RemoveItem(5);
  Assert.AreEqual(1, FOrder.Items.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOrderItem);
  TDUnitX.RegisterTestFixture(TTestOrder);

end.
