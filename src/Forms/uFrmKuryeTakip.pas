unit uFrmKuryeTakip;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  System.Generics.Collections,
  uCourier, uOrder, uConstants;

type
  TKuryeTabFilter = (ktfTumu, ktfYolda, ktfTeslimEdildi, ktfBekliyor);

  TFrmKuryeTakip = class(TForm)
    LayoutMain: TLayout;
    LayoutHeader: TLayout;
    RectHeader: TRectangle;
    BtnBack: TSpeedButton;
    LblHeaderTitle: TLabel;
    BtnRefresh: TSpeedButton;
    LayoutSummary: TLayout;
    GridSummary: TGridPanelLayout;
    RectToplamCard: TRectangle;
    LblToplamTitle: TLabel;
    LblToplamCount: TLabel;
    RectYoldaCard: TRectangle;
    LblYoldaTitle: TLabel;
    LblYoldaCount: TLabel;
    RectTeslimCard: TRectangle;
    LblTeslimTitle: TLabel;
    LblTeslimCount: TLabel;
    RectBekliyorCard: TRectangle;
    LblBekliyorTitle: TLabel;
    LblBekliyorCount: TLabel;
    LayoutFilter: TLayout;
    GridFilter: TGridPanelLayout;
    BtnFilterTumu: TCornerButton;
    BtnFilterYolda: TCornerButton;
    BtnFilterTeslim: TCornerButton;
    BtnFilterBekliyor: TCornerButton;
    ListViewCouriers: TListView;
    procedure BtnBackClick(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnFilterTumuClick(Sender: TObject);
    procedure BtnFilterYoldaClick(Sender: TObject);
    procedure BtnFilterTeslimClick(Sender: TObject);
    procedure BtnFilterBekliyorClick(Sender: TObject);
    procedure ListViewCouriersItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FCouriers: TObjectList<TCourier>;
    FOrders: TOrderList;
    FCurrentFilter: TKuryeTabFilter;
    FTotalOrders: Integer;
    FYoldaCount: Integer;
    FTeslimCount: Integer;
    FBekliyorCount: Integer;
    procedure LoadData;
    procedure UpdateCounts;
    procedure UpdateUI;
    procedure ApplyFilter;
    procedure SetFilter(AFilter: TKuryeTabFilter);
    procedure UpdateFilterButtons;
  public
    property CurrentFilter: TKuryeTabFilter read FCurrentFilter;
  end;

var
  FrmKuryeTakip: TFrmKuryeTakip;

implementation

{$R *.fmx}

uses
  uOrderService, uHelpers;

procedure TFrmKuryeTakip.FormCreate(Sender: TObject);
begin
  FCouriers := TObjectList<TCourier>.Create(True);
  FOrders := TOrderList.Create(True);
  FCurrentFilter := ktfTumu;
  LoadData;
end;

procedure TFrmKuryeTakip.FormDestroy(Sender: TObject);
begin
  FCouriers.Free;
  FOrders.Free;
end;

procedure TFrmKuryeTakip.LoadData;
begin
  UpdateCounts;
  UpdateUI;
  ApplyFilter;
end;

procedure TFrmKuryeTakip.UpdateCounts;
var
  I: Integer;
begin
  FTotalOrders := 0;
  FYoldaCount := 0;
  FTeslimCount := 0;
  FBekliyorCount := 0;

  for I := 0 to FOrders.Count - 1 do
  begin
    Inc(FTotalOrders);
    case FOrders[I].Durum of
      osYolda: Inc(FYoldaCount);
      osTeslimEdildi: Inc(FTeslimCount);
      osHazirlaniyor: Inc(FBekliyorCount);
    end;
  end;

  LblToplamCount.Text := IntToStr(FTotalOrders);
  LblYoldaCount.Text := IntToStr(FYoldaCount);
  LblTeslimCount.Text := IntToStr(FTeslimCount);
  LblBekliyorCount.Text := IntToStr(FBekliyorCount);
end;

procedure TFrmKuryeTakip.UpdateUI;
begin
  UpdateFilterButtons;
end;

procedure TFrmKuryeTakip.ApplyFilter;
var
  I: Integer;
  LItem: TListViewItem;
  LCourier: TCourier;
begin
  ListViewCouriers.Items.Clear;
  for I := 0 to FCouriers.Count - 1 do
  begin
    LCourier := FCouriers[I];
    LItem := ListViewCouriers.Items.Add;
    LItem.Text := LCourier.AdSoyad;
    LItem.Detail := Format('%s | Teslim: %d/%d',
      [LCourier.GetDurumText, LCourier.TeslimEdilen, LCourier.ToplamSiparis]);
    LItem.Tag := LCourier.Id;
  end;
end;

procedure TFrmKuryeTakip.SetFilter(AFilter: TKuryeTabFilter);
begin
  FCurrentFilter := AFilter;
  UpdateFilterButtons;
  ApplyFilter;
end;

procedure TFrmKuryeTakip.UpdateFilterButtons;
begin
  BtnFilterTumu.TextSettings.FontColor := TAlphaColor($FF757575);
  BtnFilterYolda.TextSettings.FontColor := TAlphaColor($FF757575);
  BtnFilterTeslim.TextSettings.FontColor := TAlphaColor($FF757575);
  BtnFilterBekliyor.TextSettings.FontColor := TAlphaColor($FF757575);

  case FCurrentFilter of
    ktfTumu: BtnFilterTumu.TextSettings.FontColor := TAlphaColor($FFFFFFFF);
    ktfYolda: BtnFilterYolda.TextSettings.FontColor := TAlphaColor($FFFFFFFF);
    ktfTeslimEdildi: BtnFilterTeslim.TextSettings.FontColor := TAlphaColor($FFFFFFFF);
    ktfBekliyor: BtnFilterBekliyor.TextSettings.FontColor := TAlphaColor($FFFFFFFF);
  end;
end;

procedure TFrmKuryeTakip.BtnBackClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmKuryeTakip.BtnRefreshClick(Sender: TObject);
begin
  LoadData;
end;

procedure TFrmKuryeTakip.BtnFilterTumuClick(Sender: TObject);
begin
  SetFilter(ktfTumu);
end;

procedure TFrmKuryeTakip.BtnFilterYoldaClick(Sender: TObject);
begin
  SetFilter(ktfYolda);
end;

procedure TFrmKuryeTakip.BtnFilterTeslimClick(Sender: TObject);
begin
  SetFilter(ktfTeslimEdildi);
end;

procedure TFrmKuryeTakip.BtnFilterBekliyorClick(Sender: TObject);
begin
  SetFilter(ktfBekliyor);
end;

procedure TFrmKuryeTakip.ListViewCouriersItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  // Show courier detail
end;

end.
