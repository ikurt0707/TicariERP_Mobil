unit uCallDetectionService;

interface

uses
  System.SysUtils, System.Classes, System.JSON
  {$IFDEF ANDROID}
  , Androidapi.JNI.JavaTypes
  , Androidapi.JNI.GraphicsContentViewText
  , Androidapi.JNIBridge
  , Androidapi.JNI.Telephony
  , Androidapi.JNI.Os
  , Androidapi.Helpers
  , Androidapi.JNI.App
  , FMX.Platform.Android
  {$ENDIF};

type
  TCallState = (csIdle, csRinging, csOffhook);

  TOnIncomingCall = procedure(const APhoneNumber: string) of object;
  TOnCallStateChanged = procedure(AState: TCallState; const APhoneNumber: string) of object;

  TCallDetectionService = class
  private
    FActive: Boolean;
    FOnIncomingCall: TOnIncomingCall;
    FOnCallStateChanged: TOnCallStateChanged;
    FLastNumber: string;
    {$IFDEF ANDROID}
    procedure RegisterReceiver;
    procedure UnregisterReceiver;
    procedure StartForegroundService;
    procedure StopForegroundService;
    {$ENDIF}
    procedure LogCallToServer(const APhoneNumber: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start;
    procedure Stop;

    property Active: Boolean read FActive;
    property OnIncomingCall: TOnIncomingCall read FOnIncomingCall write FOnIncomingCall;
    property OnCallStateChanged: TOnCallStateChanged read FOnCallStateChanged write FOnCallStateChanged;
  end;

var
  CallDetectionService: TCallDetectionService;

implementation

uses
  uApiService, uConstants;

constructor TCallDetectionService.Create;
begin
  inherited Create;
  FActive := False;
  FLastNumber := '';
end;

destructor TCallDetectionService.Destroy;
begin
  if FActive then
    Stop;
  inherited;
end;

procedure TCallDetectionService.Start;
begin
  if FActive then Exit;
  {$IFDEF ANDROID}
  RegisterReceiver;
  StartForegroundService;
  {$ENDIF}
  FActive := True;
end;

procedure TCallDetectionService.Stop;
begin
  if not FActive then Exit;
  {$IFDEF ANDROID}
  UnregisterReceiver;
  StopForegroundService;
  {$ENDIF}
  FActive := False;
end;

{$IFDEF ANDROID}
procedure TCallDetectionService.RegisterReceiver;
var
  LFilter: JIntentFilter;
begin
  LFilter := TJIntentFilter.JavaClass.init;
  LFilter.addAction(StringToJString('android.intent.action.PHONE_STATE'));
  LFilter.addAction(StringToJString('android.intent.action.NEW_OUTGOING_CALL'));
  TAndroidHelper.Context.registerReceiver(
    TJBroadcastReceiver.Wrap(nil), LFilter);
end;

procedure TCallDetectionService.UnregisterReceiver;
begin
  // Unregister broadcast receiver
end;

procedure TCallDetectionService.StartForegroundService;
var
  LIntent: JIntent;
begin
  LIntent := TJIntent.JavaClass.init;
  LIntent.setAction(StringToJString('com.ticarierp.mobil.CALL_DETECTION'));
  if TOSVersion.Check(8, 0) then
    TAndroidHelper.Context.startForegroundService(LIntent)
  else
    TAndroidHelper.Context.startService(LIntent);
end;

procedure TCallDetectionService.StopForegroundService;
var
  LIntent: JIntent;
begin
  LIntent := TJIntent.JavaClass.init;
  LIntent.setAction(StringToJString('com.ticarierp.mobil.CALL_DETECTION'));
  TAndroidHelper.Context.stopService(LIntent);
end;
{$ENDIF}

procedure TCallDetectionService.LogCallToServer(const APhoneNumber: string);
var
  LBody: TJSONObject;
  LResponse: TApiResponse;
begin
  LBody := TJSONObject.Create;
  try
    LBody.AddPair('telefon', APhoneNumber);
    LBody.AddPair('tarih', DateTimeToStr(Now));
    LBody.AddPair('yon', 'Gelen');
    LResponse := ApiService.Post('rest/TSmCallerID/LogCallerIdEvent/', LBody);
    try
      // Fire-and-forget, just ensure no memory leak
    finally
      LResponse.Free;
    end;
  finally
    LBody.Free;
  end;

  FLastNumber := APhoneNumber;
  if Assigned(FOnIncomingCall) then
    FOnIncomingCall(APhoneNumber);
end;

initialization
  CallDetectionService := TCallDetectionService.Create;

finalization
  CallDetectionService.Free;

end.
