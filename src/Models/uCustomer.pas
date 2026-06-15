unit uCustomer;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections;

type
  TCustomerStatus = (csKayitli, csKayitsiz);

  TCustomer = class
  private
    FId: Integer;
    FAdSoyad: string;
    FTelefon: string;
    FAdres: string;
    FBakiye: Currency;
    FSonSiparisTarihi: TDateTime;
    FToplamSiparis: Integer;
    FToplamHarcama: Currency;
    FDurum: TCustomerStatus;
    FLatitude: Double;
    FLongitude: Double;
  public
    constructor Create; overload;
    constructor Create(AId: Integer; const AAdSoyad, ATelefon, AAdres: string); overload;

    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
    function Clone: TCustomer;

    function GetFormattedBakiye: string;
    function GetFormattedToplamHarcama: string;
    function GetInitials: string;
    function GetDurumText: string;
    function IsKayitli: Boolean;

    property Id: Integer read FId write FId;
    property AdSoyad: string read FAdSoyad write FAdSoyad;
    property Telefon: string read FTelefon write FTelefon;
    property Adres: string read FAdres write FAdres;
    property Bakiye: Currency read FBakiye write FBakiye;
    property SonSiparisTarihi: TDateTime read FSonSiparisTarihi write FSonSiparisTarihi;
    property ToplamSiparis: Integer read FToplamSiparis write FToplamSiparis;
    property ToplamHarcama: Currency read FToplamHarcama write FToplamHarcama;
    property Durum: TCustomerStatus read FDurum write FDurum;
    property Latitude: Double read FLatitude write FLatitude;
    property Longitude: Double read FLongitude write FLongitude;
  end;

  TCustomerList = TObjectList<TCustomer>;

implementation

uses
  System.DateUtils;

{ TCustomer }

constructor TCustomer.Create;
begin
  inherited Create;
  FId := 0;
  FAdSoyad := '';
  FTelefon := '';
  FAdres := '';
  FBakiye := 0;
  FSonSiparisTarihi := 0;
  FToplamSiparis := 0;
  FToplamHarcama := 0;
  FDurum := csKayitsiz;
  FLatitude := 0;
  FLongitude := 0;
end;

constructor TCustomer.Create(AId: Integer; const AAdSoyad, ATelefon, AAdres: string);
begin
  Create;
  FId := AId;
  FAdSoyad := AAdSoyad;
  FTelefon := ATelefon;
  FAdres := AAdres;
  FDurum := csKayitli;
end;

function TCustomer.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(FId));
  Result.AddPair('adSoyad', FAdSoyad);
  Result.AddPair('telefon', FTelefon);
  Result.AddPair('adres', FAdres);
  Result.AddPair('bakiye', TJSONNumber.Create(FBakiye));
  Result.AddPair('sonSiparisTarihi', DateToISO8601(FSonSiparisTarihi));
  Result.AddPair('toplamSiparis', TJSONNumber.Create(FToplamSiparis));
  Result.AddPair('toplamHarcama', TJSONNumber.Create(FToplamHarcama));
  Result.AddPair('durum', Ord(FDurum));
  Result.AddPair('latitude', TJSONNumber.Create(FLatitude));
  Result.AddPair('longitude', TJSONNumber.Create(FLongitude));
end;

procedure TCustomer.FromJSON(AJSON: TJSONObject);
var
  LValue: TJSONValue;
begin
  if AJSON.TryGetValue<TJSONValue>('id', LValue) then
    FId := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('adSoyad', LValue) then
    FAdSoyad := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('telefon', LValue) then
    FTelefon := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('adres', LValue) then
    FAdres := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('bakiye', LValue) then
    FBakiye := LValue.AsType<Double>;
  if AJSON.TryGetValue<TJSONValue>('sonSiparisTarihi', LValue) then
    FSonSiparisTarihi := ISO8601ToDate(LValue.AsType<string>);
  if AJSON.TryGetValue<TJSONValue>('toplamSiparis', LValue) then
    FToplamSiparis := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('toplamHarcama', LValue) then
    FToplamHarcama := LValue.AsType<Double>;
  if AJSON.TryGetValue<TJSONValue>('durum', LValue) then
    FDurum := TCustomerStatus(LValue.AsType<Integer>);
  if AJSON.TryGetValue<TJSONValue>('latitude', LValue) then
    FLatitude := LValue.AsType<Double>;
  if AJSON.TryGetValue<TJSONValue>('longitude', LValue) then
    FLongitude := LValue.AsType<Double>;
end;

function TCustomer.Clone: TCustomer;
begin
  Result := TCustomer.Create;
  Result.FId := FId;
  Result.FAdSoyad := FAdSoyad;
  Result.FTelefon := FTelefon;
  Result.FAdres := FAdres;
  Result.FBakiye := FBakiye;
  Result.FSonSiparisTarihi := FSonSiparisTarihi;
  Result.FToplamSiparis := FToplamSiparis;
  Result.FToplamHarcama := FToplamHarcama;
  Result.FDurum := FDurum;
  Result.FLatitude := FLatitude;
  Result.FLongitude := FLongitude;
end;

function TCustomer.GetFormattedBakiye: string;
begin
  Result := FormatFloat('#,##0.00', FBakiye) + ' ' + Chr($20BA);
end;

function TCustomer.GetFormattedToplamHarcama: string;
begin
  Result := FormatFloat('#,##0.00', FToplamHarcama) + ' ' + Chr($20BA);
end;

function TCustomer.GetInitials: string;
var
  LParts: TArray<string>;
begin
  Result := '';
  LParts := FAdSoyad.Split([' ']);
  if Length(LParts) > 0 then
    Result := UpperCase(Copy(LParts[0], 1, 1));
  if Length(LParts) > 1 then
    Result := Result + UpperCase(Copy(LParts[High(LParts)], 1, 1));
end;

function TCustomer.GetDurumText: string;
begin
  case FDurum of
    csKayitli: Result := 'Kay' + Chr($0131) + 'tl' + Chr($0131) + ' M' + Chr($00FC) + Chr($015F) + 'teri';
    csKayitsiz: Result := 'Kay' + Chr($0131) + 'ts' + Chr($0131) + 'z';
  end;
end;

function TCustomer.IsKayitli: Boolean;
begin
  Result := FDurum = csKayitli;
end;

end.
