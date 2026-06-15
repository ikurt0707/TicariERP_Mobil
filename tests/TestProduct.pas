unit TestProduct;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON,
  uProduct;

type
  [TestFixture]
  TTestProduct = class
  private
    FProduct: TProduct;
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
    procedure TestGetFormattedFiyat;
    [Test]
    procedure TestIsStokYeterli_True;
    [Test]
    procedure TestIsStokYeterli_False;
    [Test]
    procedure TestIsStokYeterli_Exact;
    [Test]
    procedure TestJSONRoundTrip;
    [Test]
    procedure TestDefaultBirim;
    [Test]
    procedure TestDefaultAktif;
  end;

implementation

{ TTestProduct }

procedure TTestProduct.Setup;
begin
  FProduct := TProduct.Create;
end;

procedure TTestProduct.TearDown;
begin
  FProduct.Free;
end;

procedure TTestProduct.TestCreateDefault;
begin
  Assert.AreEqual(0, FProduct.Id);
  Assert.AreEqual('', FProduct.UrunAdi);
  Assert.AreEqual(Currency(0), FProduct.BirimFiyat);
  Assert.AreEqual(0, FProduct.StokMiktari);
  Assert.AreEqual('Adet', FProduct.Birim);
  Assert.IsTrue(FProduct.Aktif);
end;

procedure TTestProduct.TestCreateWithParams;
var
  LProduct: TProduct;
begin
  LProduct := TProduct.Create(1, 'Damacana Su', 60.00, 100, 'Adet');
  try
    Assert.AreEqual(1, LProduct.Id);
    Assert.AreEqual('Damacana Su', LProduct.UrunAdi);
    Assert.AreEqual(Currency(60.00), LProduct.BirimFiyat);
    Assert.AreEqual(100, LProduct.StokMiktari);
    Assert.AreEqual('Adet', LProduct.Birim);
    Assert.IsTrue(LProduct.Aktif);
  finally
    LProduct.Free;
  end;
end;

procedure TTestProduct.TestToJSON;
var
  LJSON: TJSONObject;
begin
  FProduct.Id := 2;
  FProduct.UrunAdi := 'Su Pompasi';
  FProduct.BirimFiyat := 150;
  FProduct.StokMiktari := 50;

  LJSON := FProduct.ToJSON;
  try
    Assert.AreEqual(2, LJSON.GetValue<Integer>('id'));
    Assert.AreEqual('Su Pompasi', LJSON.GetValue<string>('urunAdi'));
    Assert.IsTrue(LJSON.GetValue<Boolean>('aktif'));
  finally
    LJSON.Free;
  end;
end;

procedure TTestProduct.TestFromJSON;
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('id', TJSONNumber.Create(3));
    LJSON.AddPair('urunAdi', 'Bardak Su 200 ml');
    LJSON.AddPair('birimFiyat', TJSONNumber.Create(1.00));
    LJSON.AddPair('stokMiktari', TJSONNumber.Create(500));
    LJSON.AddPair('birim', 'Adet');
    LJSON.AddPair('aktif', TJSONBool.Create(True));

    FProduct.FromJSON(LJSON);

    Assert.AreEqual(3, FProduct.Id);
    Assert.AreEqual('Bardak Su 200 ml', FProduct.UrunAdi);
    Assert.AreEqual(Currency(1.00), FProduct.BirimFiyat);
    Assert.AreEqual(500, FProduct.StokMiktari);
    Assert.IsTrue(FProduct.Aktif);
  finally
    LJSON.Free;
  end;
end;

procedure TTestProduct.TestClone;
var
  LClone: TProduct;
begin
  FProduct.Id := 4;
  FProduct.UrunAdi := 'Soda 330 ml';
  FProduct.BirimFiyat := 2.50;
  FProduct.StokMiktari := 300;

  LClone := FProduct.Clone;
  try
    Assert.AreEqual(FProduct.Id, LClone.Id);
    Assert.AreEqual(FProduct.UrunAdi, LClone.UrunAdi);
    Assert.AreEqual(FProduct.BirimFiyat, LClone.BirimFiyat);
    Assert.AreEqual(FProduct.StokMiktari, LClone.StokMiktari);

    LClone.UrunAdi := 'Modified';
    Assert.AreNotEqual(FProduct.UrunAdi, LClone.UrunAdi);
  finally
    LClone.Free;
  end;
end;

procedure TTestProduct.TestGetFormattedFiyat;
begin
  FProduct.BirimFiyat := 60.00;
  Assert.IsNotEmpty(FProduct.GetFormattedFiyat);
  Assert.Contains(FProduct.GetFormattedFiyat, '60');
end;

procedure TTestProduct.TestIsStokYeterli_True;
begin
  FProduct.StokMiktari := 100;
  Assert.IsTrue(FProduct.IsStokYeterli(50));
end;

procedure TTestProduct.TestIsStokYeterli_False;
begin
  FProduct.StokMiktari := 10;
  Assert.IsFalse(FProduct.IsStokYeterli(20));
end;

procedure TTestProduct.TestIsStokYeterli_Exact;
begin
  FProduct.StokMiktari := 10;
  Assert.IsTrue(FProduct.IsStokYeterli(10));
end;

procedure TTestProduct.TestJSONRoundTrip;
var
  LOriginal, LRestored: TProduct;
  LJSON: TJSONObject;
begin
  LOriginal := TProduct.Create(99, 'Test Urun', 75.50, 200, 'Kutu');
  try
    LJSON := LOriginal.ToJSON;
    try
      LRestored := TProduct.Create;
      try
        LRestored.FromJSON(LJSON);
        Assert.AreEqual(LOriginal.Id, LRestored.Id);
        Assert.AreEqual(LOriginal.UrunAdi, LRestored.UrunAdi);
        Assert.AreEqual(LOriginal.BirimFiyat, LRestored.BirimFiyat);
        Assert.AreEqual(LOriginal.StokMiktari, LRestored.StokMiktari);
        Assert.AreEqual(LOriginal.Birim, LRestored.Birim);
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

procedure TTestProduct.TestDefaultBirim;
begin
  Assert.AreEqual('Adet', FProduct.Birim);
end;

procedure TTestProduct.TestDefaultAktif;
begin
  Assert.IsTrue(FProduct.Aktif);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestProduct);

end.
