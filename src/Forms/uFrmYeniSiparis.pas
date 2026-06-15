unit uFrmYeniSiparis;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON,
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
    FAramaLogID: Integer;
    FCariID: Integer;
    procedure UpdateTotal;
    procedure UpdateQuantityLabel(AIndex: Integer);
    procedure ChangeQuantity(AIndex, ADelta: Integer);
    function ValidateOrder: Boolean;
    function GetToplamTutar: Currency;
    procedure LoadProductsFromServer;
    procedure OnMusteriSelected(ACariID: Integer; const ACariAdi, ATelefon: string);
  public
    procedure SetCustomer(ACustomer: TCustomer);
    procedure SetFromIncomingCall(AAramaLogID: Integer; const ATelefon, ACariAdi: string);
    procedure ResetForm;
    property ToplamTutar: Currency read GetToplamTutar;
  end;

var
  FrmYeniSiparis: TFrmYeniSiparis;

implementation

{$R *.fmx}

uses
  uApiService, uHelpers, uFrmMusteriSec;

procedure TFrmYeniSiparis.FormCreate(Sender: TObject);
begin
  FCustomer := nil;
  FAramaLogID := 0;
  FCariID := 0;
  FQuantities[0] := 0;
  FQuantities[1] := 0;
  FQuantities[2] := 0;
  FQuantities[3] := 0;
  LoadProductsFromServer;
end;

procedure TFrmYeniSiparis.FormDestroy(Sender: TObject);
begin
  if Assigned(FCustomer) then
    FCustomer.Free;
end;

procedure TFrmYeniSiparis.LoadProductsFromServer;
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LObj: TJSONObject;
  I: Integer;
  LLabels: array[0..3] of TLabel;
  LPriceLabels: array[0..3] of TLabel;
begin
  LLabels[0] := LblProduct1Name;
  LLabels[1] := LblProduct2Name;
  LLabels[2] := LblProduct3Name;
  LLabels[3] := LblProduct4Name;
  LPriceLabels[0] := LblProduct1Price;
  LPriceLabels[1] := LblProduct2Price;
  LPriceLabels[2] := LblProduct3Price;
  LPriceLabels[3] := LblProduct4Price;

  LResponse := ApiService.Get('rest/TSmStok/GetHizliSiparisUrunler/');
  try
    if LResponse.Success and Assigned(LResponse.Data) and (LResponse.Data is TJSONObject) then
    begin
      LData := TJSONObject(LResponse.Data);
      if LData.TryGetValue<TJSONArray>('data', LArray) then
      begin
        for I := 0 to Min(LArray.Count - 1, 3) do
        begin
          LObj := LArray.Items[I] as TJSONObject;
          LLabels[I].Text := LObj.GetValue<string>('stokAdi', '');
          FPrices[I] := LObj.GetValue<Double>('satisFiyat', 0);
          LPriceLabels[I].Text := THelpers.FormatCurrency(FPrices[I]);
        end;
      end;
    end
    else
    begin
      // Fallback defaults
      FPrices[0] := 60.00;
      FPrices[1] := 150.00;
      FPrices[2] := 1.00;
      FPrices[3] := 2.50;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TFrmYeniSiparis.SetCustomer(ACustomer: TCustomer);
begin
  if Assigned(FCustomer) then
    FreeAndNil(FCustomer);
  FCustomer := ACustomer.Clone;
  FCariID := FCustomer.Id;
  LblMusteriAdi.Text := FCustomer.AdSoyad;
end;

procedure TFrmYeniSiparis.SetFromIncomingCall(AAramaLogID: Integer;
  const ATelefon, ACariAdi: string);
begin
  ResetForm;
  FAramaLogID := AAramaLogID;
  LblMusteriAdi.Text := ACariAdi;
  if ACariAdi = '' then
    LblMusteriAdi.Text := ATelefon + ' (Kayitsiz)';
  LblHeaderTitle.Text := 'Yeni Siparis (Gelen Cagri)';
end;

procedure TFrmYeniSiparis.ResetForm;
var
  I: Integer;
begin
  FAramaLogID := 0;
  FCariID := 0;
  if Assigned(FCustomer) then
    FreeAndNil(FCustomer);
  for I := 0 to 3 do
  begin
    FQuantities[I] := 0;
    UpdateQuantityLabel(I);
  end;
  MemoNot.Text := '';
  LblMusteriAdi.Text := 'Musteri seciniz';
  LblHeaderTitle.Text := 'Yeni Siparis';
  UpdateTotal;
end;

procedure TFrmYeniSiparis.OnMusteriSelected(ACariID: Integer;
  const ACariAdi, ATelefon: string);
begin
  FCariID := ACariID;
  LblMusteriAdi.Text := ACariAdi;
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

  Result := (FCariID > 0) and LHasItem;
end;

procedure TFrmYeniSiparis.BtnBackClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmYeniSiparis.BtnMusteriSecClick(Sender: TObject);
begin
  FrmMusteriSec.OnMusteriSelected := OnMusteriSelected;
  FrmMusteriSec.Show;
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
  LBody: TJSONObject;
  LItems: TJSONArray;
  LItem: TJSONObject;
  LResponse: TApiResponse;
  I: Integer;
  LNames: array[0..3] of string;
begin
  if not ValidateOrder then
  begin
    ShowMessage('Lutfen musteri secin ve en az bir urun ekleyin.');
    Exit;
  end;

  LNames[0] := LblProduct1Name.Text;
  LNames[1] := LblProduct2Name.Text;
  LNames[2] := LblProduct3Name.Text;
  LNames[3] := LblProduct4Name.Text;

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('cariId', TJSONNumber.Create(FCariID));
    LBody.AddPair('aciklama', MemoNot.Text);
    LBody.AddPair('siparisKaynak', 'Mobil');

    if FAramaLogID > 0 then
    begin
      LBody.AddPair('aramaLogId', TJSONNumber.Create(FAramaLogID));
      LBody.AddPair('siparisKaynak', 'CallerID');
    end;

    LItems := TJSONArray.Create;
    for I := 0 to 3 do
    begin
      if FQuantities[I] > 0 then
      begin
        LItem := TJSONObject.Create;
        LItem.AddPair('stokAdi', LNames[I]);
        LItem.AddPair('miktar', TJSONNumber.Create(FQuantities[I]));
        LItem.AddPair('birimFiyat', TJSONNumber.Create(Double(FPrices[I])));
        LItems.AddElement(LItem);
      end;
    end;
    LBody.AddPair('items', LItems);

    LResponse := ApiService.Post('rest/TSmSiparis/CreateSiparis/', LBody);
    try
      if LResponse.Success then
      begin
        ShowMessage('Siparis basariyla kaydedildi!');
        ResetForm;
        Close;
      end
      else
        ShowMessage('Hata: ' + LResponse.ErrorMessage);
    finally
      LResponse.Free;
    end;
  finally
    LBody.Free;
  end;
end;

end.
