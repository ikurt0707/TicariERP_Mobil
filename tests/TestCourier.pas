unit TestCourier;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON,
  uCourier;

type
  [TestFixture]
  TTestCourier = class
  private
    FCourier: TCourier;
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
    procedure TestGetTeslimOrani_WithOrders;
    [Test]
    procedure TestGetTeslimOrani_NoOrders;
    [Test]
    procedure TestGetTeslimOrani_AllDelivered;
    [Test]
    procedure TestGetFormattedTeslimOrani;
    [Test]
    procedure TestGetDurumText_Aktif;
    [Test]
    procedure TestGetDurumText_Pasif;
    [Test]
    procedure TestGetDurumText_Molada;
    [Test]
    procedure TestToJSON;
    [Test]
    procedure TestFromJSON;
    [Test]
    procedure TestJSONRoundTrip;
  end;

implementation

{ TTestCourier }

procedure TTestCourier.Setup;
begin
  FCourier := TCourier.Create;
end;

procedure TTestCourier.TearDown;
begin
  FCourier.Free;
end;

procedure TTestCourier.TestCreateDefault;
begin
  Assert.AreEqual(0, FCourier.Id);
  Assert.AreEqual('', FCourier.AdSoyad);
  Assert.AreEqual('', FCourier.Telefon);
  Assert.AreEqual(0, FCourier.ToplamSiparis);
  Assert.AreEqual(0, FCourier.TeslimEdilen);
  Assert.AreEqual(0, FCourier.Yoldaki);
  Assert.AreEqual(0, FCourier.Bekleyen);
  Assert.IsTrue(FCourier.Durum = crsAktif);
end;

procedure TTestCourier.TestCreateWithParams;
var
  LCourier: TCourier;
begin
  LCourier := TCourier.Create(1, 'Ali Yilmaz', '0533 444 55 66');
  try
    Assert.AreEqual(1, LCourier.Id);
    Assert.AreEqual('Ali Yilmaz', LCourier.AdSoyad);
    Assert.AreEqual('0533 444 55 66', LCourier.Telefon);
  finally
    LCourier.Free;
  end;
end;

procedure TTestCourier.TestGetTeslimOrani_WithOrders;
begin
  FCourier.ToplamSiparis := 5;
  FCourier.TeslimEdilen := 3;
  Assert.AreEqual(Double(60), FCourier.GetTeslimOrani);
end;

procedure TTestCourier.TestGetTeslimOrani_NoOrders;
begin
  FCourier.ToplamSiparis := 0;
  FCourier.TeslimEdilen := 0;
  Assert.AreEqual(Double(0), FCourier.GetTeslimOrani);
end;

procedure TTestCourier.TestGetTeslimOrani_AllDelivered;
begin
  FCourier.ToplamSiparis := 10;
  FCourier.TeslimEdilen := 10;
  Assert.AreEqual(Double(100), FCourier.GetTeslimOrani);
end;

procedure TTestCourier.TestGetFormattedTeslimOrani;
begin
  FCourier.ToplamSiparis := 5;
  FCourier.TeslimEdilen := 3;
  Assert.AreEqual('%60', FCourier.GetFormattedTeslimOrani);
end;

procedure TTestCourier.TestGetDurumText_Aktif;
begin
  FCourier.Durum := crsAktif;
  Assert.AreEqual('Aktif', FCourier.GetDurumText);
end;

procedure TTestCourier.TestGetDurumText_Pasif;
begin
  FCourier.Durum := crsPasif;
  Assert.AreEqual('Pasif', FCourier.GetDurumText);
end;

procedure TTestCourier.TestGetDurumText_Molada;
begin
  FCourier.Durum := crsMolada;
  Assert.AreEqual('Molada', FCourier.GetDurumText);
end;

procedure TTestCourier.TestToJSON;
var
  LJSON: TJSONObject;
begin
  FCourier.Id := 1;
  FCourier.AdSoyad := 'Test Kurye';
  FCourier.ToplamSiparis := 5;
  FCourier.TeslimEdilen := 3;
  FCourier.Latitude := 41.0082;
  FCourier.Longitude := 28.9784;

  LJSON := FCourier.ToJSON;
  try
    Assert.AreEqual(1, LJSON.GetValue<Integer>('id'));
    Assert.AreEqual('Test Kurye', LJSON.GetValue<string>('adSoyad'));
    Assert.AreEqual(5, LJSON.GetValue<Integer>('toplamSiparis'));
    Assert.AreEqual(3, LJSON.GetValue<Integer>('teslimEdilen'));
  finally
    LJSON.Free;
  end;
end;

procedure TTestCourier.TestFromJSON;
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('id', TJSONNumber.Create(2));
    LJSON.AddPair('adSoyad', 'Mehmet Aksoy');
    LJSON.AddPair('telefon', '0544 333 22 11');
    LJSON.AddPair('toplamSiparis', TJSONNumber.Create(8));
    LJSON.AddPair('teslimEdilen', TJSONNumber.Create(5));
    LJSON.AddPair('yoldaki', TJSONNumber.Create(2));
    LJSON.AddPair('bekleyen', TJSONNumber.Create(1));
    LJSON.AddPair('latitude', TJSONNumber.Create(41.0082));
    LJSON.AddPair('longitude', TJSONNumber.Create(28.9784));
    LJSON.AddPair('durum', TJSONNumber.Create(0));

    FCourier.FromJSON(LJSON);

    Assert.AreEqual(2, FCourier.Id);
    Assert.AreEqual('Mehmet Aksoy', FCourier.AdSoyad);
    Assert.AreEqual(8, FCourier.ToplamSiparis);
    Assert.AreEqual(5, FCourier.TeslimEdilen);
    Assert.AreEqual(2, FCourier.Yoldaki);
    Assert.AreEqual(1, FCourier.Bekleyen);
    Assert.IsTrue(FCourier.Durum = crsAktif);
  finally
    LJSON.Free;
  end;
end;

procedure TTestCourier.TestJSONRoundTrip;
var
  LOriginal, LRestored: TCourier;
  LJSON: TJSONObject;
begin
  LOriginal := TCourier.Create(5, 'Caner Kaya', '0555 666 77 88');
  try
    LOriginal.ToplamSiparis := 12;
    LOriginal.TeslimEdilen := 8;
    LOriginal.Yoldaki := 3;
    LOriginal.Bekleyen := 1;
    LOriginal.Latitude := 40.9;
    LOriginal.Longitude := 29.1;

    LJSON := LOriginal.ToJSON;
    try
      LRestored := TCourier.Create;
      try
        LRestored.FromJSON(LJSON);
        Assert.AreEqual(LOriginal.Id, LRestored.Id);
        Assert.AreEqual(LOriginal.AdSoyad, LRestored.AdSoyad);
        Assert.AreEqual(LOriginal.ToplamSiparis, LRestored.ToplamSiparis);
        Assert.AreEqual(LOriginal.TeslimEdilen, LRestored.TeslimEdilen);
      finally
        LRestored.Free;
      end;
    finally
      LJSON.Free;
    end;
  finally
    LOriginal.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCourier);

end.
