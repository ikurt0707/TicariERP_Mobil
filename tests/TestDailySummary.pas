unit TestDailySummary;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON,
  uDailySummary;

type
  [TestFixture]
  TTestDailySummary = class
  private
    FSummary: TDailySummary;
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
    procedure TestGetFormattedCiro;
    [Test]
    procedure TestGetFormattedTahsilat;
    [Test]
    procedure TestGetFormattedBorc;
    [Test]
    procedure TestGetFormattedTarih;
    [Test]
    procedure TestGetTahsilatOrani_Normal;
    [Test]
    procedure TestGetTahsilatOrani_ZeroCiro;
    [Test]
    procedure TestGetTahsilatOrani_FullCollection;
    [Test]
    procedure TestToJSON;
    [Test]
    procedure TestFromJSON;
    [Test]
    procedure TestJSONRoundTrip;
  end;

implementation

uses
  System.DateUtils;

{ TTestDailySummary }

procedure TTestDailySummary.Setup;
begin
  FSummary := TDailySummary.Create;
end;

procedure TTestDailySummary.TearDown;
begin
  FSummary.Free;
end;

procedure TTestDailySummary.TestCreateDefault;
begin
  Assert.AreEqual(0, FSummary.SiparisAdedi);
  Assert.AreEqual(Currency(0), FSummary.Ciro);
  Assert.AreEqual(Currency(0), FSummary.Tahsilat);
  Assert.AreEqual(Currency(0), FSummary.Borc);
  Assert.AreEqual(0, FSummary.TeslimEdilen);
  Assert.AreEqual(0, FSummary.IptalEdilen);
  Assert.AreEqual(0, FSummary.YeniMusteri);
end;

procedure TTestDailySummary.TestCreateWithParams;
var
  LSummary: TDailySummary;
begin
  LSummary := TDailySummary.Create(EncodeDate(2024, 5, 12), 18, 6250, 4100, 3850);
  try
    Assert.AreEqual(18, LSummary.SiparisAdedi);
    Assert.AreEqual(Currency(6250), LSummary.Ciro);
    Assert.AreEqual(Currency(4100), LSummary.Tahsilat);
    Assert.AreEqual(Currency(3850), LSummary.Borc);
  finally
    LSummary.Free;
  end;
end;

procedure TTestDailySummary.TestGetFormattedCiro;
begin
  FSummary.Ciro := 6250;
  Assert.IsNotEmpty(FSummary.GetFormattedCiro);
  Assert.Contains(FSummary.GetFormattedCiro, '6');
end;

procedure TTestDailySummary.TestGetFormattedTahsilat;
begin
  FSummary.Tahsilat := 4100;
  Assert.IsNotEmpty(FSummary.GetFormattedTahsilat);
end;

procedure TTestDailySummary.TestGetFormattedBorc;
begin
  FSummary.Borc := 3850;
  Assert.IsNotEmpty(FSummary.GetFormattedBorc);
end;

procedure TTestDailySummary.TestGetFormattedTarih;
begin
  FSummary.Tarih := EncodeDate(2024, 5, 12);
  Assert.AreEqual('12.05.2024', FSummary.GetFormattedTarih);
end;

procedure TTestDailySummary.TestGetTahsilatOrani_Normal;
begin
  FSummary.Ciro := 6250;
  FSummary.Tahsilat := 4100;
  // 4100/6250 * 100 = 65.6
  Assert.IsTrue(Abs(FSummary.GetTahsilatOrani - 65.6) < 0.1);
end;

procedure TTestDailySummary.TestGetTahsilatOrani_ZeroCiro;
begin
  FSummary.Ciro := 0;
  FSummary.Tahsilat := 0;
  Assert.AreEqual(Double(0), FSummary.GetTahsilatOrani);
end;

procedure TTestDailySummary.TestGetTahsilatOrani_FullCollection;
begin
  FSummary.Ciro := 5000;
  FSummary.Tahsilat := 5000;
  Assert.AreEqual(Double(100), FSummary.GetTahsilatOrani);
end;

procedure TTestDailySummary.TestToJSON;
var
  LJSON: TJSONObject;
begin
  FSummary.SiparisAdedi := 18;
  FSummary.Ciro := 6250;
  FSummary.TeslimEdilen := 15;

  LJSON := FSummary.ToJSON;
  try
    Assert.AreEqual(18, LJSON.GetValue<Integer>('siparisAdedi'));
    Assert.AreEqual(15, LJSON.GetValue<Integer>('teslimEdilen'));
  finally
    LJSON.Free;
  end;
end;

procedure TTestDailySummary.TestFromJSON;
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('tarih', DateToISO8601(EncodeDate(2024, 5, 12)));
    LJSON.AddPair('siparisAdedi', TJSONNumber.Create(18));
    LJSON.AddPair('ciro', TJSONNumber.Create(6250));
    LJSON.AddPair('tahsilat', TJSONNumber.Create(4100));
    LJSON.AddPair('borc', TJSONNumber.Create(3850));
    LJSON.AddPair('teslimEdilen', TJSONNumber.Create(15));
    LJSON.AddPair('iptalEdilen', TJSONNumber.Create(2));
    LJSON.AddPair('yeniMusteri', TJSONNumber.Create(3));

    FSummary.FromJSON(LJSON);

    Assert.AreEqual(18, FSummary.SiparisAdedi);
    Assert.AreEqual(Currency(6250), FSummary.Ciro);
    Assert.AreEqual(Currency(4100), FSummary.Tahsilat);
    Assert.AreEqual(15, FSummary.TeslimEdilen);
    Assert.AreEqual(2, FSummary.IptalEdilen);
    Assert.AreEqual(3, FSummary.YeniMusteri);
  finally
    LJSON.Free;
  end;
end;

procedure TTestDailySummary.TestJSONRoundTrip;
var
  LOriginal, LRestored: TDailySummary;
  LJSON: TJSONObject;
begin
  LOriginal := TDailySummary.Create(EncodeDate(2024, 5, 12), 18, 6250, 4100, 3850);
  try
    LOriginal.TeslimEdilen := 15;
    LOriginal.IptalEdilen := 2;
    LOriginal.YeniMusteri := 3;

    LJSON := LOriginal.ToJSON;
    try
      LRestored := TDailySummary.Create;
      try
        LRestored.FromJSON(LJSON);
        Assert.AreEqual(LOriginal.SiparisAdedi, LRestored.SiparisAdedi);
        Assert.AreEqual(LOriginal.Ciro, LRestored.Ciro);
        Assert.AreEqual(LOriginal.Tahsilat, LRestored.Tahsilat);
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
  TDUnitX.RegisterTestFixture(TTestDailySummary);

end.
