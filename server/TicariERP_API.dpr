program TicariERP_API;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  IPPeerServer,
  IPPeerAPI,
  IdHTTPWebBrokerBridge,
  Web.WebReq,
  Web.WebBroker,
  uWebModule in 'src\uWebModule.pas' {WebModule1: TWebModule},
  uServerContainer in 'src\uServerContainer.pas' {ServerContainer1: TDataModule},
  uSmCari in 'src\uSmCari.pas' {SmCari: TDSServerModule},
  uSmSiparis in 'src\uSmSiparis.pas' {SmSiparis: TDSServerModule},
  uSmStok in 'src\uSmStok.pas' {SmStok: TDSServerModule},
  uSmCallerID in 'src\uSmCallerID.pas' {SmCallerID: TDSServerModule},
  uSmKurye in 'src\uSmKurye.pas' {SmKurye: TDSServerModule},
  uSmAuth in 'src\uSmAuth.pas' {SmAuth: TDSServerModule},
  uDM in 'src\uDM.pas' {DM: TDataModule};

{$R *.res}

procedure RunServer;
var
  LServer: TIdHTTPWebBrokerBridge;
  LPort: Integer;
begin
  LPort := 8080;
  if ParamCount > 0 then
    LPort := StrToIntDef(ParamStr(1), 8080);

  LServer := TIdHTTPWebBrokerBridge.Create(nil);
  try
    LServer.DefaultPort := LPort;
    LServer.Active := True;
    WriteLn(Format('TicariERP REST API Server started on port %d', [LPort]));
    WriteLn('Press Enter to stop...');
    ReadLn;
  finally
    LServer.Free;
  end;
end;

begin
  try
    if WebRequestHandler <> nil then
      WebRequestHandler.WebModuleClass := WebModuleClass;
    RunServer;
  except
    on E: Exception do
    begin
      WriteLn(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
