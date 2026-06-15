unit uFrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.TabControl,
  FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListBox, FMX.Effects,
  System.Generics.Collections,
  uCustomer, uOrder, uDailySummary, uConstants;

type
  TFrmMain = class(TForm)
  private
    FDailySummary: TDailySummary;
    FRecentOrders: TOrderList;
    FCurrentTab: Integer;

    procedure LoadDailySummary;
    procedure LoadRecentOrders;
    procedure SetupUI;
    procedure NavigateToTab(ATabIndex: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure OnYeniSiparisClick(Sender: TObject);
    procedure OnSiparislerClick(Sender: TObject);
    procedure OnMusterilerClick(Sender: TObject);
    procedure OnTahsilatClick(Sender: TObject);
    procedure OnKuryeTakipClick(Sender: TObject);
    procedure OnKasaClick(Sender: TObject);
    procedure OnStoklarClick(Sender: TObject);
    procedure OnRaporlarClick(Sender: TObject);
    procedure OnBildirimlerClick(Sender: TObject);
    procedure OnAyarlarClick(Sender: TObject);
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.fmx}

{ TFrmMain }

constructor TFrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDailySummary := TDailySummary.Create;
  FRecentOrders := TOrderList.Create(True);
  FCurrentTab := 0;
  SetupUI;
  LoadDailySummary;
  LoadRecentOrders;
end;

destructor TFrmMain.Destroy;
begin
  FDailySummary.Free;
  FRecentOrders.Free;
  inherited;
end;

procedure TFrmMain.SetupUI;
begin
  Caption := APP_NAME;
end;

procedure TFrmMain.LoadDailySummary;
begin
  // Will load from API
  FDailySummary.SiparisAdedi := 0;
  FDailySummary.Ciro := 0;
  FDailySummary.Tahsilat := 0;
  FDailySummary.Borc := 0;
end;

procedure TFrmMain.LoadRecentOrders;
begin
  FRecentOrders.Clear;
  // Will load from API
end;

procedure TFrmMain.NavigateToTab(ATabIndex: Integer);
begin
  FCurrentTab := ATabIndex;
end;

procedure TFrmMain.OnYeniSiparisClick(Sender: TObject);
begin
  // Navigate to new order form
end;

procedure TFrmMain.OnSiparislerClick(Sender: TObject);
begin
  NavigateToTab(1);
end;

procedure TFrmMain.OnMusterilerClick(Sender: TObject);
begin
  // Navigate to customers
end;

procedure TFrmMain.OnTahsilatClick(Sender: TObject);
begin
  // Navigate to collections
end;

procedure TFrmMain.OnKuryeTakipClick(Sender: TObject);
begin
  // Navigate to courier tracking
end;

procedure TFrmMain.OnKasaClick(Sender: TObject);
begin
  // Navigate to cash register
end;

procedure TFrmMain.OnStoklarClick(Sender: TObject);
begin
  // Navigate to stocks
end;

procedure TFrmMain.OnRaporlarClick(Sender: TObject);
begin
  // Navigate to reports
end;

procedure TFrmMain.OnBildirimlerClick(Sender: TObject);
begin
  NavigateToTab(3);
end;

procedure TFrmMain.OnAyarlarClick(Sender: TObject);
begin
  NavigateToTab(4);
end;

end.
