unit TestHelpers;

interface

uses
  DUnitX.TestFramework, System.SysUtils,
  uHelpers;

type
  [TestFixture]
  TTestHelpers = class
  public
    [Test]
    procedure TestFormatCurrency_Normal;
    [Test]
    procedure TestFormatCurrency_Zero;
    [Test]
    procedure TestFormatCurrency_Large;

    [Test]
    procedure TestFormatPhone_10Digits;
    [Test]
    procedure TestFormatPhone_11Digits;
    [Test]
    procedure TestFormatPhone_Invalid;

    [Test]
    procedure TestCleanPhone_WithSpaces;
    [Test]
    procedure TestCleanPhone_WithDashes;
    [Test]
    procedure TestCleanPhone_WithParens;
    [Test]
    procedure TestCleanPhone_AlreadyClean;

    [Test]
    procedure TestIsValidPhone_Valid10;
    [Test]
    procedure TestIsValidPhone_Valid11;
    [Test]
    procedure TestIsValidPhone_TooShort;
    [Test]
    procedure TestIsValidPhone_TooLong;
    [Test]
    procedure TestIsValidPhone_Empty;

    [Test]
    procedure TestIsValidEmail_Valid;
    [Test]
    procedure TestIsValidEmail_NoAt;
    [Test]
    procedure TestIsValidEmail_NoDomain;
    [Test]
    procedure TestIsValidEmail_Empty;

    [Test]
    procedure TestGetInitials_TwoWords;
    [Test]
    procedure TestGetInitials_SingleWord;
    [Test]
    procedure TestGetInitials_Empty;
    [Test]
    procedure TestGetInitials_ThreeWords;
    [Test]
    procedure TestGetInitials_WithSpaces;

    [Test]
    procedure TestTruncateText_Short;
    [Test]
    procedure TestTruncateText_Exact;
    [Test]
    procedure TestTruncateText_Long;

    [Test]
    procedure TestDateToDisplayStr_Valid;
    [Test]
    procedure TestDateToDisplayStr_Zero;

    [Test]
    procedure TestTimeToDisplayStr_Valid;
    [Test]
    procedure TestTimeToDisplayStr_Zero;

    [Test]
    procedure TestDateTimeToDisplayStr_Valid;
    [Test]
    procedure TestDateTimeToDisplayStr_Zero;

    [Test]
    procedure TestRelativeTimeStr_Recent;
  end;

implementation

uses
  System.DateUtils;

{ TTestHelpers }

procedure TTestHelpers.TestFormatCurrency_Normal;
var
  LResult: string;
begin
  LResult := THelpers.FormatCurrency(250.50);
  Assert.IsNotEmpty(LResult);
  Assert.Contains(LResult, '250');
end;

procedure TTestHelpers.TestFormatCurrency_Zero;
var
  LResult: string;
begin
  LResult := THelpers.FormatCurrency(0);
  Assert.IsNotEmpty(LResult);
  Assert.Contains(LResult, '0');
end;

procedure TTestHelpers.TestFormatCurrency_Large;
var
  LResult: string;
begin
  LResult := THelpers.FormatCurrency(1000000);
  Assert.IsNotEmpty(LResult);
end;

procedure TTestHelpers.TestFormatPhone_10Digits;
var
  LResult: string;
begin
  LResult := THelpers.FormatPhone('5321234567');
  Assert.Contains(LResult, '532');
  Assert.Contains(LResult, '123');
end;

procedure TTestHelpers.TestFormatPhone_11Digits;
var
  LResult: string;
begin
  LResult := THelpers.FormatPhone('05321234567');
  Assert.Contains(LResult, '0532');
end;

procedure TTestHelpers.TestFormatPhone_Invalid;
var
  LResult: string;
begin
  LResult := THelpers.FormatPhone('123');
  Assert.AreEqual('123', LResult);
end;

procedure TTestHelpers.TestCleanPhone_WithSpaces;
begin
  Assert.AreEqual('05321234567', THelpers.CleanPhone('0532 123 45 67'));
end;

procedure TTestHelpers.TestCleanPhone_WithDashes;
begin
  Assert.AreEqual('05321234567', THelpers.CleanPhone('0532-123-45-67'));
end;

procedure TTestHelpers.TestCleanPhone_WithParens;
begin
  Assert.AreEqual('05321234567', THelpers.CleanPhone('(0532) 123 45 67'));
end;

procedure TTestHelpers.TestCleanPhone_AlreadyClean;
begin
  Assert.AreEqual('05321234567', THelpers.CleanPhone('05321234567'));
