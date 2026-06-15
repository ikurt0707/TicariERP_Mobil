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
    GridActions: TGridPanelLayout;
    RectBtnYeniSiparis: TRectangle;
    LblBtnYeniSiparis: TLabel;
    RectBtnSiparisler: TRectangle;
    LblBtnSiparisler: TLabel;
    RectBtnMusteriler: TRectangle;
    LblBtnMusteriler: TLabel;
    RectBtnTahsilat: TRectangle;
    LblBtnTahsilat: TLabel;
    RectBtnKuryeTakip: TRectangle;
    LblBtnKuryeTakip: TLabel;
    RectBtnKasa: TRectangle;
    LblBtnKasa: TLabel;
    RectBtnStoklar: TRectangle;
    LblBtnStoklar: TLabel;
    RectBtnRaporlar: TRectangle;
    LblBtnRaporlar: TLabel;
    LayoutDailySummary: TLayout;
    LblGunlukOzet: TLabel;
    LayoutSummaryCards: TGridPanelLayout;
    RectSiparis: TRectangle;
    LblSiparisTitle: TLabel;
    LblSiparisCount: TLabel;
    RectCiro: TRectangle;
    LblCiroTitle: TLabel;
    LblCiroValue: TLabel;
    RectTahsilat: TRectangle;
    LblTahsilatTitle: TLabel;
    LblTahsilatValue: TLabel;
    RectBorc: TRectangle;
    LblBorcTitle: TLabel;
    LblBorcValue: TLabel;
    LayoutRecentOrders: TLayout;
    LayoutRecentHeader: TLayout;
    LblSonSiparisler: TLabel;
    BtnTumuSiparisler: TSpeedButton;
    ListViewRecentOrders: TListView;
    LayoutBottomNav: TLayout;
    RectBottomNav: TRectangle;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnTumuSiparislerClick(Sender: TObject);
    procedure RectBtnYeniSiparisClick(Sender: TObject);
    procedure RectBtnSiparislerClick(Sender: TObject);
    procedure RectBtnMusterilerClick(Sender: TObject);
    procedure RectBtnTahsilatClick(Sender: TObject);
    procedure RectBtnKuryeTakipClick(Sender: TObject);
    procedure RectBtnKasaClick(Sender: TObject);
    procedure RectBtnStoklarClick(Sender: TObject);
    procedure RectBtnRaporlarClick(Sender: TObject);
  private
    FDailySummary: TDailySummary;
    FRecentOrders: TOrderList;
    FLoginDone: Boolean;
    procedure ShowLoginForm;
    procedure LoadDailySummary;
    procedure LoadTeslimEdilmemisSiparisler;
    procedure UpdateSummaryUI;
    procedure UpdateRecentOrdersUI;
  public
    procedure RefreshData;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.fmx}

uses
  uApiService, uAuthService, uHelpers,
  uFrmLogin, uFrmYeniSiparis, uFrmSiparisler, uFrmGelenArama,
  uFrmMusteriSec, uFrmStoklar;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FDailySummary := TDailySummary.Create;
  FRecentOrders := TOrderList.Create(True);
  FLoginDone := False;
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin
  if not FLoginDone then
    ShowLoginForm;
end;

procedure TFrmMain.ShowLoginForm;
var
  LLogin: TFrmLogin;
begin
  LLogin := TFrmLogin.Create(Application);
  try
    LLogin.ShowModal(
      procedure(AResult: TModalResult)
      begin
        if LLogin.LoginSuccess then
        begin
          FLoginDone := True;
          LblUserName.Text := AuthService.AdSoyad;
          LblBayiName.Text := AuthService.BayiName;
          RefreshData;
        end
        else
          Application.Terminate;
      end
    );
  except
    LLogin.Free;
    raise;
  end;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FDailySummary.Free;
  FRecentOrders.Free;
end;

procedure TFrmMain.RefreshData;
begin
  LoadDailySummary;
  LoadTeslimEdilmemisSiparisler;
end;

procedure TFrmMain.LoadDailySummary;
var
  LResponse: TApiResponse;
  LData: TJSONObject;
begin
  LResponse := ApiService.Get('rest/TSmSiparis/GetGunlukOzet/');
  try
    LData := ExtractDSResult(LResponse);
    if Assigned(LData) then
    begin
      FDailySummary.SiparisAdedi := LData.GetValue<Integer>('toplamSiparis', 0);
      FDailySummary.Ciro := LData.GetValue<Double>('toplamTutar', 0);
      FDailySummary.Tahsilat := LData.GetValue<Double>('toplamTahsilat', 0);
      FDailySummary.Borc := LData.GetValue<Double>('toplamBorc', 0);
    end;
  finally
    LResponse.Free;
  end;
  UpdateSummaryUI;
end;

procedure TFrmMain.LoadTeslimEdilmemisSiparisler;
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LOrder: TOrder;
  I: Integer;
begin
  FRecentOrders.Clear;
  LResponse := ApiService.Get('rest/TSmSiparis/GetTeslimEdilmemisSiparisler/50');
  try
    LData := ExtractDSResult(LResponse);
    if Assigned(LData) and LData.TryGetValue<TJSONArray>('data', LArray) then
    begin
      for I := 0 to LArray.Count - 1 do
      begin
        LOrder := TOrder.Create;
        LOrder.FromJSON(LArray.Items[I] as TJSONObject);
        FRecentOrders.Add(LOrder);
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
    LItem.Detail := FRecentOrders[I].GetDurumText + ' - ' + FRecentOrders[I].GetFormattedToplam;
    LItem.Tag := FRecentOrders[I].Id;
  end;
end;

procedure TFrmMain.RectBtnYeniSiparisClick(Sender: TObject);
var
  LForm: TFrmYeniSiparis;
begin
  LForm := TFrmYeniSiparis.Create(Application);
  LForm.Show;
end;

procedure TFrmMain.RectBtnSiparislerClick(Sender: TObject);
var
  LForm: TFrmSiparisler;
begin
  LForm := TFrmSiparisler.Create(Application);
  LForm.Show;
end;

procedure TFrmMain.RectBtnMusterilerClick(Sender: TObject);
var
  LForm: TFrmMusteriSec;
begin
  LForm := TFrmMusteriSec.Create(Application);
  LForm.Show;
end;

procedure TFrmMain.RectBtnTahsilatClick(Sender: TObject);
begin
  // TODO: Tahsilat ekrani
end;

procedure TFrmMain.RectBtnKuryeTakipClick(Sender: TObject);
var
  LForm: TFrmGelenArama;
begin
  LForm := TFrmGelenArama.Create(Application);
  LForm.Show;
end;

procedure TFrmMain.RectBtnKasaClick(Sender: TObject);
begin
  // TODO: Kasa ekrani
end;

procedure TFrmMain.RectBtnStoklarClick(Sender: TObject);
var
  LForm: TFrmStoklar;
begin
  LForm := TFrmStoklar.Create(Application);
  LForm.Show;
end;

procedure TFrmMain.RectBtnRaporlarClick(Sender: TObject);
begin
  // TODO: Raporlar ekrani
end;

procedure TFrmMain.BtnTumuSiparislerClick(Sender: TObject);
var
  LForm: TFrmSiparisler;
begin
  LForm := TFrmSiparisler.Create(Application);
  LForm.Show;
end;

end.
