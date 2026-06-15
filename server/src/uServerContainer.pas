unit uServerContainer;

interface

uses
  System.SysUtils, System.Classes,
  Datasnap.DSServer, Datasnap.DSCommonServer, Datasnap.DSAuth,
  IPPeerServer;

type
  TServerContainer1 = class(TDataModule)
    DSServer1: TDSServer;
    DSServerClass_Cari: TDSServerClass;
    DSServerClass_Siparis: TDSServerClass;
    DSServerClass_Stok: TDSServerClass;
    DSServerClass_CallerID: TDSServerClass;
    DSServerClass_Kurye: TDSServerClass;
    DSServerClass_Auth: TDSServerClass;
    procedure DSServerClass_CariGetClass(DSServerClass: TDSServerClass;
      var PersistentClass: TPersistentClass);
    procedure DSServerClass_SiparisGetClass(DSServerClass: TDSServerClass;
      var PersistentClass: TPersistentClass);
    procedure DSServerClass_StokGetClass(DSServerClass: TDSServerClass;
      var PersistentClass: TPersistentClass);
    procedure DSServerClass_CallerIDGetClass(DSServerClass: TDSServerClass;
      var PersistentClass: TPersistentClass);
    procedure DSServerClass_KuryeGetClass(DSServerClass: TDSServerClass;
      var PersistentClass: TPersistentClass);
    procedure DSServerClass_AuthGetClass(DSServerClass: TDSServerClass;
      var PersistentClass: TPersistentClass);
  private
  public
  end;

var
  ServerContainer1: TServerContainer1;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

uses
  uSmCari, uSmSiparis, uSmStok, uSmCallerID, uSmKurye, uSmAuth;

procedure TServerContainer1.DSServerClass_CariGetClass(
  DSServerClass: TDSServerClass; var PersistentClass: TPersistentClass);
begin
  PersistentClass := TSmCari;
end;

procedure TServerContainer1.DSServerClass_SiparisGetClass(
  DSServerClass: TDSServerClass; var PersistentClass: TPersistentClass);
begin
  PersistentClass := TSmSiparis;
end;

procedure TServerContainer1.DSServerClass_StokGetClass(
  DSServerClass: TDSServerClass; var PersistentClass: TPersistentClass);
begin
  PersistentClass := TSmStok;
end;

procedure TServerContainer1.DSServerClass_CallerIDGetClass(
  DSServerClass: TDSServerClass; var PersistentClass: TPersistentClass);
begin
  PersistentClass := TSmCallerID;
end;

procedure TServerContainer1.DSServerClass_KuryeGetClass(
  DSServerClass: TDSServerClass; var PersistentClass: TPersistentClass);
begin
  PersistentClass := TSmKurye;
end;

procedure TServerContainer1.DSServerClass_AuthGetClass(
  DSServerClass: TDSServerClass; var PersistentClass: TPersistentClass);
begin
  PersistentClass := TSmAuth;
end;

end.
