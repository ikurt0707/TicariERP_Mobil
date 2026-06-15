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
  private
    FCustomer: TCustomer;
    FRecentOrders: TOrderList;
    FPhoneNumber: string;

    procedure LoadCustomerByPhone(const APhone: string);
    procedure LoadRecentOrders;
    procedure SetupUI;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ShowForPhone(const APhone: string);
    procedure OnSiparisAcClick(Sender: TObject);
    procedure OnWhatsAppClick(Sender: TObject);
    procedure OnAraClick(Sender: TObject);
    procedure OnHaritadaGosterClick(Sender: TObject);
    procedure OnAramayiKaydetClick(Sender: TObject);

    property Customer: TCustomer read FCustomer;
    property PhoneNumber: string read FPhoneNumber;
  end;

var
  FrmGelenArama: TFrmGelenArama;

implementation

{$R *.fmx}

uses
  uCustomerService, uOrderService;

{ TFrmGelenArama }

constructor TFrmGelenArama.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCustomer := nil;
  FRecentOrders := TOrderList.Create(True);
  FPhoneNumber := '';
  SetupUI;
end;

destructor TFrmGelenArama.Destroy;
begin
  if Assigned(FCustomer) then
    FCustomer.Free;
  FRecentOrders.Free;
  inherited;
end;

procedure TFrmGelenArama.SetupUI;
begin
  Caption := 'Gelen Arama';
end;

procedure TFrmGelenArama.ShowForPhone(const APhone: string);
begin
  FPhoneNumber := APhone;
  LoadCustomerByPhone(APhone);
  LoadRecentOrders;
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

procedure TFrmGelenArama.OnSiparisAcClick(Sender: TObject);
begin
  // Open new order form with customer pre-filled
end;

procedure TFrmGelenArama.OnWhatsAppClick(Sender: TObject);
begin
  // Open WhatsApp with customer number
end;

procedure TFrmGelenArama.OnAraClick(Sender: TObject);
begin
  // Make phone call
end;

procedure TFrmGelenArama.OnHaritadaGosterClick(Sender: TObject);
begin
  // Show customer on map
end;

procedure TFrmGelenArama.OnAramayiKaydetClick(Sender: TObject);
begin
  // Log the call
end;

end.
