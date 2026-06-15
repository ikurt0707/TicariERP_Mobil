unit uOrder;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  uProduct, uCustomer;

type
  TOrderStatus = (osHazirlaniyor, osYolda, osTeslimEdildi, osIptal);

  TOrderItem = class
  private
    FProductId: Integer;
    FUrunAdi: string;
    FMiktar: Integer;
    FBirimFiyat: Currency;
  public
    constructor Create; overload;
    constructor Create(AProductId: Integer; const AUrunAdi: string;
      AMiktar: Integer; ABirimFiyat: Currency); overload;

    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
    function GetToplam: Currency;
    function GetFormattedToplam: string;
    function GetOzet: string;

    property ProductId: Integer read FProductId write FProductId;
    property UrunAdi: string read FUrunAdi write FUrunAdi;
    property Miktar: Integer read FMiktar write FMiktar;
    property BirimFiyat: Currency read FBirimFiyat write FBirimFiyat;
  end;

  TOrderItemList = TObjectList<TOrderItem>;

  TOrder = class
  private
    FId: Integer;
    FCustomerId: Integer;
    FMusteriAdi: string;
    FMusteriTelefon: string;
    FMusteriAdres: string;
    FItems: TOrderItemList;
    FNot: string;
    FDurum: TOrderStatus;
    FOlusturmaTarihi: TDateTime;
    FTeslimTarihi: TDateTime;
    FKuryeId: Integer;
    FToplam: Currency;
    FDurumText: string;
  public
    constructor Create;
    destructor Destroy; override;

    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);

    function GetToplamTutar: Currency;
    function GetFormattedToplam: string;
    function GetDurumText: string;
    function GetDurumColor: Cardinal;
    function GetFormattedTarih: string;
    function GetItemsSummary: string;

    procedure AddItem(AItem: TOrderItem);
    procedure RemoveItem(AIndex: Integer);
    procedure ClearItems;

    property Id: Integer read FId write FId;
    property CustomerId: Integer read FCustomerId write FCustomerId;
    property MusteriAdi: string read FMusteriAdi write FMusteriAdi;
    property MusteriTelefon: string read FMusteriTelefon write FMusteriTelefon;
    property MusteriAdres: string read FMusteriAdres write FMusteriAdres;
    property Items: TOrderItemList read FItems;
    property Not_: string read FNot write FNot;
    property Durum: TOrderStatus read FDurum write FDurum;
    property OlusturmaTarihi: TDateTime read FOlusturmaTarihi write FOlusturmaTarihi;
    property TeslimTarihi: TDateTime read FTeslimTarihi write FTeslimTarihi;
    property KuryeId: Integer read FKuryeId write FKuryeId;
    property Toplam: Currency read FToplam write FToplam;
    property DurumText: string read FDurumText write FDurumText;
  end;

  TOrderList = TObjectList<TOrder>;

implementation

uses
  System.DateUtils;

{ TOrderItem }

constructor TOrderItem.Create;
begin
  inherited Create;
  FProductId := 0;
  FUrunAdi := '';
  FMiktar := 0;
  FBirimFiyat := 0;
end;

constructor TOrderItem.Create(AProductId: Integer; const AUrunAdi: string;
  AMiktar: Integer; ABirimFiyat: Currency);
begin
  Create;
  FProductId := AProductId;
  FUrunAdi := AUrunAdi;
  FMiktar := AMiktar;
  FBirimFiyat := ABirimFiyat;
end;

function TOrderItem.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('productId', TJSONNumber.Create(FProductId));
  Result.AddPair('urunAdi', FUrunAdi);
  Result.AddPair('miktar', TJSONNumber.Create(FMiktar));
  Result.AddPair('birimFiyat', TJSONNumber.Create(FBirimFiyat));
end;

procedure TOrderItem.FromJSON(AJSON: TJSONObject);
var
  LValue: TJSONValue;
begin
  if AJSON.TryGetValue<TJSONValue>('productId', LValue) then
    FProductId := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('urunAdi', LValue) then
    FUrunAdi := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('miktar', LValue) then
    FMiktar := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('birimFiyat', LValue) then
    FBirimFiyat := LValue.AsType<Double>;
end;

function TOrderItem.GetToplam: Currency;
begin
  Result := FMiktar * FBirimFiyat;
end;

function TOrderItem.GetFormattedToplam: string;
begin
  Result := FormatFloat('#,##0.00', GetToplam) + ' ' + Chr($20BA);
end;

function TOrderItem.GetOzet: string;
begin
  Result := Format('%d %s', [FMiktar, FUrunAdi]);
end;

{ TOrder }

constructor TOrder.Create;
begin
  inherited Create;
  FId := 0;
  FCustomerId := 0;
  FMusteriAdi := '';
  FMusteriTelefon := '';
  FMusteriAdres := '';
  FItems := TOrderItemList.Create(True);
  FNot := '';
  FDurum := osHazirlaniyor;
  FOlusturmaTarihi := Now;
  FTeslimTarihi := 0;
  FKuryeId := 0;
