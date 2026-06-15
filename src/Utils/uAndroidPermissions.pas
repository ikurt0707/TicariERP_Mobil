unit uAndroidPermissions;

interface

uses
  System.SysUtils, System.Classes
  {$IFDEF ANDROID}
  , Androidapi.JNI.JavaTypes
  , Androidapi.JNI.GraphicsContentViewText
  , Androidapi.Helpers
  , Androidapi.JNI.Os
  , FMX.Platform.Android
  {$ENDIF};

type
  TPermissionResult = (prGranted, prDenied, prNeverAsk);

  TOnPermissionResult = procedure(const APermission: string; AResult: TPermissionResult) of object;

  TAndroidPermissions = class
  private
    FOnResult: TOnPermissionResult;
  public
    constructor Create;

    procedure RequestPhonePermissions;
    procedure RequestContactPermissions;
    procedure RequestAllAppPermissions;

    function HasPermission(const APermission: string): Boolean;
    function HasPhonePermissions: Boolean;
    function HasContactPermissions: Boolean;

    property OnResult: TOnPermissionResult read FOnResult write FOnResult;
  end;

const
  PERM_READ_PHONE_STATE = 'android.permission.READ_PHONE_STATE';
  PERM_READ_CALL_LOG = 'android.permission.READ_CALL_LOG';
  PERM_READ_CONTACTS = 'android.permission.READ_CONTACTS';
  PERM_WRITE_CONTACTS = 'android.permission.WRITE_CONTACTS';
  PERM_INTERNET = 'android.permission.INTERNET';
  PERM_FOREGROUND_SERVICE = 'android.permission.FOREGROUND_SERVICE';
  PERM_RECEIVE_BOOT = 'android.permission.RECEIVE_BOOT_COMPLETED';

  REQ_CODE_PHONE = 100;
  REQ_CODE_CONTACTS = 200;
  REQ_CODE_ALL = 300;

var
  AndroidPermissions: TAndroidPermissions;

implementation

constructor TAndroidPermissions.Create;
begin
  inherited Create;
end;

function TAndroidPermissions.HasPermission(const APermission: string): Boolean;
begin
  {$IFDEF ANDROID}
  Result := TAndroidHelper.Context.checkSelfPermission(
    StringToJString(APermission)) = 0;
  {$ELSE}
  Result := True;
  {$ENDIF}
end;

function TAndroidPermissions.HasPhonePermissions: Boolean;
begin
  Result := HasPermission(PERM_READ_PHONE_STATE) and
            HasPermission(PERM_READ_CALL_LOG);
end;

function TAndroidPermissions.HasContactPermissions: Boolean;
begin
  Result := HasPermission(PERM_READ_CONTACTS) and
            HasPermission(PERM_WRITE_CONTACTS);
end;

procedure TAndroidPermissions.RequestPhonePermissions;
{$IFDEF ANDROID}
var
  LPerms: TJavaObjectArray<JString>;
begin
  LPerms := TJavaObjectArray<JString>.Create(2);
  LPerms[0] := StringToJString(PERM_READ_PHONE_STATE);
  LPerms[1] := StringToJString(PERM_READ_CALL_LOG);
  MainActivity.requestPermissions(LPerms, REQ_CODE_PHONE);
end;
{$ELSE}
begin
end;
{$ENDIF}

procedure TAndroidPermissions.RequestContactPermissions;
{$IFDEF ANDROID}
var
  LPerms: TJavaObjectArray<JString>;
begin
  LPerms := TJavaObjectArray<JString>.Create(2);
  LPerms[0] := StringToJString(PERM_READ_CONTACTS);
  LPerms[1] := StringToJString(PERM_WRITE_CONTACTS);
  MainActivity.requestPermissions(LPerms, REQ_CODE_CONTACTS);
end;
{$ELSE}
begin
end;
{$ENDIF}

procedure TAndroidPermissions.RequestAllAppPermissions;
{$IFDEF ANDROID}
var
  LPerms: TJavaObjectArray<JString>;
begin
  LPerms := TJavaObjectArray<JString>.Create(4);
  LPerms[0] := StringToJString(PERM_READ_PHONE_STATE);
  LPerms[1] := StringToJString(PERM_READ_CALL_LOG);
  LPerms[2] := StringToJString(PERM_READ_CONTACTS);
  LPerms[3] := StringToJString(PERM_WRITE_CONTACTS);
  MainActivity.requestPermissions(LPerms, REQ_CODE_ALL);
end;
{$ELSE}
begin
end;
{$ENDIF}

initialization
  AndroidPermissions := TAndroidPermissions.Create;

finalization
  AndroidPermissions.Free;

end.
