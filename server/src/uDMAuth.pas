unit uDMAuth;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, System.IOUtils,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Stan.Param,
  FireDAC.Phys, FireDAC.Phys.MSSQL, FireDAC.Phys.MSSQLDef,
  FireDAC.UI.Intf, FireDAC.ConsoleUI.Wait,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  FireDAC.DApt, FireDAC.DApt.Intf;

type
  TDMAuth = class(TDataModule)
    FDConnectionAuth: TFDConnection;
    FDPhysMSSQLDriverLink1: TFDPhysMSSQLDriverLink;
    procedure DataModuleCreate(Sender: TObject);
  private
    FConnected: Boolean;
    procedure ConfigureAuthConnection;
    function GetIniFilePath: string;
  public
    function GetAuthQuery: TFDQuery;
    property Connected: Boolean read FConnected;
  end;

var
  DMAuth: TDMAuth;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TDMAuth.DataModuleCreate(Sender: TObject);
begin
  FConnected := False;
  try
    ConfigureAuthConnection;
    FDConnectionAuth.Connected := True;
    FConnected := True;
    WriteLn('[DMAuth] ERP_AUTH veritabanina baglandi.');
  except
    on E: Exception do
      WriteLn('[DMAuth] HATA - ERP_AUTH baglanti basarisiz: ' + E.Message);
  end;
end;

function TDMAuth.GetIniFilePath: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'server.ini');
end;

procedure TDMAuth.ConfigureAuthConnection;
var
  LIni: TIniFile;
  LIniPath: string;
  LServer, LPort, LDatabase, LUsername, LPassword: string;
begin
  LIniPath := GetIniFilePath;

  // Oncelik: server.ini dosyasi, yoksa ortam degiskenleri
  if FileExists(LIniPath) then
  begin
    WriteLn('[DMAuth] server.ini okunuyor: ' + LIniPath);
    LIni := TIniFile.Create(LIniPath);
    try
      LServer := LIni.ReadString('Database', 'Server', '127.0.0.1');
      LPort := LIni.ReadString('Database', 'Port', '1433');
      LDatabase := LIni.ReadString('Database', 'AuthDatabase', 'ERP_AUTH');
      LUsername := LIni.ReadString('Database', 'Username', '');
      LPassword := LIni.ReadString('Database', 'Password', '');
    finally
      LIni.Free;
    end;
  end
  else
  begin
    WriteLn('[DMAuth] server.ini bulunamadi, ortam degiskenleri kullaniliyor...');
    LServer := GetEnvironmentVariable('MSSQL_SERVER_HOST');
    LPort := GetEnvironmentVariable('MSSQL_SERVER_PORT');
    LDatabase := GetEnvironmentVariable('MSSQL_DATABASE_AUTH');
    LUsername := GetEnvironmentVariable('MSSQL_USERNAME');
    LPassword := GetEnvironmentVariable('MSSQL_PASSWORD');

    if LServer = '' then LServer := '127.0.0.1';
    if LPort = '' then LPort := '1433';
    if LDatabase = '' then LDatabase := 'ERP_AUTH';
  end;

  if LUsername = '' then
    WriteLn('[DMAuth] UYARI: Kullanici adi bos! server.ini veya ortam degiskenlerini kontrol edin.');

  FDConnectionAuth.Params.Clear;
  FDConnectionAuth.Params.DriverID := 'MSSQL';
  FDConnectionAuth.Params.Add('Server=' + LServer + ',' + LPort);
  FDConnectionAuth.Params.Database := LDatabase;
  FDConnectionAuth.Params.UserName := LUsername;
  FDConnectionAuth.Params.Password := LPassword;
  FDConnectionAuth.Params.Add('ApplicationName=TicariERP_API_Auth');
  FDConnectionAuth.LoginPrompt := False;
end;

function TDMAuth.GetAuthQuery: TFDQuery;
begin
  if not FConnected then
    raise Exception.Create('ERP_AUTH veritabanina baglanilmamis. server.ini dosyasini kontrol edin.');
  Result := TFDQuery.Create(nil);
  Result.Connection := FDConnectionAuth;
end;

end.
