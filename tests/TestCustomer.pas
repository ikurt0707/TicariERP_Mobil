unit TestCustomer;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON,
  uCustomer;

type
  [TestFixture]
  TTestCustomer = class
  private
    FCustomer: TCustomer;
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
    procedure TestToJSON;
    [Test]
    procedure TestFromJSON;
    [Test]
    procedure TestClone;
    [Test]
    procedure TestGetInitials_TwoWords;
    [Test]
    procedure TestGetInitials_SingleWord;
    [Test]
    procedure TestGetInitials_ThreeWords;
    [Test]
    procedure TestGetFormattedBakiye;
    [Test]
    procedure TestGetFormattedToplamHarcama;
    [Test]
    procedure TestIsKayitli_True;
    [Test]
    procedure TestIsKayitli_False;
    [Test]
    procedure TestGetDurumText_Kayitli;
    [Test]
    procedure TestGetDurumText_Kayitsiz;
    [Test]
    procedure TestJSONRoundTrip;
  end;

implementation

{ TTestCustomer }

procedure TTestCustomer.Setup;
begin
  FCustomer := TCustomer.Create;
end;

procedure TTestCustomer.TearDown;
begin
  FCustomer.Free;
end;

procedure TTestCustomer.TestCreateDefault;
begin
  Assert.AreEqual(0, FCustomer.Id);
  Assert.AreEqual('', FCustomer.AdSoyad);
  Assert.AreEqual('', FCustomer.Telefon);
  Assert.AreEqual('', FCustomer.Adres);
  Assert.AreEqual(Currency(0), FCustomer.Bakiye);
  Assert.AreEqual(0, FCustomer.ToplamSiparis);
  Assert.AreEqual(Currency(0), FCustomer.ToplamHarcama);
  Assert.IsTrue(FCustomer.Durum = csKayitsiz);
end;

procedure TTestCustomer.TestCreateWithParams;
var
  LCustomer: TCustomer;
begin
  LCustomer := TCustomer.Create(1, 'Ahmet Yilmaz', '0532 123 45 67', 'Soguksu Mah.');
  try
    Assert.AreEqual(1, LCustomer.Id);
    Assert.AreEqual('Ahmet Yilmaz', LCustomer.AdSoyad);
    Assert.AreEqual('0532 123 45 67', LCustomer.Telefon);
    Assert.AreEqual('Soguksu Mah.', LCustomer.Adres);
    Assert.IsTrue(LCustomer.Durum = csKayitli);
  finally
    LCustomer.Free;
  end;
end;

procedure TTestCustomer.TestToJSON;
var
  LJSON: TJSONObject;
begin
  FCustomer.Id := 5;
  FCustomer.AdSoyad := 'Test Musteri';
  FCustomer.Telefon := '0555 111 22 33';
  FCustomer.Bakiye := 250.50;

  LJSON := FCustomer.ToJSON;
  try
    Assert.AreEqual(5, LJSON.GetValue<Integer>('id'));
    Assert.AreEqual('Test Musteri', LJSON.GetValue<string>('adSoyad'));
    Assert.AreEqual('0555 111 22 33', LJSON.GetValue<string>('telefon'));
  finally
    LJSON.Free;
  end;
end;

procedure TTestCustomer.TestFromJSON;
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('id', TJSONNumber.Create(10));
    LJSON.AddPair('adSoyad', 'Mehmet Demir');
    LJSON.AddPair('telefon', '0544 222 33 44');
    LJSON.AddPair('adres', 'Ataturk Cad. No:78');
    LJSON.AddPair('bakiye', TJSONNumber.Create(500.75));
    LJSON.AddPair('toplamSiparis', TJSONNumber.Create(28));
    LJSON.AddPair('toplamHarcama', TJSONNumber.Create(2850.00));
    LJSON.AddPair('durum', TJSONNumber.Create(0)); // csKayitli

    FCustomer.FromJSON(LJSON);

    Assert.AreEqual(10, FCustomer.Id);
    Assert.AreEqual('Mehmet Demir', FCustomer.AdSoyad);
    Assert.AreEqual('0544 222 33 44', FCustomer.Telefon);
    Assert.AreEqual('Ataturk Cad. No:78', FCustomer.Adres);
    Assert.AreEqual(28, FCustomer.ToplamSiparis);
    Assert.IsTrue(FCustomer.Durum = csKayitli);
  finally
    LJSON.Free;
  end;
