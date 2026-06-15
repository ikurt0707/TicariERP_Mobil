unit uProduct;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections;

type
  TProduct = class
  private
    FId: Integer;
    FUrunAdi: string;
    FBirimFiyat: Currency;
    FStokMiktari: Integer;
    FBirim: string;
    FAktif: Boolean;
  public
    constructor Create; overload;
    constructor Create(AId: Integer; const AUrunAdi: string; ABirimFiyat: Currency;
      AStokMiktari: Integer; const ABirim: string); overload;

    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
    function Clone: TProduct;

    function GetFormattedFiyat: string;
    function IsStokYeterli(AMiktar: Integer): Boolean;

    property Id: Integer read FId write FId;
    property UrunAdi: string read FUrunAdi write FUrunAdi;
    property BirimFiyat: Currency read FBirimFiyat write FBirimFiyat;
    property StokMiktari: Integer read FStokMiktari write FStokMiktari;
    property Birim: string read FBirim write FBirim;
    property Aktif: Boolean read FAktif write FAktif;
  end;

  TProductList = TObjectList<TProduct>;

implementation

{ TProduct }

constructor TProduct.Create;
begin
  inherited Create;
  FId := 0;
  FUrunAdi := '';
  FBirimFiyat := 0;
  FStokMiktari := 0;
  FBirim := 'Adet';
  FAktif := True;
end;

constructor TProduct.Create(AId: Integer; const AUrunAdi: string; ABirimFiyat: Currency;
  AStokMiktari: Integer; const ABirim: string);
begin
  Create;
  FId := AId;
  FUrunAdi := AUrunAdi;
  FBirimFiyat := ABirimFiyat;
  FStokMiktari := AStokMiktari;
  FBirim := ABirim;
end;

function TProduct.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(FId));
  Result.AddPair('urunAdi', FUrunAdi);
  Result.AddPair('birimFiyat', TJSONNumber.Create(FBirimFiyat));
  Result.AddPair('stokMiktari', TJSONNumber.Create(FStokMiktari));
  Result.AddPair('birim', FBirim);
  Result.AddPair('aktif', TJSONBool.Create(FAktif));
end;

procedure TProduct.FromJSON(AJSON: TJSONObject);
var
  LValue: TJSONValue;
begin
  if AJSON.TryGetValue<TJSONValue>('id', LValue) then
    FId := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('urunAdi', LValue) then
    FUrunAdi := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('birimFiyat', LValue) then
    FBirimFiyat := LValue.AsType<Double>;
  if AJSON.TryGetValue<TJSONValue>('stokMiktari', LValue) then
    FStokMiktari := LValue.AsType<Integer>;
  if AJSON.TryGetValue<TJSONValue>('birim', LValue) then
    FBirim := LValue.AsType<string>;
  if AJSON.TryGetValue<TJSONValue>('aktif', LValue) then
    FAktif := LValue.AsType<Boolean>;
end;

function TProduct.Clone: TProduct;
begin
  Result := TProduct.Create;
  Result.FId := FId;
  Result.FUrunAdi := FUrunAdi;
  Result.FBirimFiyat := FBirimFiyat;
  Result.FStokMiktari := FStokMiktari;
  Result.FBirim := FBirim;
  Result.FAktif := FAktif;
end;

function TProduct.GetFormattedFiyat: string;
begin
  Result := FormatFloat('#,##0.00', FBirimFiyat) + ' ' + Chr($20BA);
end;

function TProduct.IsStokYeterli(AMiktar: Integer): Boolean;
begin
  Result := FStokMiktari >= AMiktar;
end;

end.
