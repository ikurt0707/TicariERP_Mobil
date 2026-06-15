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
    FTenantConnected: Boolean;
  public
    function GetQuery: TFDQuery;
    procedure ConnectToTenantDB(const AServer, ADatabase, AUser, APassword: string);
    property TenantConnected: Boolean read FTenantConnected;
  end;

var
  DM: TDM;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  FTenantConnected := False;
end;

procedure TDM.ConnectToTenantDB(const AServer, ADatabase, AUser, APassword: string);
begin
  FDConnection.Connected := False;
  FDConnection.Params.Clear;
  FDConnection.Params.DriverID := 'MSSQL';
  FDConnection.Params.Add('Server=' + AServer + ',1433');
  FDConnection.Params.Database := ADatabase;
  FDConnection.Params.UserName := AUser;
  FDConnection.Params.Password := APassword;
  FDConnection.Params.Add('ApplicationName=TicariERP_API_Tenant');
  FDConnection.LoginPrompt := False;
  FDConnection.Connected := True;
  FTenantConnected := True;
end;

function TDM.GetQuery: TFDQuery;
begin
  if not FTenantConnected then
    raise Exception.Create('Tenant veritabanina baglanilmamis. Once login yapiniz.');
  Result := TFDQuery.Create(nil);
  Result.Connection := FDConnection;
end;

end.
