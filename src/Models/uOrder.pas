unit uOrder;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  uProduct, uCustomer;

type
  TOrderStatus = (osBeklemede, osTeslimEdildi, osIptal);

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

  TOrder = class
  private
    FId: Integer;
    FMusteriAdi: string;
    FMusteriTelefon: string;
    FMusteriAdres: string;
    FDurum: TOrderStatus;
    FDurumText: string;
    FItems: TObjectList<TOrderItem>;
    FToplam: Currency;
    FAciklama: string;
    FTarih: TDateTime;
    FAramaLogID: Integer;
    FCariID: Integer;
    FSiparisKaynak: string;
  public
    constructor Create;
    destructor Destroy; override;

    function GetDurumText: string;
    function GetDurumColor: Cardinal;
    function GetFormattedToplam: string;
    function GetFormattedTarih: string;
    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);

    property Id: Integer read FId write FId;
    property MusteriAdi: string read FMusteriAdi write FMusteriAdi;
    property MusteriTelefon: string read FMusteriTelefon write FMusteriTelefon;
    property MusteriAdres: string read FMusteriAdres write FMusteriAdres;
    property Durum: TOrderStatus read FDurum write FDurum;
    property DurumText: string read FDurumText write FDurumText;
    property Items: TObjectList<TOrderItem> read FItems;
    property Toplam: Currency read FToplam write FToplam;
    property Aciklama: string read FAciklama write FAciklama;
    property Tarih: TDateTime read FTarih write FTarih;
    property AramaLogID: Integer read FAramaLogID write FAramaLogID;
    property CariID: Integer read FCariID write FCariID;
    property SiparisKaynak: string read FSiparisKaynak write FSiparisKaynak;
  end;

  TOrderList = TObjectList<TOrder>;

implementation

uses
  uConstants;

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
  inherited Create;
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
  Result.AddPair('birimFiyat', TJSONNumber.Create(Double(FBirimFiyat)));
end;

procedure TOrderItem.FromJSON(AJSON: TJSONObject);
begin
  FProductId := AJSON.GetValue<Integer>('productId', 0);
  FUrunAdi := AJSON.GetValue<string>('urunAdi', '');
  FMiktar := AJSON.GetValue<Integer>('miktar', 0);
  FBirimFiyat := AJSON.GetValue<Double>('birimFiyat', 0);
end;

function TOrderItem.GetToplam: Currency;
begin
  Result := FMiktar * FBirimFiyat;
end;

function TOrderItem.GetFormattedToplam: string;
begin
  Result := FormatFloat('#,##0.00 TL', GetToplam);
end;

function TOrderItem.GetOzet: string;
begin
  Result := Format('%s x%d', [FUrunAdi, FMiktar]);
end;

{ TOrder }

constructor TOrder.Create;
begin
  inherited Create;
  FId := 0;
  FMusteriAdi := '';
  FMusteriTelefon := '';
  FMusteriAdres := '';
  FDurum := osBeklemede;
  FDurumText := '';
  FItems := TObjectList<TOrderItem>.Create(True);
  FToplam := 0;
  FAciklama := '';
  FTarih := Now;
  FAramaLogID := 0;
  FCariID := 0;
  FSiparisKaynak := 'Mobil';
end;

destructor TOrder.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TOrder.GetDurumText: string;
begin
  if FDurumText <> '' then
  begin
    Result := FDurumText;
    Exit;
  end;
  case FDurum of
    osBeklemede: Result := 'Beklemede';
    osTeslimEdildi: Result := 'Teslim Edildi';
    osIptal: Result := 'Iptal';
  else
    Result := 'Beklemede';
  end;
end;

function TOrder.GetDurumColor: Cardinal;
begin
  case FDurum of
    osBeklemede: Result := COLOR_STATUS_BEKLEMEDE;
    osTeslimEdildi: Result := COLOR_STATUS_TESLIM;
    osIptal: Result := COLOR_STATUS_IPTAL;
  else
    Result := COLOR_STATUS_BEKLEMEDE;
  end;
end;

function TOrder.GetFormattedToplam: string;
begin
  Result := FormatFloat('#,##0.00 TL', FToplam);
end;

function TOrder.GetFormattedTarih: string;
begin
  if FTarih = 0 then
    Result := ''
  else
    Result := FormatDateTime('dd.mm.yyyy hh:nn', FTarih);
end;

function TOrder.ToJSON: TJSONObject;
var
  LItems: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('cariId', TJSONNumber.Create(FCariID));
  Result.AddPair('aciklama', FAciklama);
  Result.AddPair('siparisKaynak', FSiparisKaynak);
  if FAramaLogID > 0 then
    Result.AddPair('aramaLogId', TJSONNumber.Create(FAramaLogID));
  LItems := TJSONArray.Create;
  for I := 0 to FItems.Count - 1 do
    LItems.AddElement(FItems[I].ToJSON);
  Result.AddPair('items', LItems);
end;

procedure TOrder.FromJSON(AJSON: TJSONObject);
var
  LDurumStr: string;
begin
  FId := AJSON.GetValue<Integer>('siparisId', 0);
  FMusteriAdi := AJSON.GetValue<string>('cariAdi', '');
  FMusteriTelefon := AJSON.GetValue<string>('telefon', '');
  FMusteriAdres := AJSON.GetValue<string>('adres', '');
  FToplam := AJSON.GetValue<Double>('genelToplam', 0);
  LDurumStr := AJSON.GetValue<string>('durum', 'Beklemede');
  FDurumText := LDurumStr;
  if LDurumStr = 'Teslim Edildi' then
    FDurum := osTeslimEdildi
  else if LDurumStr = 'Iptal' then
    FDurum := osIptal
  else
    FDurum := osBeklemede;
end;

end.
