unit uFrmYeniSiparis;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Memo,
  System.Generics.Collections,
  uCustomer, uOrder, uProduct, uConstants;

type
  TFrmYeniSiparis = class(TForm)
    LayoutMain: TLayout;
    LayoutHeader: TLayout;
    RectHeader: TRectangle;
    BtnBack: TSpeedButton;
    LblHeaderTitle: TLabel;
    ScrollContent: TVertScrollBox;
    LayoutMusteriSec: TLayout;
    RectMusteriSec: TRectangle;
    LayoutMusteriInfo: TLayout;
    LblMusteriLabel: TLabel;
    LblMusteriAdi: TLabel;
    BtnMusteriSec: TSpeedButton;
    LayoutProducts: TLayout;
    LblUrunlerTitle: TLabel;
    RectProductList: TRectangle;
    LayoutProduct1: TLayout;
    LblProduct1Name: TLabel;
    LblProduct1Price: TLabel;
    LayoutProduct1Qty: TLayout;
    BtnProduct1Minus: TCornerButton;
    LblProduct1Qty: TLabel;
    BtnProduct1Plus: TCornerButton;
    Line1: TLine;
    LayoutProduct2: TLayout;
    LblProduct2Name: TLabel;
    LblProduct2Price: TLabel;
    LayoutProduct2Qty: TLayout;
    BtnProduct2Minus: TCornerButton;
    LblProduct2Qty: TLabel;
    BtnProduct2Plus: TCornerButton;
    Line2: TLine;
    LayoutProduct3: TLayout;
    LblProduct3Name: TLabel;
    LblProduct3Price: TLabel;
    LayoutProduct3Qty: TLayout;
    BtnProduct3Minus: TCornerButton;
    LblProduct3Qty: TLabel;
    BtnProduct3Plus: TCornerButton;
    Line3: TLine;
    LayoutProduct4: TLayout;
    LblProduct4Name: TLabel;
    LblProduct4Price: TLabel;
    LayoutProduct4Qty: TLayout;
    BtnProduct4Minus: TCornerButton;
    LblProduct4Qty: TLabel;
    BtnProduct4Plus: TCornerButton;
    LayoutNot: TLayout;
    LblNotTitle: TLabel;
    RectNot: TRectangle;
    MemoNot: TMemo;
    LayoutFooter: TLayout;
    RectFooter: TRectangle;
    LayoutTotal: TLayout;
    LblToplamLabel: TLabel;
    LblToplamTutar: TLabel;
    BtnSiparisiKaydet: TCornerButton;
    procedure BtnBackClick(Sender: TObject);
    procedure BtnMusteriSecClick(Sender: TObject);
    procedure BtnProduct1MinusClick(Sender: TObject);
    procedure BtnProduct1PlusClick(Sender: TObject);
    procedure BtnProduct2MinusClick(Sender: TObject);
    procedure BtnProduct2PlusClick(Sender: TObject);
    procedure BtnProduct3MinusClick(Sender: TObject);
    procedure BtnProduct3PlusClick(Sender: TObject);
    procedure BtnProduct4MinusClick(Sender: TObject);
    procedure BtnProduct4PlusClick(Sender: TObject);
    procedure BtnSiparisiKaydetClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FCustomer: TCustomer;
    FQuantities: array[0..3] of Integer;
    FPrices: array[0..3] of Currency;
    procedure UpdateTotal;
    procedure UpdateQuantityLabel(AIndex: Integer);
    procedure ChangeQuantity(AIndex, ADelta: Integer);
    function ValidateOrder: Boolean;
    function GetToplamTutar: Currency;
  public
    procedure SetCustomer(ACustomer: TCustomer);
    property ToplamTutar: Currency read GetToplamTutar;
  end;

var
  FrmYeniSiparis: TFrmYeniSiparis;

implementation

{$R *.fmx}

uses
  uOrderService, uHelpers;

procedure TFrmYeniSiparis.FormCreate(Sender: TObject);
begin
  FCustomer := nil;
  FQuantities[0] := 0;
  FQuantities[1] := 0;
  FQuantities[2] := 0;
  FQuantities[3] := 0;
  FPrices[0] := 60.00;   // Damacana Su
  FPrices[1] := 150.00;  // Su Pompasi
  FPrices[2] := 1.00;    // Bardak Su 200ml
  FPrices[3] := 2.50;    // Soda 330ml
end;

procedure TFrmYeniSiparis.FormDestroy(Sender: TObject);
begin
  if Assigned(FCustomer) then
    FCustomer.Free;
end;