end;

procedure TTestCustomer.TestClone;
var
  LClone: TCustomer;
begin
  FCustomer.Id := 3;
  FCustomer.AdSoyad := 'Clone Test';
  FCustomer.Telefon := '0532 999 88 77';
  FCustomer.Bakiye := 100;
  FCustomer.ToplamSiparis := 5;

  LClone := FCustomer.Clone;
  try
    Assert.AreEqual(FCustomer.Id, LClone.Id);
    Assert.AreEqual(FCustomer.AdSoyad, LClone.AdSoyad);
    Assert.AreEqual(FCustomer.Telefon, LClone.Telefon);
    Assert.AreEqual(FCustomer.Bakiye, LClone.Bakiye);
    Assert.AreEqual(FCustomer.ToplamSiparis, LClone.ToplamSiparis);

    // Verify independence
    LClone.AdSoyad := 'Modified';
    Assert.AreNotEqual(FCustomer.AdSoyad, LClone.AdSoyad);
  finally
    LClone.Free;
  end;
end;

procedure TTestCustomer.TestGetInitials_TwoWords;
begin
  FCustomer.AdSoyad := 'Ahmet Yilmaz';
  Assert.AreEqual('AY', FCustomer.GetInitials);
end;

procedure TTestCustomer.TestGetInitials_SingleWord;
begin
  FCustomer.AdSoyad := 'Ahmet';
  Assert.AreEqual('A', FCustomer.GetInitials);
end;

procedure TTestCustomer.TestGetInitials_ThreeWords;
begin
  FCustomer.AdSoyad := 'Ahmet Can Yilmaz';
  Assert.AreEqual('AY', FCustomer.GetInitials);
end;

procedure TTestCustomer.TestGetFormattedBakiye;
begin
  FCustomer.Bakiye := 250;
  Assert.IsNotEmpty(FCustomer.GetFormattedBakiye);
  Assert.Contains(FCustomer.GetFormattedBakiye, '250');
end;

procedure TTestCustomer.TestGetFormattedToplamHarcama;
begin
  FCustomer.ToplamHarcama := 2850;
  Assert.IsNotEmpty(FCustomer.GetFormattedToplamHarcama);
end;

procedure TTestCustomer.TestIsKayitli_True;
begin
  FCustomer.Durum := csKayitli;
  Assert.IsTrue(FCustomer.IsKayitli);
end;

procedure TTestCustomer.TestIsKayitli_False;
begin
  FCustomer.Durum := csKayitsiz;
  Assert.IsFalse(FCustomer.IsKayitli);
end;

procedure TTestCustomer.TestGetDurumText_Kayitli;
begin
  FCustomer.Durum := csKayitli;
  Assert.IsNotEmpty(FCustomer.GetDurumText);
end;

procedure TTestCustomer.TestGetDurumText_Kayitsiz;
begin
  FCustomer.Durum := csKayitsiz;
  Assert.IsNotEmpty(FCustomer.GetDurumText);
end;

procedure TTestCustomer.TestJSONRoundTrip;
var
  LOriginal, LRestored: TCustomer;
  LJSON: TJSONObject;
begin
  LOriginal := TCustomer.Create(42, 'Round Trip', '0532 111 22 33', 'Test Adres');
  try
    LOriginal.Bakiye := 1500;
    LOriginal.ToplamSiparis := 15;
    LOriginal.ToplamHarcama := 5000;
    LOriginal.Latitude := 41.0082;
    LOriginal.Longitude := 28.9784;

    LJSON := LOriginal.ToJSON;
    try
      LRestored := TCustomer.Create;
      try
        LRestored.FromJSON(LJSON);
        Assert.AreEqual(LOriginal.Id, LRestored.Id);
        Assert.AreEqual(LOriginal.AdSoyad, LRestored.AdSoyad);
        Assert.AreEqual(LOriginal.Telefon, LRestored.Telefon);
        Assert.AreEqual(LOriginal.ToplamSiparis, LRestored.ToplamSiparis);
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
  TDUnitX.RegisterTestFixture(TTestCustomer);

end.
