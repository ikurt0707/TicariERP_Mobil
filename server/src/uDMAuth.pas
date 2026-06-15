unit uDMAuth;

interface

uses
  System.SysUtils, System.Classes,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Stan.Param,
  FireDAC.Phys, FireDAC.Phys.MSSQL, FireDAC.Phys.MSSQLDef,
  FireDAC.UI.Intf, FireDAC.ConsoleUI.Wait,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  FireDAC.DApt, FireDAC.DApt.Intf;

type
  TDMAuth = class(TDataModule)
    FDConnectionAuth: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
  private
    procedure ConfigureAuthConnection;
  public
    function GetAuthQuery: TFDQuery;
  end;

var
  DMAuth: TDMAuth;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TDMAuth.DataModuleCreate(Sender: TObject);
begin
  ConfigureAuthConnection;
  FDConnectionAuth.Connected := True;
end;

procedure TDMAuth.ConfigureAuthConnection;
var
  LServer, LPort: string;
begin
  LServer := GetEnvironmentVariable('MSSQL_SERVER_HOST');
  LPort := GetEnvironmentVariable('MSSQL_SERVER_PORT');

  if LServer = '' then LServer := '127.0.0.1';
  if LPort = '' then LPort := '1433';

  FDConnectionAuth.Params.Clear;
  FDConnectionAuth.Params.DriverID := 'MSSQL';
  FDConnectionAuth.Params.Add('Server=' + LServer + ',' + LPort);
  FDConnectionAuth.Params.Database := 'ERP_AUTH';
  FDConnectionAuth.Params.UserName := GetEnvironmentVariable('MSSQL_USERNAME');
  FDConnectionAuth.Params.Password := GetEnvironmentVariable('MSSQL_PASSWORD');
  FDConnectionAuth.Params.Add('ApplicationName=TicariERP_API_Auth');
  FDConnectionAuth.LoginPrompt := False;
end;

function TDMAuth.GetAuthQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FDConnectionAuth;
end;

end.
