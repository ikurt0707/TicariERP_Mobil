unit uDM;

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
  TDM = class(TDataModule)
    FDConnection: TFDConnection;
    FDPhysMSSQLDriverLink: TFDPhysMSSQLDriverLink;
    procedure DataModuleCreate(Sender: TObject);
  private
    procedure ConfigureConnection;
  public
    function GetQuery: TFDQuery;
  end;

var
  DM: TDM;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  ConfigureConnection;
  FDConnection.Connected := True;
end;

procedure TDM.ConfigureConnection;
var
  LServer, LPort, LDatabase, LUser, LPassword: string;
begin
  LServer := GetEnvironmentVariable('MSSQL_SERVER_HOST');
  LPort := GetEnvironmentVariable('MSSQL_SERVER_PORT');
  LDatabase := GetEnvironmentVariable('MSSQL_DATABASE_NAME');
  LUser := GetEnvironmentVariable('MSSQL_USERNAME');
  LPassword := GetEnvironmentVariable('MSSQL_PASSWORD');

  if LServer = '' then LServer := '127.0.0.1';
  if LPort = '' then LPort := '1433';
  if LDatabase = '' then LDatabase := 'TicariERP';
  if LUser = '' then LUser := 'SA';

  FDConnection.Params.Clear;
  FDConnection.Params.DriverID := 'MSSQL';
  FDConnection.Params.Add('Server=' + LServer + ',' + LPort);
  FDConnection.Params.Database := LDatabase;
  FDConnection.Params.UserName := LUser;
  FDConnection.Params.Password := LPassword;
  FDConnection.Params.Add('ApplicationName=TicariERP_API');
  FDConnection.LoginPrompt := False;
end;

function TDM.GetQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FDConnection;
end;

end.
