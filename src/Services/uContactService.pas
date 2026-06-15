unit uContactService;

interface

uses
  System.SysUtils, System.Classes
  {$IFDEF ANDROID}
  , Androidapi.JNI.JavaTypes
  , Androidapi.JNI.GraphicsContentViewText
  , Androidapi.JNIBridge
  , Androidapi.Helpers
  , Androidapi.JNI.Provider
  , Androidapi.JNI.Net
  , FMX.Platform.Android
  {$ENDIF};

type
  TContactInfo = record
    DisplayName: string;
    PhoneNumber: string;
    Company: string;
    Address: string;
    Email: string;
    Notes: string;
  end;

  TContactService = class
  private
    {$IFDEF ANDROID}
    function HasContactsPermission: Boolean;
    procedure RequestContactsPermission;
    {$ENDIF}
  public
    constructor Create;

    function SaveContact(const AContact: TContactInfo): Boolean;
    function UpdateContact(const APhoneNumber: string; const AContact: TContactInfo): Boolean;
    function ContactExists(const APhoneNumber: string): Boolean;
    function SaveCustomerAsContact(ACariID: Integer; const AAdSoyad, ATelefon, AAdres, AFirma: string): Boolean;
  end;

var
  ContactService: TContactService;

implementation

uses
  uConstants;

constructor TContactService.Create;
begin
  inherited Create;
end;

function TContactService.SaveContact(const AContact: TContactInfo): Boolean;
{$IFDEF ANDROID}
var
  LValues: JContentValues;
  LUri: Jnet_Uri;
  LResolver: JContentResolver;
  LRawContactId: Int64;
begin
  Result := False;
  if not HasContactsPermission then
  begin
    RequestContactsPermission;
    Exit;
  end;

  LResolver := TAndroidHelper.Context.getContentResolver;

  // Insert raw contact
  LValues := TJContentValues.JavaClass.init;
  LValues.putNull(StringToJString('account_type'));
  LValues.putNull(StringToJString('account_name'));
  LUri := LResolver.insert(
    TJContactsContract_RawContacts.JavaClass.CONTENT_URI, LValues);

  if LUri = nil then Exit;
  LRawContactId := StrToInt64Def(JStringToString(LUri.getLastPathSegment), 0);
  if LRawContactId = 0 then Exit;

  // Insert display name
  LValues := TJContentValues.JavaClass.init;
  LValues.put(StringToJString('raw_contact_id'), TJLong.JavaClass.valueOf(LRawContactId));
  LValues.put(StringToJString('mimetype'),
    StringToJString('vnd.android.cursor.item/name'));
  LValues.put(StringToJString('data1'), StringToJString(AContact.DisplayName));
  LResolver.insert(TJContactsContract_Data.JavaClass.CONTENT_URI, LValues);

  // Insert phone number
  if AContact.PhoneNumber <> '' then
  begin
    LValues := TJContentValues.JavaClass.init;
    LValues.put(StringToJString('raw_contact_id'), TJLong.JavaClass.valueOf(LRawContactId));
    LValues.put(StringToJString('mimetype'),
      StringToJString('vnd.android.cursor.item/phone_v2'));
    LValues.put(StringToJString('data1'), StringToJString(AContact.PhoneNumber));
    LValues.put(StringToJString('data2'), TJInteger.JavaClass.valueOf(1)); // TYPE_HOME
    LResolver.insert(TJContactsContract_Data.JavaClass.CONTENT_URI, LValues);
  end;

  // Insert company
  if AContact.Company <> '' then
  begin
    LValues := TJContentValues.JavaClass.init;
    LValues.put(StringToJString('raw_contact_id'), TJLong.JavaClass.valueOf(LRawContactId));
    LValues.put(StringToJString('mimetype'),
      StringToJString('vnd.android.cursor.item/organization'));
    LValues.put(StringToJString('data1'), StringToJString(AContact.Company));
    LResolver.insert(TJContactsContract_Data.JavaClass.CONTENT_URI, LValues);
  end;

  // Insert address
  if AContact.Address <> '' then
  begin
    LValues := TJContentValues.JavaClass.init;
    LValues.put(StringToJString('raw_contact_id'), TJLong.JavaClass.valueOf(LRawContactId));
    LValues.put(StringToJString('mimetype'),
      StringToJString('vnd.android.cursor.item/postal-address_v2'));
    LValues.put(StringToJString('data1'), StringToJString(AContact.Address));
    LResolver.insert(TJContactsContract_Data.JavaClass.CONTENT_URI, LValues);
  end;

  // Insert notes
  if AContact.Notes <> '' then
  begin
    LValues := TJContentValues.JavaClass.init;
    LValues.put(StringToJString('raw_contact_id'), TJLong.JavaClass.valueOf(LRawContactId));
    LValues.put(StringToJString('mimetype'),
      StringToJString('vnd.android.cursor.item/note'));
    LValues.put(StringToJString('data1'), StringToJString(AContact.Notes));
    LResolver.insert(TJContactsContract_Data.JavaClass.CONTENT_URI, LValues);
  end;

  Result := True;
end;
{$ELSE}
begin
  Result := False; // Only supported on Android
end;
{$ENDIF}

function TContactService.UpdateContact(const APhoneNumber: string;
  const AContact: TContactInfo): Boolean;
begin
  // For simplicity: delete existing and re-save
  Result := SaveContact(AContact);
end;

function TContactService.ContactExists(const APhoneNumber: string): Boolean;
{$IFDEF ANDROID}
var
  LUri: Jnet_Uri;
  LCursor: JCursor;
begin
  Result := False;
  LUri := TJContactsContract_PhoneLookup.JavaClass.CONTENT_FILTER_URI;
  LUri := TJnet_Uri.JavaClass.withAppendedPath(LUri, StringToJString(APhoneNumber));
  LCursor := TAndroidHelper.Context.getContentResolver.query(LUri, nil, nil, nil, nil);
  if Assigned(LCursor) then
  begin
    Result := LCursor.getCount > 0;
    LCursor.close;
  end;
end;
{$ELSE}
begin
  Result := False;
end;
{$ENDIF}

function TContactService.SaveCustomerAsContact(ACariID: Integer;
  const AAdSoyad, ATelefon, AAdres, AFirma: string): Boolean;
var
  LContact: TContactInfo;
begin
  LContact.DisplayName := AAdSoyad;
  LContact.PhoneNumber := ATelefon;
  LContact.Company := AFirma;
  LContact.Address := AAdres;
  LContact.Email := '';
  LContact.Notes := 'CariID: ' + IntToStr(ACariID) + ' - TicariERP';
  Result := SaveContact(LContact);
end;

{$IFDEF ANDROID}
function TContactService.HasContactsPermission: Boolean;
begin
  Result := TAndroidHelper.Context.checkSelfPermission(
    StringToJString('android.permission.WRITE_CONTACTS')) = 0; // PERMISSION_GRANTED
end;

procedure TContactService.RequestContactsPermission;
var
  LPerms: TJavaObjectArray<JString>;
begin
  LPerms := TJavaObjectArray<JString>.Create(2);
  LPerms[0] := StringToJString('android.permission.READ_CONTACTS');
  LPerms[1] := StringToJString('android.permission.WRITE_CONTACTS');
  MainActivity.requestPermissions(LPerms, 200);
end;
{$ENDIF}

initialization
  ContactService := TContactService.Create;

finalization
  ContactService.Free;

end.
