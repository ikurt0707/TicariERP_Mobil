unit uDailySummary;

interface

uses
  System.SysUtils, System.Classes, System.JSON;

type
  TDailySummary = class
  private
    FTarih: TDateTime;
    FSiparisAdedi: Integer;
    FCiro: Currency;
    FTahsilat: Currency;
    FBorc: Currency;
    FTeslimEdilen: Integer;
    FIptalEdilen: Integer;
    FYeniMusteri: Integer;
  public
    constructor Create; overload;
    constructor Create(ATarih: TDateTime; ASiparisAdedi: Integer;
      ACiro, ATahsilat, ABorc: Currency); overload;

    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);

    function GetFormattedCiro: string;
    function GetFormattedTahsilat: string;
    function GetFormattedBorc: string;
    function GetFormattedTarih: string;
    function GetTahsilatOrani: Double;

    property Tarih: TDateTime read FTarih write FTarih;
    property SiparisAdedi: Integer read FSiparisAdedi write FSiparisAdedi;
    property Ciro: Currency read FCiro write FCiro;
    property Tahsilat: Currency read FTahsilat write FTahsilat;
    property Borc: Currency read FBorc write FBorc;
    property TeslimEdilen: Integer read FTeslimEdilen write FTeslimEdilen;
    property IptalEdilen: Integer read FIptalEdilen write FIptalEdilen;
    property YeniMusteri: Integer read FYeniMusteri write FYeniMusteri;
  end;

implementation

uses
  System.DateUtils;

{ TDailySummary }

constructor TDailySummary.Create;
begin
  inherited Create;
  FTarih := Now;
  FSiparisAdedi := 0;
  FCiro := 0;
  FTahsilat := 0;
  FBorc := 0;
  FTeslimEdilen := 0;
  FIptalEdilen := 0;
  FYeniMusteri := 0;
end;

constructor TDailySummary.Create(ATarih: TDateTime; ASiparisAdedi: Integer;
  ACiro, ATahsilat, ABorc: Currency);
begin
  Create;
  FTarih := ATarih;
  FSiparisAdedi := ASiparisAdedi;
  FCiro := ACiro;
  FTahsilat := ATahsilat;
  FBorc := ABorc;
end;

function TDailySummary.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('tarih', DateToISO8601(FTarih));
  Result.AddPair('siparisAdedi', TJSONNumber.Create(FSiparisAdedi));
  Result.AddPair('ciro', TJSONNumber.Create(FCiro));
  Result.AddPair('tahsilat', TJSONNumber.Create(FTahsilat));
  Result.AddPair('borc', TJSONNumber.Create(FBorc));
  Result.AddPair('teslimEdilen', TJSONNumber.Create(FTeslimEdilen));
  Result.AddPair('iptalEdilen', TJSONNumber.Create(FIptalEdilen));
  Result.AddPair('yeniMusteri', TJSONNumber.Create(FYeniMusteri));
end;

procedure TDailySummary.FromJSON(AJSON: TJSONObject);
var
  LValue: TJSONValue;
begin
  if AJSON.TryGetValue<TJSONValue>('tarih', LValue) then
    FTarih := ISO8601ToDate(LValue.AsType<string>);
  if AJSON.TryGetValue<TJSONValue>('siparisAdedi', LValue) then
    FSiparisAdedi := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('ciro', LValue) then
    FCiro := LValue.AsType<Double>;
  if AJSON.TryGetValue<TJSONValue>('tahsilat', LValue) then
    FTahsilat := LValue.AsType<Double>;
  if AJSON.TryGetValue<TJSONValue>('borc', LValue) then
    FBorc := LValue.AsType<Double>;
  if AJSON.TryGetValue<TJSONValue>('teslimEdilen', LValue) then
    FTeslimEdilen := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('iptalEdilen', LValue) then
    FIptalEdilen := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('yeniMusteri', LValue) then
    FYeniMusteri := LValue.AsType<Integer>;
end;

function TDailySummary.GetFormattedCiro: string;
begin
  Result := FormatFloat('#,##0', FCiro) + ' ' + Chr($20BA);
end;

function TDailySummary.GetFormattedTahsilat: string;
begin
  Result := FormatFloat('#,##0', FTahsilat) + ' ' + Chr($20BA);
end;

function TDailySummary.GetFormattedBorc: string;
begin
  Result := FormatFloat('#,##0', FBorc) + ' ' + Chr($20BA);
end;

function TDailySummary.GetFormattedTarih: string;
begin
  Result := FormatDateTime('dd.mm.yyyy', FTarih);
end;

function TDailySummary.GetTahsilatOrani: Double;
begin
  if FCiro > 0 then
    Result := (FTahsilat / FCiro) * 100
  else
    Result := 0;
end;

end.
