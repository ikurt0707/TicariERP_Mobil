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
  uDM in 'src\uDM.pas' {DM: TDataModule},
  uDMAuth in 'src\uDMAuth.pas' {DMAuth: TDataModule};

{$R *.res}

procedure RunServer;
var
  LServer: TIdHTTPWebBrokerBridge;
  LPort: Integer;
begin
  LPort := 8080;
  if ParamCount > 0 then
    LPort := StrToIntDef(ParamStr(1), 8080);

  // DataModule'leri olustur (Console app'te otomatik olusturulmazlar)
  WriteLn('DataModule''ler olusturuluyor...');
  DM := TDM.Create(nil);
  WriteLn('[DM] Tenant DataModule olusturuldu.');
  DMAuth := TDMAuth.Create(nil);
  ServerContainer1 := TServerContainer1.Create(nil);
  WriteLn('[ServerContainer] DSServer olusturuldu.');

  LServer := TIdHTTPWebBrokerBridge.Create(nil);
  try
    LServer.DefaultPort := LPort;
    LServer.Active := True;
    WriteLn(Format('TicariERP REST API Server started on port %d', [LPort]));
    WriteLn('Press Enter to stop...');
    ReadLn;
  finally
    LServer.Free;
    ServerContainer1.Free;
    DMAuth.Free;
    DM.Free;
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
