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
    LayoutMain: TLayout;
    LayoutHeader: TLayout;
    RectHeader: TRectangle;
    LblAppTitle: TLabel;
    BtnMenu: TSpeedButton;
    BtnNotification: TSpeedButton;
    LayoutContent: TLayout;
    ScrollContent: TVertScrollBox;
    LayoutWelcome: TLayout;
    RectWelcome: TRectangle;
    LblWelcome: TLabel;
    LblUserName: TLabel;
    LblBayiName: TLabel;
    LayoutQuickActions: TLayout;
    RectQuickActions: TRectangle;
    GridActions: TGridPanelLayout;
    BtnYeniSiparis: TSpeedButton;
    BtnSiparisler: TSpeedButton;
    BtnMusteriler: TSpeedButton;
    BtnTahsilat: TSpeedButton;
    BtnKuryeTakip: TSpeedButton;
    BtnKasa: TSpeedButton;
    BtnStoklar: TSpeedButton;
    BtnRaporlar: TSpeedButton;
    LayoutDailySummary: TLayout;
    LblGunlukOzet: TLabel;
    LayoutSummaryCards: TGridPanelLayout;
    RectSiparis: TRectangle;
    LblSiparisTitle: TLabel;
    LblSiparisCount: TLabel;
    LblSiparisSubtitle: TLabel;
    RectCiro: TRectangle;
    LblCiroTitle: TLabel;
    LblCiroValue: TLabel;
    LblCiroSubtitle: TLabel;
    RectTahsilat: TRectangle;
    LblTahsilatTitle: TLabel;
    LblTahsilatValue: TLabel;
    LblTahsilatSubtitle: TLabel;
    RectBorc: TRectangle;
    LblBorcTitle: TLabel;
    LblBorcValue: TLabel;
    LblBorcSubtitle: TLabel;
    LayoutRecentOrders: TLayout;
    LayoutRecentHeader: TLayout;
    LblSonSiparisler: TLabel;
    BtnTumuSiparisler: TSpeedButton;
    ListViewRecentOrders: TListView;
    LayoutBottomNav: TLayout;
    RectBottomNav: TRectangle;
    GridBottomNav: TGridPanelLayout;
    BtnTabAnaSayfa: TSpeedButton;
    BtnTabSiparisler: TSpeedButton;
    BtnTabYeniSiparis: TSpeedButton;
    BtnTabBildirimler: TSpeedButton;
    BtnTabAyarlar: TSpeedButton;
    procedure BtnYeniSiparisClick(Sender: TObject);
    procedure BtnSiparislerClick(Sender: TObject);
    procedure BtnMusterilerClick(Sender: TObject);
    procedure BtnTahsilatClick(Sender: TObject);
    procedure BtnKuryeTakipClick(Sender: TObject);
    procedure BtnKasaClick(Sender: TObject);
    procedure BtnStoklarClick(Sender: TObject);
    procedure BtnRaporlarClick(Sender: TObject);
    procedure BtnTabAnaSayfaClick(Sender: TObject);
    procedure BtnTabSiparislerClick(Sender: TObject);
    procedure BtnTabYeniSiparisClick(Sender: TObject);
    procedure BtnTabBildirimlerClick(Sender: TObject);
    procedure BtnTabAyarlarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FDailySummary: TDailySummary;
    FRecentOrders: TOrderList;
    FCurrentTab: Integer;
    procedure LoadDailySummary;
    procedure LoadRecentOrders;
    procedure UpdateSummaryUI;
    procedure UpdateRecentOrdersUI;
    procedure SetActiveTab(AIndex: Integer);
  public
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.fmx}

uses
  uOrderService, uApiService, uAuthService, uHelpers;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FDailySummary := TDailySummary.Create;
  FRecentOrders := TOrderList.Create(True);
  FCurrentTab := 0;

  if AuthService.IsAuthenticated then
  begin
    LblUserName.Text := AuthService.UserName;
    LblBayiName.Text := AuthService.BayiName;
  end;

  LoadDailySummary;
  LoadRecentOrders;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FDailySummary.Free;
  FRecentOrders.Free;
end;

