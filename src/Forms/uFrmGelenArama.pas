unit uFrmGelenArama;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  System.Generics.Collections,
  uCustomer, uOrder, uConstants;

type
  TFrmGelenArama = class(TForm)
    LayoutMain: TLayout;
    LayoutHeader: TLayout;
    RectHeader: TRectangle;
    BtnBack: TSpeedButton;
    LblHeaderTitle: TLabel;
    ScrollContent: TVertScrollBox;
    LayoutCustomerCard: TLayout;
    RectCustomerCard: TRectangle;
    LayoutCustomerTop: TLayout;
    CircleAvatar: TCircle;
    LblAvatar: TLabel;
    LayoutCustomerInfo: TLayout;
    LblCustomerName: TLabel;
    LblCustomerPhone: TLabel;
    RectKayitliTag: TRectangle;
    LblKayitliTag: TLabel;
    LayoutCustomerDetails: TGridPanelLayout;
    LayoutBakiye: TLayout;
    LblBakiyeTitle: TLabel;
    LblBakiyeValue: TLabel;
    LayoutSonSiparis: TLayout;
    LblSonSiparisTitle: TLabel;
    LblSonSiparisValue: TLabel;
    LayoutToplamHarcama: TLayout;
    LblToplamHarcamaTitle: TLabel;
    LblToplamHarcamaValue: TLabel;
    LayoutToplamSiparis: TLayout;
    LblToplamSiparisTitle: TLabel;
    LblToplamSiparisValue: TLabel;
    LayoutActionButtons: TLayout;
    BtnSiparisAc: TCornerButton;
    BtnWhatsApp: TCornerButton;
    BtnAra: TCornerButton;
    BtnHaritadaGoster: TCornerButton;
    LayoutSonSiparisler: TLayout;
    LayoutSonSipHeader: TLayout;
    LblSonSiparislerTitle: TLabel;
    BtnTumu: TSpeedButton;
    ListViewSonSiparisler: TListView;
    BtnAramayiKaydet: TCornerButton;
    procedure BtnBackClick(Sender: TObject);
    procedure BtnSiparisAcClick(Sender: TObject);
    procedure BtnWhatsAppClick(Sender: TObject);
    procedure BtnAraClick(Sender: TObject);
    procedure BtnHaritadaGosterClick(Sender: TObject);
    procedure BtnAramayiKaydetClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FCustomer: TCustomer;
    FRecentOrders: TOrderList;
    FPhoneNumber: string;
    procedure LoadCustomerByPhone(const APhone: string);
    procedure LoadRecentOrders;
    procedure UpdateCustomerUI;
    procedure UpdateOrdersUI;
  public
    procedure ShowForPhone(const APhone: string);
    property Customer: TCustomer read FCustomer;
    property PhoneNumber: string read FPhoneNumber;
  end;

var
  FrmGelenArama: TFrmGelenArama;

implementation

{$R *.fmx}

uses
  uCustomerService, uOrderService, uHelpers;

procedure TFrmGelenArama.FormCreate(Sender: TObject);
begin
  FCustomer := nil;
  FRecentOrders := TOrderList.Create(True);
  FPhoneNumber := '';
end;

procedure TFrmGelenArama.FormDestroy(Sender: TObject);
begin
  if Assigned(FCustomer) then
    FCustomer.Free;
  FRecentOrders.Free;
end;

procedure TFrmGelenArama.ShowForPhone(const APhone: string);
begin
  FPhoneNumber := APhone;
  LoadCustomerByPhone(APhone);
  LoadRecentOrders;
  UpdateCustomerUI;
  UpdateOrdersUI;
end;

procedure TFrmGelenArama.LoadCustomerByPhone(const APhone: string);
begin
  if Assigned(FCustomer) then
    FreeAndNil(FCustomer);
  FCustomer := CustomerService.GetCustomerByPhone(APhone);
end;

procedure TFrmGelenArama.LoadRecentOrders;
begin
  FRecentOrders.Clear;
  if Assigned(FCustomer) then
  begin
    FRecentOrders.Free;
    FRecentOrders := OrderService.GetOrdersByCustomer(FCustomer.Id);
  end;
end;

procedure TFrmGelenArama.UpdateCustomerUI;
begin
  if Assigned(FCustomer) then
  begin
    LblCustomerName.Text := FCustomer.AdSoyad;
    LblCustomerPhone.Text := THelpers.FormatPhone(FCustomer.Telefon);
    LblAvatar.Text := FCustomer.GetInitials;
    LblBakiyeValue.Text := FCustomer.GetFormattedBakiye;
    LblSonSiparisValue.Text := THelpers.DateToDisplayStr(FCustomer.SonSiparisTarihi);
    LblToplamHarcamaValue.Text := FCustomer.GetFormattedToplamHarcama;
    LblToplamSiparisValue.Text := IntToStr(FCustomer.ToplamSiparis);

    if FCustomer.IsKayitli then
    begin
      LblKayitliTag.Text := 'Kayitli Musteri';
      RectKayitliTag.Fill.Color := TAlphaColorRec.Create($FFE8F5E9);
      LblKayitliTag.TextSettings.FontColor := TAlphaColorRec.Create($FF4CAF50);
    end
    else
    begin
      LblKayitliTag.Text := 'Kayitsiz';
      RectKayitliTag.Fill.Color := TAlphaColorRec.Create($FFFBE9E7);
      LblKayitliTag.TextSettings.FontColor := TAlphaColorRec.Create($FFF44336);
    end;
  end;
end;

procedure TFrmGelenArama.UpdateOrdersUI;
var
  I: Integer;
  LItem: TListViewItem;
begin
  ListViewSonSiparisler.Items.Clear;
  for I := 0 to FRecentOrders.Count - 1 do
  begin
    LItem := ListViewSonSiparisler.Items.Add;
    LItem.Text := FRecentOrders[I].GetFormattedTarih + '    ' +
                  FRecentOrders[I].GetItemsSummary;
    LItem.Detail := FRecentOrders[I].GetFormattedToplam;
    LItem.Tag := FRecentOrders[I].Id;
  end;
end;

procedure TFrmGelenArama.BtnBackClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmGelenArama.BtnSiparisAcClick(Sender: TObject);
begin
  // Open new order form with customer pre-filled
end;

procedure TFrmGelenArama.BtnWhatsAppClick(Sender: TObject);
begin
  // Open WhatsApp with customer number
end;

procedure TFrmGelenArama.BtnAraClick(Sender: TObject);
begin
  // Make phone call
end;

procedure TFrmGelenArama.BtnHaritadaGosterClick(Sender: TObject);
begin
  // Show customer location on map
end;

procedure TFrmGelenArama.BtnAramayiKaydetClick(Sender: TObject);
begin
  // Log the call record
end;

end.
