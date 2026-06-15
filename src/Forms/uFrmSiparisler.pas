unit uFrmSiparisler;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.Edit,
  System.Generics.Collections,
  uOrder, uConstants;

type
  TSiparisFilter = (sfTumu, sfHazirlaniyor, sfYolda, sfTeslimEdildi, sfIptal);

  TFrmSiparisler = class(TForm)
    LayoutMain: TLayout;
    LayoutHeader: TLayout;
    RectHeader: TRectangle;
    BtnBack: TSpeedButton;
    LblHeaderTitle: TLabel;
    LayoutSearch: TLayout;
    RectSearch: TRectangle;
    EdtSearch: TEdit;
    LayoutFilter: TLayout;
    GridFilter: TGridPanelLayout;
    BtnFilterTumu: TCornerButton;
    BtnFilterHazirlaniyor: TCornerButton;
    BtnFilterYolda: TCornerButton;
    BtnFilterTeslim: TCornerButton;
    BtnFilterIptal: TCornerButton;
    ListViewOrders: TListView;
    procedure BtnBackClick(Sender: TObject);
    procedure BtnFilterTumuClick(Sender: TObject);
    procedure BtnFilterHazirlaniyorClick(Sender: TObject);
    procedure BtnFilterYoldaClick(Sender: TObject);
    procedure BtnFilterTeslimClick(Sender: TObject);
    procedure BtnFilterIptalClick(Sender: TObject);
    procedure EdtSearchChange(Sender: TObject);
    procedure ListViewOrdersItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure ListViewOrdersPullRefresh(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOrders: TOrderList;
    FFilteredOrders: TOrderList;
    FCurrentFilter: TSiparisFilter;
    FSearchText: string;
    FCurrentPage: Integer;
    FHasMore: Boolean;
    procedure LoadOrders;
    procedure ApplyFilter;
    procedure ApplySearch;
    procedure UpdateListView;
    procedure SetFilter(AFilter: TSiparisFilter);
    procedure UpdateFilterButtons;
    procedure LoadMoreOrders;
  public
    property CurrentFilter: TSiparisFilter read FCurrentFilter;
  end;

var
  FrmSiparisler: TFrmSiparisler;

implementation

{$R *.fmx}

uses
  uOrderService, uHelpers;

procedure TFrmSiparisler.FormCreate(Sender: TObject);
begin
  FOrders := TOrderList.Create(True);
  FFilteredOrders := TOrderList.Create(False);
  FCurrentFilter := sfTumu;
  FSearchText := '';
  FCurrentPage := 1;
  FHasMore := True;
  LoadOrders;
end;

procedure TFrmSiparisler.FormDestroy(Sender: TObject);
begin
  FFilteredOrders.Free;
  FOrders.Free;
end;

procedure TFrmSiparisler.LoadOrders;
begin
  FOrders.Clear;
  FCurrentPage := 1;
  FOrders.Free;
  FOrders := OrderService.GetOrders(FCurrentPage);
  ApplyFilter;
end;

procedure TFrmSiparisler.LoadMoreOrders;
var
  LMoreOrders: TOrderList;
  I: Integer;
begin
  if not FHasMore then
    Exit;

  Inc(FCurrentPage);
  LMoreOrders := OrderService.GetOrders(FCurrentPage);
  try
    if LMoreOrders.Count = 0 then
      FHasMore := False
    else
      for I := 0 to LMoreOrders.Count - 1 do
        FOrders.Add(LMoreOrders.ExtractAt(0));
  finally
    LMoreOrders.Free;
  end;
  ApplyFilter;
end;

procedure TFrmSiparisler.ApplyFilter;
var
  I: Integer;
  LOrder: TOrder;
begin
  FFilteredOrders.Clear;
  for I := 0 to FOrders.Count - 1 do
  begin
    LOrder := FOrders[I];
    case FCurrentFilter of
      sfTumu: FFilteredOrders.Add(LOrder);
      sfHazirlaniyor:
        if LOrder.Durum = osHazirlaniyor then
          FFilteredOrders.Add(LOrder);
      sfYolda:
        if LOrder.Durum = osYolda then
          FFilteredOrders.Add(LOrder);
      sfTeslimEdildi:
        if LOrder.Durum = osTeslimEdildi then
          FFilteredOrders.Add(LOrder);
      sfIptal:
        if LOrder.Durum = osIptal then
          FFilteredOrders.Add(LOrder);
    end;
  end;
  ApplySearch;
end;

procedure TFrmSiparisler.ApplySearch;
var
  I: Integer;
  LOrder: TOrder;
  LTempList: TOrderList;
begin
  if FSearchText = '' then
  begin
    UpdateListView;
    Exit;
  end;

  LTempList := TOrderList.Create(False);
  try
    for I := 0 to FFilteredOrders.Count - 1 do
    begin
      LOrder := FFilteredOrders[I];
      if (Pos(LowerCase(FSearchText), LowerCase(LOrder.MusteriAdi)) > 0) or
         (Pos(FSearchText, LOrder.MusteriTelefon) > 0) then
        LTempList.Add(LOrder);
    end;
    FFilteredOrders.Clear;
    for I := 0 to LTempList.Count - 1 do
      FFilteredOrders.Add(LTempList[I]);
  finally
    LTempList.Free;
  end;
  UpdateListView;
end;

procedure TFrmSiparisler.UpdateListView;
var
  I: Integer;
  LItem: TListViewItem;
  LOrder: TOrder;
begin
  ListViewOrders.Items.Clear;
  for I := 0 to FFilteredOrders.Count - 1 do
  begin
    LOrder := FFilteredOrders[I];
    LItem := ListViewOrders.Items.Add;
    LItem.Text := LOrder.MusteriAdi + '  ' + LOrder.GetDurumText;
    LItem.Detail := LOrder.GetItemsSummary + ' | ' +
                    LOrder.GetFormattedToplam + ' | ' +
                    LOrder.GetFormattedTarih;
    LItem.Tag := LOrder.Id;
  end;
end;

procedure TFrmSiparisler.SetFilter(AFilter: TSiparisFilter);
begin
  FCurrentFilter := AFilter;
  UpdateFilterButtons;
  ApplyFilter;
end;

procedure TFrmSiparisler.UpdateFilterButtons;
begin
  BtnFilterTumu.TextSettings.FontColor := TAlphaColorRec.Create($FF757575);
  BtnFilterHazirlaniyor.TextSettings.FontColor := TAlphaColorRec.Create($FF757575);
  BtnFilterYolda.TextSettings.FontColor := TAlphaColorRec.Create($FF757575);
  BtnFilterTeslim.TextSettings.FontColor := TAlphaColorRec.Create($FF757575);
  BtnFilterIptal.TextSettings.FontColor := TAlphaColorRec.Create($FF757575);

  case FCurrentFilter of
    sfTumu: BtnFilterTumu.TextSettings.FontColor := TAlphaColorRec.Create($FFFFFFFF);
    sfHazirlaniyor: BtnFilterHazirlaniyor.TextSettings.FontColor := TAlphaColorRec.Create($FFFFFFFF);
    sfYolda: BtnFilterYolda.TextSettings.FontColor := TAlphaColorRec.Create($FFFFFFFF);
    sfTeslimEdildi: BtnFilterTeslim.TextSettings.FontColor := TAlphaColorRec.Create($FFFFFFFF);
    sfIptal: BtnFilterIptal.TextSettings.FontColor := TAlphaColorRec.Create($FFFFFFFF);
  end;
end;

procedure TFrmSiparisler.BtnBackClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmSiparisler.BtnFilterTumuClick(Sender: TObject);
begin
  SetFilter(sfTumu);
end;

procedure TFrmSiparisler.BtnFilterHazirlaniyorClick(Sender: TObject);
begin
  SetFilter(sfHazirlaniyor);
end;

procedure TFrmSiparisler.BtnFilterYoldaClick(Sender: TObject);
begin
  SetFilter(sfYolda);
end;

procedure TFrmSiparisler.BtnFilterTeslimClick(Sender: TObject);
begin
  SetFilter(sfTeslimEdildi);
end;

procedure TFrmSiparisler.BtnFilterIptalClick(Sender: TObject);
begin
  SetFilter(sfIptal);
end;

procedure TFrmSiparisler.EdtSearchChange(Sender: TObject);
begin
  FSearchText := EdtSearch.Text;
  ApplyFilter;
end;

procedure TFrmSiparisler.ListViewOrdersItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  // Open order detail
end;

procedure TFrmSiparisler.ListViewOrdersPullRefresh(Sender: TObject);
begin
  LoadOrders;
end;

end.