procedure TFrmMain.LoadDailySummary;
begin
  // Load from API and update UI
  UpdateSummaryUI;
end;

procedure TFrmMain.LoadRecentOrders;
begin
  FRecentOrders.Free;
  FRecentOrders := OrderService.GetRecentOrders(5);
  UpdateRecentOrdersUI;
end;

procedure TFrmMain.UpdateSummaryUI;
begin
  LblSiparisCount.Text := IntToStr(FDailySummary.SiparisAdedi);
  LblCiroValue.Text := THelpers.FormatCurrency(FDailySummary.Ciro);
  LblTahsilatValue.Text := THelpers.FormatCurrency(FDailySummary.Tahsilat);
  LblBorcValue.Text := THelpers.FormatCurrency(FDailySummary.Borc);
end;

procedure TFrmMain.UpdateRecentOrdersUI;
var
  I: Integer;
  LItem: TListViewItem;
begin
  ListViewRecentOrders.Items.Clear;
  for I := 0 to FRecentOrders.Count - 1 do
  begin
    LItem := ListViewRecentOrders.Items.Add;
    LItem.Text := FRecentOrders[I].MusteriAdi;
    LItem.Detail := FRecentOrders[I].GetItemsSummary + ' - ' +
                    FRecentOrders[I].GetFormattedToplam;
    LItem.Tag := FRecentOrders[I].Id;
  end;
end;

procedure TFrmMain.SetActiveTab(AIndex: Integer);
begin
  FCurrentTab := AIndex;
  BtnTabAnaSayfa.TextSettings.FontColor := TAlphaColorRec.Create($FF757575);
  BtnTabSiparisler.TextSettings.FontColor := TAlphaColorRec.Create($FF757575);
  BtnTabBildirimler.TextSettings.FontColor := TAlphaColorRec.Create($FF757575);
  BtnTabAyarlar.TextSettings.FontColor := TAlphaColorRec.Create($FF757575);

  case AIndex of
    0: BtnTabAnaSayfa.TextSettings.FontColor := TAlphaColorRec.Create(COLOR_PRIMARY);
    1: BtnTabSiparisler.TextSettings.FontColor := TAlphaColorRec.Create(COLOR_PRIMARY);
    3: BtnTabBildirimler.TextSettings.FontColor := TAlphaColorRec.Create(COLOR_PRIMARY);
    4: BtnTabAyarlar.TextSettings.FontColor := TAlphaColorRec.Create(COLOR_PRIMARY);
  end;
end;

procedure TFrmMain.BtnYeniSiparisClick(Sender: TObject);
begin
  // Navigate to FrmYeniSiparis
end;

procedure TFrmMain.BtnSiparislerClick(Sender: TObject);
begin
  // Navigate to FrmSiparisler
end;

procedure TFrmMain.BtnMusterilerClick(Sender: TObject);
begin
  // Navigate to Customers screen
end;

procedure TFrmMain.BtnTahsilatClick(Sender: TObject);
begin
  // Navigate to Collections screen
end;

procedure TFrmMain.BtnKuryeTakipClick(Sender: TObject);
begin
  // Navigate to FrmKuryeTakip
end;

procedure TFrmMain.BtnKasaClick(Sender: TObject);
begin
  // Navigate to Cash register
end;

procedure TFrmMain.BtnStoklarClick(Sender: TObject);
begin
  // Navigate to Stocks screen
end;

procedure TFrmMain.BtnRaporlarClick(Sender: TObject);
begin
  // Navigate to Reports screen
end;

procedure TFrmMain.BtnTabAnaSayfaClick(Sender: TObject);
begin
  SetActiveTab(0);
end;

procedure TFrmMain.BtnTabSiparislerClick(Sender: TObject);
begin
  SetActiveTab(1);
end;

procedure TFrmMain.BtnTabYeniSiparisClick(Sender: TObject);
begin
  // Navigate to FrmYeniSiparis
end;

procedure TFrmMain.BtnTabBildirimlerClick(Sender: TObject);
begin
  SetActiveTab(3);
end;

procedure TFrmMain.BtnTabAyarlarClick(Sender: TObject);
begin
  SetActiveTab(4);
end;

end.
