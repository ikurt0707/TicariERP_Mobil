unit uSessionManager;

interface

uses
  System.SysUtils, System.Classes;

type
  TSessionInfo = record
    Token: string;
    UserID: Integer;
    KullaniciAdi: string;
    AdSoyad: string;
    RolID: Integer;
    IsKurye: Boolean;
    TenantID: Integer;
    TenantAdi: string;
    DbServer: string;
    DbName: string;
    DbUser: string;
    DbPassword: string;
  end;

  TSessionManager = class
  private
    FSession: TSessionInfo;
    FIsActive: Boolean;
  public
    constructor Create;
    procedure StartSession(const AToken: string; AUserID: Integer;
      const AKullaniciAdi, AAdSoyad: string; ARolID: Integer; AKurye: Boolean;
      ATenantID: Integer; const ATenantAdi: string;
      const ADbServer, ADbName, ADbUser, ADbPassword: string);
    procedure EndSession;
    function IsLoggedIn: Boolean;

    property Session: TSessionInfo read FSession;
    property IsActive: Boolean read FIsActive;
  end;

var
  SessionManager: TSessionManager;

implementation

constructor TSessionManager.Create;
begin
  inherited Create;
  FIsActive := False;
  FillChar(FSession, SizeOf(FSession), 0);
  FSession.Token := '';
  FSession.KullaniciAdi := '';
  FSession.AdSoyad := '';
  FSession.TenantAdi := '';
  FSession.DbServer := '';
  FSession.DbName := '';
  FSession.DbUser := '';
  FSession.DbPassword := '';
end;

procedure TSessionManager.StartSession(const AToken: string; AUserID: Integer;
  const AKullaniciAdi, AAdSoyad: string; ARolID: Integer; AKurye: Boolean;
  ATenantID: Integer; const ATenantAdi: string;
  const ADbServer, ADbName, ADbUser, ADbPassword: string);
begin
  FSession.Token := AToken;
  FSession.UserID := AUserID;
  FSession.KullaniciAdi := AKullaniciAdi;
  FSession.AdSoyad := AAdSoyad;
  FSession.RolID := ARolID;
  FSession.IsKurye := AKurye;
  FSession.TenantID := ATenantID;
  FSession.TenantAdi := ATenantAdi;
  FSession.DbServer := ADbServer;
  FSession.DbName := ADbName;
  FSession.DbUser := ADbUser;
  FSession.DbPassword := ADbPassword;
  FIsActive := True;
end;

procedure TSessionManager.EndSession;
begin
  FIsActive := False;
  FSession.Token := '';
  FSession.KullaniciAdi := '';
  FSession.AdSoyad := '';
  FSession.TenantAdi := '';
  FSession.DbServer := '';
  FSession.DbName := '';
  FSession.DbUser := '';
  FSession.DbPassword := '';
end;

function TSessionManager.IsLoggedIn: Boolean;
begin
  Result := FIsActive and (FSession.Token <> '');
end;

initialization
  SessionManager := TSessionManager.Create;

finalization
  SessionManager.Free;

end.
