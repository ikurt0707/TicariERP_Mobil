unit uFrmYeniSiparis;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.Memo,
  System.Generics.Collections,
  uCustomer, uOrder, uProduct, uConstants;

type
  TFrmYeniSiparis = class(TForm)
  private
    FCustomer: TCustomer;
    FOrder: TOrder;
    FProducts: TObjectList<TProduct>;

    procedure LoadProducts;
    procedure SetupUI;
    procedure UpdateTotal;
    procedure ValidateOrder(out AIsValid: Boolean; out AErrorMsg: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetCustomer(ACustomer: TCustomer);
    procedure OnMiktarChange(AProductId: Integer; ANewMiktar: Integer);
    procedure OnSiparisiKaydetClick(Sender: TObject);
    procedure OnMusteriSecClick(Sender: TObject);

    function GetToplamTutar: Currency;
    function GetItemCount: Integer;

    property Customer: TCustomer read FCustomer;
    property Order: TOrder read FOrder;
  end;

var
  FrmYeniSiparis: TFrmYeniSiparis;

implementation

{$R *.fmx}

uses
  uOrderService, uApiService;

{ TFrmYeniSiparis }

constructor TFrmYeniSiparis.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCustomer := nil;
  FOrder := TOrder.Create;
  FProducts := TObjectList<TProduct>.Create(True);
  SetupUI;
  LoadProducts;
end;

destructor TFrmYeniSiparis.Destroy;
begin
  FOrder.Free;
  FProducts.Free;
  inherited;
end;

procedure TFrmYeniSiparis.SetupUI;
begin
  Caption := 'Yeni Siparis';
end;

procedure TFrmYeniSiparis.LoadProducts;
begin
  FProducts.Clear;
  // Default products from mockup
  FProducts.Add(TProduct.Create(1, 'Damacana Su', 60.00, 100, 'Adet'));
  FProducts.Add(TProduct.Create(2, 'Su Pompasi', 150.00, 50, 'Adet'));
  FProducts.Add(TProduct.Create(3, 'Bardak Su 200 ml', 1.00, 500, 'Adet'));
  FProducts.Add(TProduct.Create(4, 'Soda 330 ml', 2.50, 300, 'Adet'));
end;

procedure TFrmYeniSiparis.SetCustomer(ACustomer: TCustomer);
begin
  FCustomer := ACustomer;
  if Assigned(ACustomer) then
  begin
    FOrder.CustomerId := ACustomer.Id;
    FOrder.MusteriAdi := ACustomer.AdSoyad;
    FOrder.MusteriTelefon := ACustomer.Telefon;
    FOrder.MusteriAdres := ACustomer.Adres;
  end;
end;

procedure TFrmYeniSiparis.OnMiktarChange(AProductId: Integer; ANewMiktar: Integer);
var
  I: Integer;
  LProduct: TProduct;
  LItem: TOrderItem;
  LFound: Boolean;
begin
  LFound := False;
  LProduct := nil;

  // Find the product
  for I := 0 to FProducts.Count - 1 do
    if FProducts[I].Id = AProductId then
    begin
      LProduct := FProducts[I];
      Break;
    end;

  if not Assigned(LProduct) then
    Exit;

  // Update or add item in order
  for I := 0 to FOrder.Items.Count - 1 do
    if FOrder.Items[I].ProductId = AProductId then
    begin
      if ANewMiktar > 0 then
        FOrder.Items[I].Miktar := ANewMiktar
      else
        FOrder.RemoveItem(I);
      LFound := True;
      Break;
    end;

  if (not LFound) and (ANewMiktar > 0) then
  begin
    LItem := TOrderItem.Create(AProductId, LProduct.UrunAdi, ANewMiktar, LProduct.BirimFiyat);
    FOrder.AddItem(LItem);
  end;

  UpdateTotal;
end;

procedure TFrmYeniSiparis.UpdateTotal;
begin
  // Update UI with new total
end;

procedure TFrmYeniSiparis.ValidateOrder(out AIsValid: Boolean; out AErrorMsg: string);
begin
  AIsValid := True;
  AErrorMsg := '';

  if not Assigned(FCustomer) then
  begin
    AIsValid := False;
    AErrorMsg := 'Musteri secilmedi';
    Exit;
  end;

  if FOrder.Items.Count = 0 then
  begin
    AIsValid := False;
    AErrorMsg := 'En az bir urun ekleyin';
    Exit;
  end;

  if GetToplamTutar <= 0 then
  begin
    AIsValid := False;
    AErrorMsg := 'Siparis tutari 0 olamaz';
    Exit;
  end;
end;

procedure TFrmYeniSiparis.OnSiparisiKaydetClick(Sender: TObject);
var
  LIsValid: Boolean;
  LErrorMsg: string;
  LResponse: TApiResponse;
begin
  ValidateOrder(LIsValid, LErrorMsg);
  if not LIsValid then
  begin
    ShowMessage(LErrorMsg);
    Exit;
  end;

  LResponse := OrderService.CreateOrder(FOrder);
  try
    if LResponse.Success then
      ShowMessage('Siparis basariyla kaydedildi')
    else
      ShowMessage('Hata: ' + LResponse.ErrorMessage);
  finally
    LResponse.Free;
  end;
end;

procedure TFrmYeniSiparis.OnMusteriSecClick(Sender: TObject);
begin
  // Open customer selection
end;

function TFrmYeniSiparis.GetToplamTutar: Currency;
begin
  Result := FOrder.GetToplamTutar;
end;

function TFrmYeniSiparis.GetItemCount: Integer;
begin
  Result := FOrder.Items.Count;
end;

end.