end;

destructor TOrder.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TOrder.ToJSON: TJSONObject;
var
  LItemsArr: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(FId));
  Result.AddPair('customerId', TJSONNumber.Create(FCustomerId));
  Result.AddPair('musteriAdi', FMusteriAdi);
  Result.AddPair('musteriTelefon', FMusteriTelefon);
  Result.AddPair('musteriAdres', FMusteriAdres);
  Result.AddPair('not', FNot);
  Result.AddPair('durum', TJSONNumber.Create(Ord(FDurum)));
  Result.AddPair('olusturmaTarihi', DateToISO8601(FOlusturmaTarihi));
  if FTeslimTarihi > 0 then
    Result.AddPair('teslimTarihi', DateToISO8601(FTeslimTarihi));
  Result.AddPair('kuryeId', TJSONNumber.Create(FKuryeId));

  LItemsArr := TJSONArray.Create;
  for I := 0 to FItems.Count - 1 do
    LItemsArr.AddElement(FItems[I].ToJSON);
  Result.AddPair('items', LItemsArr);
end;

procedure TOrder.FromJSON(AJSON: TJSONObject);
var
  LValue: TJSONValue;
  LItemsArr: TJSONArray;
  I: Integer;
  LItem: TOrderItem;
begin
  if AJSON.TryGetValue<TJSONValue>('id', LValue) then
    FId := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('customerId', LValue) then
    FCustomerId := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('musteriAdi', LValue) then
    FMusteriAdi := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('musteriTelefon', LValue) then
    FMusteriTelefon := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('musteriAdres', LValue) then
    FMusteriAdres := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('not', LValue) then
    FNot := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('durum', LValue) then
    FDurum := TOrderStatus(LValue.AsType<Integer>);
  if AJSON.TryGetValue<TJSONValue>('olusturmaTarihi', LValue) then
    FOlusturmaTarihi := ISO8601ToDate(LValue.AsType<string>);
  if AJSON.TryGetValue<TJSONValue>('teslimTarihi', LValue) then
    FTeslimTarihi := ISO8601ToDate(LValue.AsType<string>);
  if AJSON.TryGetValue<TJSONValue>('kuryeId', LValue) then
    FKuryeId := LValue.AsType<Integer>;

  FItems.Clear;
  if AJSON.TryGetValue<TJSONArray>('items', LItemsArr) then
  begin
    for I := 0 to LItemsArr.Count - 1 do
    begin
      LItem := TOrderItem.Create;
      LItem.FromJSON(LItemsArr.Items[I] as TJSONObject);
      FItems.Add(LItem);
    end;
  end;
end;

function TOrder.GetToplamTutar: Currency;
var
  I: Integer;
begin
  if FToplam > 0 then
    Result := FToplam
  else
  begin
    Result := 0;
    for I := 0 to FItems.Count - 1 do
      Result := Result + FItems[I].GetToplam;
  end;
end;

function TOrder.GetFormattedToplam: string;
begin
  Result := FormatFloat('#,##0.00', GetToplamTutar) + ' ' + Chr($20BA);
end;

function TOrder.GetDurumText: string;
begin
  if FDurumText <> '' then
  begin
    Result := FDurumText;
    Exit;
  end;
  case FDurum of
    osHazirlaniyor: Result := 'Haz' + Chr($0131) + 'rlan' + Chr($0131) + 'yor';
    osYolda: Result := 'Yolda';
    osTeslimEdildi: Result := 'Teslim Edildi';
    osIptal: Result := Chr($0130) + 'ptal';
  end;
end;

function TOrder.GetDurumColor: Cardinal;
begin
  case FDurum of
    osHazirlaniyor: Result := $FFFF9800; // Orange
    osYolda: Result := $FF2196F3;        // Blue
    osTeslimEdildi: Result := $FF4CAF50; // Green
    osIptal: Result := $FFF44336;        // Red
  else
    Result := $FF9E9E9E;                 // Grey
  end;
end;

function TOrder.GetFormattedTarih: string;
begin
  Result := FormatDateTime('dd.mm.yyyy', FOlusturmaTarihi);
end;

function TOrder.GetItemsSummary: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FItems.Count - 1 do
  begin
    if I > 0 then
      Result := Result + ' + ';
    Result := Result + FItems[I].GetOzet;
  end;
end;

procedure TOrder.AddItem(AItem: TOrderItem);
begin
  FItems.Add(AItem);
end;

procedure TOrder.RemoveItem(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FItems.Count) then
    FItems.Delete(AIndex);
end;

procedure TOrder.ClearItems;
begin
  FItems.Clear;
end;

end.
