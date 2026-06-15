program TicariERP_Tests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF}
  DUnitX.TestFramework,
  TestCustomer in 'TestCustomer.pas',
  TestProduct in 'TestProduct.pas',
  TestOrder in 'TestOrder.pas',
  TestCourier in 'TestCourier.pas',
  TestDailySummary in 'TestDailySummary.pas',
  TestHelpers in 'TestHelpers.pas',
  TestOrderService in 'TestOrderService.pas',
  uCustomer in '..\src\Models\uCustomer.pas',
  uProduct in '..\src\Models\uProduct.pas',
  uOrder in '..\src\Models\uOrder.pas',
  uCourier in '..\src\Models\uCourier.pas',
  uDailySummary in '..\src\Models\uDailySummary.pas',
  uHelpers in '..\src\Utils\uHelpers.pas',
  uConstants in '..\src\Utils\uConstants.pas',
  uApiService in '..\src\Services\uApiService.pas',
  uAuthService in '..\src\Services\uAuthService.pas',
  uOrderService in '..\src\Services\uOrderService.pas',
  uCustomerService in '..\src\Services\uCustomerService.pas';

{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger: ITestLogger;
{$ENDIF}

begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    TDUnitX.CheckCommandLine;
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    runner.FailsOnNoAsserts := False;

    logger := TDUnitXConsoleLogger.Create(True);
    runner.AddLogger(logger);

    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    runner.Execute;
    results := runner.Execute;

    {$IFNDEF CI}
    if results.FailureCount > 0 then
      System.ExitCode := EXIT_ERRORS
    else
      System.ExitCode := 0;
    {$ELSE}
    System.ExitCode := Ord(not results.AllPassed);
    {$ENDIF}
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := EXIT_ERRORS;
    end;
  end;
{$ENDIF}
end.
