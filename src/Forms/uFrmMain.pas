unit uFrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.TabControl,
  FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListBox, FMX.Effects,
  System.Generics.Collections, System.JSON,
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
    procedure BtnTumuSiparislerClick(Sender: TObject);
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
    procedure RefreshData;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.fmx}

uses
  uApiService, uAuthService, uHelpers,
  uFrmYeniSiparis, uFrmSiparisler, uFrmKuryeTakip, uFrmMusteriSec;

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

  RefreshData;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FDailySummary.Free;
  FRecentOrders.Free;
end;

procedure TFrmMain.RefreshData;
begin
  LoadDailySummary;
  LoadRecentOrders;
end;

procedure TFrmMain.LoadDailySummary;
var
  LResponse: TApiResponse;
  LData: TJSONObject;
begin
  LResponse := ApiService.Get('rest/TSmSiparis/GetGunlukOzet/');
  try
    if LResponse.Success and Assigned(LResponse.Data) and (LResponse.Data is TJSONObject) then
    begin
      LData := TJSONObject(LResponse.Data);
      FDailySummary.SiparisAdedi := LData.GetValue<Integer>('toplamSiparis', 0);
      FDailySummary.Ciro := LData.GetValue<Double>('toplamTutar', 0);
      FDailySummary.Tahsilat := LData.GetValue<Double>('toplamTutar', 0);
      FDailySummary.Borc := 0;
    end;
  finally
    LResponse.Free;
  end;
  UpdateSummaryUI;
end;

procedure TFrmMain.LoadRecentOrders;
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LOrder: TOrder;
  I: Integer;
begin
  FRecentOrders.Clear;
  LResponse := ApiService.Get('rest/TSmSiparis/GetSonSiparisler/5');
  try
    if LResponse.Success and Assigned(LResponse.Data) and (LResponse.Data is TJSONObject) then
    begin
      LData := TJSONObject(LResponse.Data);
      if LData.TryGetValue<TJSONArray>('data', LArray) then
      begin
        for I := 0 to LArray.Count - 1 do
        begin
          LOrder := TOrder.Create;
          LOrder.Id := (LArray.Items[I] as TJSONObject).GetValue<Integer>('siparisId', 0);
          LOrder.MusteriAdi := (LArray.Items[I] as TJSONObject).GetValue<string>('cariAdi', '');
          LOrder.MusteriTelefon := (LArray.Items[I] as TJSONObject).GetValue<string>('telefon', '');
          LOrder.Toplam := (LArray.Items[I] as TJSONObject).GetValue<Double>('genelToplam', 0);
          FRecentOrders.Add(LOrder);
        end;
      end;
    end;
  finally
    LResponse.Free;
  end;
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
    LItem.Detail := FRecentOrders[I].GetFormattedToplam;
    LItem.Tag := FRecentOrders[I].Id;
  end;
end;

procedure TFrmMain.SetActiveTab(AIndex: Integer);
const
  COLOR_INACTIVE = $FF757575;
begin
  FCurrentTab := AIndex;
  BtnTabAnaSayfa.TextSettings.FontColor := TAlphaColor(COLOR_INACTIVE);
  BtnTabSiparisler.TextSettings.FontColor := TAlphaColor(COLOR_INACTIVE);
  BtnTabBildirimler.TextSettings.FontColor := TAlphaColor(COLOR_INACTIVE);
  BtnTabAyarlar.TextSettings.FontColor := TAlphaColor(COLOR_INACTIVE);

  case AIndex of
    0: BtnTabAnaSayfa.TextSettings.FontColor := TAlphaColor(COLOR_PRIMARY);
    1: BtnTabSiparisler.TextSettings.FontColor := TAlphaColor(COLOR_PRIMARY);
    3: BtnTabBildirimler.TextSettings.FontColor := TAlphaColor(COLOR_PRIMARY);
    4: BtnTabAyarlar.TextSettings.FontColor := TAlphaColor(COLOR_PRIMARY);
  end;
end;

procedure TFrmMain.BtnYeniSiparisClick(Sender: TObject);
begin
  FrmYeniSiparis.Show;
end;

procedure TFrmMain.BtnSiparislerClick(Sender: TObject);
begin
  FrmSiparisler.Show;
end;

procedure TFrmMain.BtnMusterilerClick(Sender: TObject);
begin
  FrmMusteriSec.Show;
end;

procedure TFrmMain.BtnTahsilatClick(Sender: TObject);
begin
  // TODO: Tahsilat ekrani
end;

procedure TFrmMain.BtnKuryeTakipClick(Sender: TObject);
begin
  FrmKuryeTakip.Show;
end;

procedure TFrmMain.BtnKasaClick(Sender: TObject);
begin
  // TODO: Kasa ekrani
end;

procedure TFrmMain.BtnStoklarClick(Sender: TObject);
begin
  // TODO: Stoklar ekrani
end;

procedure TFrmMain.BtnRaporlarClick(Sender: TObject);
begin
  // TODO: Raporlar ekrani
end;

procedure TFrmMain.BtnTumuSiparislerClick(Sender: TObject);
begin
  FrmSiparisler.Show;
end;

procedure TFrmMain.BtnTabAnaSayfaClick(Sender: TObject);
begin
  SetActiveTab(0);
end;

procedure TFrmMain.BtnTabSiparislerClick(Sender: TObject);
begin
  SetActiveTab(1);
  FrmSiparisler.Show;
end;

procedure TFrmMain.BtnTabYeniSiparisClick(Sender: TObject);
begin
  FrmYeniSiparis.Show;
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
