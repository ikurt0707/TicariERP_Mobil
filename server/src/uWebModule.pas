unit uWebModule;

interface

uses
  System.SysUtils, System.Classes,
  Web.HTTPApp,
  Datasnap.DSHTTPWebBroker, Datasnap.DSServer,
  IPPeerServer;

type
  TWebModule1 = class(TWebModule)
    DSHTTPWebDispatcher1: TDSHTTPWebDispatcher;
    procedure WebModuleCreate(Sender: TObject);
  private
  public
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

uses
  uServerContainer;

procedure TWebModule1.WebModuleCreate(Sender: TObject);
begin
  DSHTTPWebDispatcher1.Server := ServerContainer1.DSServer1;
end;

end.