procedure TFrmYeniSiparis.SetCustomer(ACustomer: TCustomer);
begin
  if Assigned(FCustomer) then
    FreeAndNil(FCustomer);
  FCustomer := ACustomer.Clone;
  LblMusteriAdi.Text := FCustomer.AdSoyad;
end;

procedure TFrmYeniSiparis.ChangeQuantity(AIndex, ADelta: Integer);
begin
  FQuantities[AIndex] := FQuantities[AIndex] + ADelta;
  if FQuantities[AIndex] < 0 then
    FQuantities[AIndex] := 0;
  UpdateQuantityLabel(AIndex);
  UpdateTotal;
end;

procedure TFrmYeniSiparis.UpdateQuantityLabel(AIndex: Integer);
begin
  case AIndex of
    0: LblProduct1Qty.Text := IntToStr(FQuantities[0]);
    1: LblProduct2Qty.Text := IntToStr(FQuantities[1]);
    2: LblProduct3Qty.Text := IntToStr(FQuantities[2]);
    3: LblProduct4Qty.Text := IntToStr(FQuantities[3]);
  end;
end;

procedure TFrmYeniSiparis.UpdateTotal;
begin
  LblToplamTutar.Text := THelpers.FormatCurrency(GetToplamTutar);
end;

function TFrmYeniSiparis.GetToplamTutar: Currency;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 3 do
    Result := Result + (FQuantities[I] * FPrices[I]);
end;

function TFrmYeniSiparis.ValidateOrder: Boolean;
var
  I: Integer;
  LHasItem: Boolean;
begin
  LHasItem := False;
  for I := 0 to 3 do
    if FQuantities[I] > 0 then
    begin
      LHasItem := True;
      Break;
    end;

  Result := Assigned(FCustomer) and LHasItem;
end;

procedure TFrmYeniSiparis.BtnBackClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmYeniSiparis.BtnMusteriSecClick(Sender: TObject);
begin
  // Open customer selection dialog
end;

procedure TFrmYeniSiparis.BtnProduct1MinusClick(Sender: TObject);
begin
  ChangeQuantity(0, -1);
end;

procedure TFrmYeniSiparis.BtnProduct1PlusClick(Sender: TObject);
begin
  ChangeQuantity(0, 1);
end;

procedure TFrmYeniSiparis.BtnProduct2MinusClick(Sender: TObject);
begin
  ChangeQuantity(1, -1);
end;

procedure TFrmYeniSiparis.BtnProduct2PlusClick(Sender: TObject);
begin
  ChangeQuantity(1, 1);
end;

procedure TFrmYeniSiparis.BtnProduct3MinusClick(Sender: TObject);
begin
  ChangeQuantity(2, -1);
end;

procedure TFrmYeniSiparis.BtnProduct3PlusClick(Sender: TObject);
begin
  ChangeQuantity(2, 1);
end;

procedure TFrmYeniSiparis.BtnProduct4MinusClick(Sender: TObject);
begin
  ChangeQuantity(3, -1);
end;

procedure TFrmYeniSiparis.BtnProduct4PlusClick(Sender: TObject);
begin
  ChangeQuantity(3, 1);
end;

procedure TFrmYeniSiparis.BtnSiparisiKaydetClick(Sender: TObject);
var
  LOrder: TOrder;
begin
  if not ValidateOrder then
  begin
    ShowMessage('Lutfen musteri secin ve en az bir urun ekleyin.');
    Exit;
  end;

  LOrder := TOrder.Create;
  try
    LOrder.CustomerId := FCustomer.Id;
    LOrder.MusteriAdi := FCustomer.AdSoyad;
    LOrder.MusteriTelefon := FCustomer.Telefon;
    LOrder.MusteriAdres := FCustomer.Adres;
    LOrder.Not_ := MemoNot.Text;
    LOrder.Durum := osHazirlaniyor;
    LOrder.OlusturmaTarihi := Now;

    if FQuantities[0] > 0 then
      LOrder.AddItem(TOrderItem.Create(1, 'Damacana Su', FQuantities[0], FPrices[0]));
    if FQuantities[1] > 0 then
      LOrder.AddItem(TOrderItem.Create(2, 'Su Pompasi', FQuantities[1], FPrices[1]));
    if FQuantities[2] > 0 then
      LOrder.AddItem(TOrderItem.Create(3, 'Bardak Su 200ml', FQuantities[2], FPrices[2]));
    if FQuantities[3] > 0 then
      LOrder.AddItem(TOrderItem.Create(4, 'Soda 330ml', FQuantities[3], FPrices[3]));

    OrderService.CreateOrder(LOrder);
    ShowMessage('Siparis basariyla kaydedildi!');
    Close;
  finally
    LOrder.Free;
  end;
end;

end.