end;

procedure TTestHelpers.TestIsValidPhone_Valid10;
begin
  Assert.IsTrue(THelpers.IsValidPhone('5321234567'));
end;

procedure TTestHelpers.TestIsValidPhone_Valid11;
begin
  Assert.IsTrue(THelpers.IsValidPhone('05321234567'));
end;

procedure TTestHelpers.TestIsValidPhone_TooShort;
begin
  Assert.IsFalse(THelpers.IsValidPhone('12345'));
end;

procedure TTestHelpers.TestIsValidPhone_TooLong;
begin
  Assert.IsFalse(THelpers.IsValidPhone('123456789012'));
end;

procedure TTestHelpers.TestIsValidPhone_Empty;
begin
  Assert.IsFalse(THelpers.IsValidPhone(''));
end;

procedure TTestHelpers.TestIsValidEmail_Valid;
begin
  Assert.IsTrue(THelpers.IsValidEmail('test@example.com'));
end;

procedure TTestHelpers.TestIsValidEmail_NoAt;
begin
  Assert.IsFalse(THelpers.IsValidEmail('testexample.com'));
end;

procedure TTestHelpers.TestIsValidEmail_NoDomain;
begin
  Assert.IsFalse(THelpers.IsValidEmail('test@'));
end;

procedure TTestHelpers.TestIsValidEmail_Empty;
begin
  Assert.IsFalse(THelpers.IsValidEmail(''));
end;

procedure TTestHelpers.TestGetInitials_TwoWords;
begin
  Assert.AreEqual('AY', THelpers.GetInitials('Ahmet Yilmaz'));
end;

procedure TTestHelpers.TestGetInitials_SingleWord;
begin
  Assert.AreEqual('A', THelpers.GetInitials('Ahmet'));
end;

procedure TTestHelpers.TestGetInitials_Empty;
begin
  Assert.AreEqual('', THelpers.GetInitials(''));
end;

procedure TTestHelpers.TestGetInitials_ThreeWords;
begin
  Assert.AreEqual('AY', THelpers.GetInitials('Ahmet Can Yilmaz'));
end;

procedure TTestHelpers.TestGetInitials_WithSpaces;
begin
  Assert.AreEqual('AY', THelpers.GetInitials('  Ahmet Yilmaz  '));
end;

procedure TTestHelpers.TestTruncateText_Short;
begin
  Assert.AreEqual('Hello', THelpers.TruncateText('Hello', 10));
end;

procedure TTestHelpers.TestTruncateText_Exact;
begin
  Assert.AreEqual('Hello', THelpers.TruncateText('Hello', 5));
end;

procedure TTestHelpers.TestTruncateText_Long;
var
  LResult: string;
begin
  LResult := THelpers.TruncateText('Hello World Test', 10);
  Assert.AreEqual(10, Length(LResult));
  Assert.IsTrue(LResult.EndsWith('...'));
end;

procedure TTestHelpers.TestDateToDisplayStr_Valid;
begin
  Assert.AreEqual('12.05.2024', THelpers.DateToDisplayStr(EncodeDate(2024, 5, 12)));
end;

procedure TTestHelpers.TestDateToDisplayStr_Zero;
begin
  Assert.AreEqual('-', THelpers.DateToDisplayStr(0));
end;

procedure TTestHelpers.TestTimeToDisplayStr_Valid;
var
  LResult: string;
begin
  LResult := THelpers.TimeToDisplayStr(EncodeDate(2024, 5, 12) + EncodeTime(9, 25, 0, 0));
  Assert.AreEqual('09:25', LResult);
end;

procedure TTestHelpers.TestTimeToDisplayStr_Zero;
begin
  Assert.AreEqual('-', THelpers.TimeToDisplayStr(0));
end;

procedure TTestHelpers.TestDateTimeToDisplayStr_Valid;
var
  LResult: string;
begin
  LResult := THelpers.DateTimeToDisplayStr(EncodeDate(2024, 5, 12) + EncodeTime(14, 30, 0, 0));
  Assert.AreEqual('12.05.2024 14:30', LResult);
end;

procedure TTestHelpers.TestDateTimeToDisplayStr_Zero;
begin
  Assert.AreEqual('-', THelpers.DateTimeToDisplayStr(0));
end;

procedure TTestHelpers.TestRelativeTimeStr_Recent;
var
  LResult: string;
begin
  LResult := THelpers.RelativeTimeStr(Now);
  Assert.IsNotEmpty(LResult);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestHelpers);

end.
