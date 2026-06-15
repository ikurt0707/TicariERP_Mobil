unit uFrmSiparisler;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.Edit, FMX.TabControl,
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
    TabControlMain: TTabControl;
    TabSiparisler: TTabItem;
    TabGelenCagrilar: TTabItem;
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
    ListViewGelenCagrilar: TListView;
    procedure BtnBackClick(Sender: TObject);
    procedure BtnFilterTumuClick(Sender: TObject);
    procedure BtnFilterHazirlaniyorClick(Sender: TObject);
    procedure BtnFilterYoldaClick(Sender: TObject);
    procedure BtnFilterTeslimClick(Sender: TObject);
    procedure BtnFilterIptalClick(Sender: TObject);
    procedure EdtSearchChange(Sender: TObject);
    procedure ListViewOrdersItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure ListViewOrdersPullRefresh(Sender: TObject);
    procedure ListViewGelenCagrilarItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TabControlMainChange(Sender: TObject);
  private
    FOrders: TOrderList;
    FFilteredOrders: TOrderList;
    FCurrentFilter: TSiparisFilter;
    FSearchText: string;
    FCurrentPage: Integer;
    FHasMore: Boolean;
    procedure LoadOrders;
    procedure LoadGelenCagrilar;
    procedure ApplyFilter;
    procedure ApplySearch;
    procedure UpdateListView;
    procedure SetFilter(AFilter: TSiparisFilter);
    procedure UpdateFilterButtons;
    procedure LoadMoreOrders;
    procedure CreateOrderFromCall(AAramaLogID: Integer; const ATelefon, ACariAdi: string);
  public
    property CurrentFilter: TSiparisFilter read FCurrentFilter;
  end;

var
  FrmSiparisler: TFrmSiparisler;

implementation

{$R *.fmx}

uses
  uApiService, uHelpers, uFrmYeniSiparis;

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
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LOrder: TOrder;
  I: Integer;
begin
  FOrders.Clear;
  FCurrentPage := 1;

  LResponse := ApiService.Get('rest/TSmSiparis/GetSiparisler/1/20/Tumu');
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
          FOrders.Add(LOrder);
        end;
      end;
    end;
  finally
    LResponse.Free;
  end;
  ApplyFilter;
end;

procedure TFrmSiparisler.LoadGelenCagrilar;
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LItem: TListViewItem;
  LObj: TJSONObject;
  I: Integer;
begin
  ListViewGelenCagrilar.Items.Clear;

  LResponse := ApiService.Get('rest/TSmCallerID/GetSonAramalar/20');
  try
    if LResponse.Success and Assigned(LResponse.Data) and (LResponse.Data is TJSONObject) then
    begin
      LData := TJSONObject(LResponse.Data);
      if LData.TryGetValue<TJSONArray>('data', LArray) then
      begin
        for I := 0 to LArray.Count - 1 do
        begin
          LObj := LArray.Items[I] as TJSONObject;
          LItem := ListViewGelenCagrilar.Items.Add;
          LItem.Text := LObj.GetValue<string>('cariAdi', LObj.GetValue<string>('telefon', 'Bilinmeyen'));
          LItem.Detail := LObj.GetValue<string>('telefon', '') + ' - ' +
                          LObj.GetValue<string>('tarih', '');
          LItem.Tag := LObj.GetValue<Integer>('aramaLogId', 0);
          LItem.Data['telefon'] := LObj.GetValue<string>('telefon', '');
          LItem.Data['cariAdi'] := LObj.GetValue<string>('cariAdi', '');
        end;
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TFrmSiparisler.LoadMoreOrders;
begin
  if not FHasMore then Exit;
  Inc(FCurrentPage);
  // Load next page via API
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
    LItem.Detail := LOrder.GetFormattedToplam + ' | ' + LOrder.GetFormattedTarih;
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
const
  COLOR_INACTIVE = $FF757575;
  COLOR_ACTIVE = $FFFFFFFF;
begin
  BtnFilterTumu.TextSettings.FontColor := TAlphaColor(COLOR_INACTIVE);
  BtnFilterHazirlaniyor.TextSettings.FontColor := TAlphaColor(COLOR_INACTIVE);
  BtnFilterYolda.TextSettings.FontColor := TAlphaColor(COLOR_INACTIVE);
  BtnFilterTeslim.TextSettings.FontColor := TAlphaColor(COLOR_INACTIVE);
  BtnFilterIptal.TextSettings.FontColor := TAlphaColor(COLOR_INACTIVE);

  case FCurrentFilter of
    sfTumu: BtnFilterTumu.TextSettings.FontColor := TAlphaColor(COLOR_ACTIVE);
    sfHazirlaniyor: BtnFilterHazirlaniyor.TextSettings.FontColor := TAlphaColor(COLOR_ACTIVE);
    sfYolda: BtnFilterYolda.TextSettings.FontColor := TAlphaColor(COLOR_ACTIVE);
    sfTeslimEdildi: BtnFilterTeslim.TextSettings.FontColor := TAlphaColor(COLOR_ACTIVE);
    sfIptal: BtnFilterIptal.TextSettings.FontColor := TAlphaColor(COLOR_ACTIVE);
  end;
end;

procedure TFrmSiparisler.CreateOrderFromCall(AAramaLogID: Integer;
  const ATelefon, ACariAdi: string);
begin
  FrmYeniSiparis.SetFromIncomingCall(AAramaLogID, ATelefon, ACariAdi);
  FrmYeniSiparis.Show;
end;

procedure TFrmSiparisler.TabControlMainChange(Sender: TObject);
begin
  if TabControlMain.ActiveTab = TabGelenCagrilar then
    LoadGelenCagrilar;
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

procedure TFrmSiparisler.ListViewGelenCagrilarItemClick(const Sender: TObject;
  const AItem: TListViewItem);
var
  LAramaLogID: Integer;
  LTelefon, LCariAdi: string;
begin
  LAramaLogID := AItem.Tag;
  LTelefon := AItem.Data['telefon'].ToString;
  LCariAdi := AItem.Data['cariAdi'].ToString;
  CreateOrderFromCall(LAramaLogID, LTelefon, LCariAdi);
end;

procedure TFrmSiparisler.ListViewOrdersPullRefresh(Sender: TObject);
begin
  LoadOrders;
end;

end.
