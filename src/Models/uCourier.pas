unit uCourier;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections;

type
  TCourierStatus = (crsAktif, crsPasif, crsMolada);

  TCourier = class
  private
    FId: Integer;
    FAdSoyad: string;
    FTelefon: string;
    FToplamSiparis: Integer;
    FTeslimEdilen: Integer;
    FYoldaki: Integer;
    FBekleyen: Integer;
    FLatitude: Double;
    FLongitude: Double;
    FDurum: TCourierStatus;
  public
    constructor Create; overload;
    constructor Create(AId: Integer; const AAdSoyad, ATelefon: string); overload;

    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);

    function GetTeslimOrani: Double;
    function GetFormattedTeslimOrani: string;
    function GetDurumText: string;

    property Id: Integer read FId write FId;
    property AdSoyad: string read FAdSoyad write FAdSoyad;
    property Telefon: string read FTelefon write FTelefon;
    property ToplamSiparis: Integer read FToplamSiparis write FToplamSiparis;
    property TeslimEdilen: Integer read FTeslimEdilen write FTeslimEdilen;
    property Yoldaki: Integer read FYoldaki write FYoldaki;
    property Bekleyen: Integer read FBekleyen write FBekleyen;
    property Latitude: Double read FLatitude write FLatitude;
    property Longitude: Double read FLongitude write FLongitude;
    property Durum: TCourierStatus read FDurum write FDurum;
  end;

  TCourierList = TObjectList<TCourier>;

implementation

{ TCourier }

constructor TCourier.Create;
begin
  inherited Create;
  FId := 0;
  FAdSoyad := '';
  FTelefon := '';
  FToplamSiparis := 0;
  FTeslimEdilen := 0;
  FYoldaki := 0;
  FBekleyen := 0;
  FLatitude := 0;
  FLongitude := 0;
  FDurum := crsAktif;
end;

constructor TCourier.Create(AId: Integer; const AAdSoyad, ATelefon: string);
begin
  Create;
  FId := AId;
  FAdSoyad := AAdSoyad;
  FTelefon := ATelefon;
end;

function TCourier.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(FId));
  Result.AddPair('adSoyad', FAdSoyad);
  Result.AddPair('telefon', FTelefon);
  Result.AddPair('toplamSiparis', TJSONNumber.Create(FToplamSiparis));
  Result.AddPair('teslimEdilen', TJSONNumber.Create(FTeslimEdilen));
  Result.AddPair('yoldaki', TJSONNumber.Create(FYoldaki));
  Result.AddPair('bekleyen', TJSONNumber.Create(FBekleyen));
  Result.AddPair('latitude', TJSONNumber.Create(FLatitude));
  Result.AddPair('longitude', TJSONNumber.Create(FLongitude));
  Result.AddPair('durum', TJSONNumber.Create(Ord(FDurum)));
end;

procedure TCourier.FromJSON(AJSON: TJSONObject);
var
  LValue: TJSONValue;
begin
  if AJSON.TryGetValue<TJSONValue>('id', LValue) then
    FId := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('adSoyad', LValue) then
    FAdSoyad := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('telefon', LValue) then
    FTelefon := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('toplamSiparis', LValue) then
    FToplamSiparis := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('teslimEdilen', LValue) then
    FTeslimEdilen := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('yoldaki', LValue) then
    FYoldaki := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('bekleyen', LValue) then
    FBekleyen := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('latitude', LValue) then
    FLatitude := LValue.AsType<Double>;
  if AJSON.TryGetValue<TJSONValue>('longitude', LValue) then
    FLongitude := LValue.AsType<Double>;
  if AJSON.TryGetValue<TJSONValue>('durum', LValue) then
    FDurum := TCourierStatus(LValue.AsType<Integer>);
end;

function TCourier.GetTeslimOrani: Double;
begin
  if FToplamSiparis > 0 then
    Result := (FTeslimEdilen / FToplamSiparis) * 100
  else
    Result := 0;
end;

function TCourier.GetFormattedTeslimOrani: string;
begin
  Result := '%' + FormatFloat('0', GetTeslimOrani);
end;

function TCourier.GetDurumText: string;
begin
  case FDurum of
    crsAktif: Result := 'Aktif';
    crsPasif: Result := 'Pasif';
    crsMolada: Result := 'Molada';
  end;
end;

end.
