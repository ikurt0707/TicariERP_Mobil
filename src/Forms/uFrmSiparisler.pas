unit uFrmSiparisler;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.Edit, FMX.SearchBox,
  System.Generics.Collections,
  uOrder, uConstants;

type
  TSiparisFilter = (sfTumu, sfHazirlaniyor, sfYolda, sfTeslimEdildi, sfIptal);

  TFrmSiparisler = class(TForm)
  private
    FOrders: TOrderList;
    FFilteredOrders: TOrderList;
    FCurrentFilter: TSiparisFilter;
    FSearchText: string;
    FCurrentPage: Integer;
    FHasMore: Boolean;

    procedure LoadOrders;
    procedure SetupUI;
    procedure ApplyFilter;
    procedure ApplySearch(const AText: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure OnFilterChange(AFilter: TSiparisFilter);
    procedure OnSearchChange(const AText: string);
    procedure OnOrderClick(AOrderId: Integer);
    procedure OnLoadMore;
    procedure OnRefresh;

    function GetOrderCount: Integer;
    function GetFilteredCount: Integer;

    property CurrentFilter: TSiparisFilter read FCurrentFilter;
    property SearchText: string read FSearchText;
    property CurrentPage: Integer read FCurrentPage;
  end;

var
  FrmSiparisler: TFrmSiparisler;

implementation

{$R *.fmx}

uses
  uOrderService, uApiService;

{ TFrmSiparisler }

constructor TFrmSiparisler.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOrders := TOrderList.Create(True);
  FFilteredOrders := TOrderList.Create(False);
  FCurrentFilter := sfTumu;
  FSearchText := '';
  FCurrentPage := 1;
  FHasMore := True;
  SetupUI;
  LoadOrders;
end;

destructor TFrmSiparisler.Destroy;
begin
  FFilteredOrders.Free;
  FOrders.Free;
  inherited;
end;

procedure TFrmSiparisler.SetupUI;
begin
  Caption := 'Siparisler';
end;

procedure TFrmSiparisler.LoadOrders;
var
  LNewOrders: TOrderList;
  I: Integer;
begin
  LNewOrders := OrderService.GetOrders(FCurrentPage, DEFAULT_PAGE_SIZE);
  try
    FHasMore := LNewOrders.Count >= DEFAULT_PAGE_SIZE;
    for I := 0 to LNewOrders.Count - 1 do
      FOrders.Add(LNewOrders.ExtractAt(0));
  finally
    LNewOrders.Free;
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
      sfTumu: ;
      sfHazirlaniyor:
        if LOrder.Durum <> osHazirlaniyor then Continue;
      sfYolda:
        if LOrder.Durum <> osYolda then Continue;
      sfTeslimEdildi:
        if LOrder.Durum <> osTeslimEdildi then Continue;
      sfIptal:
        if LOrder.Durum <> osIptal then Continue;
    end;

    if FSearchText <> '' then
    begin
      if not (LOrder.MusteriAdi.ToLower.Contains(FSearchText.ToLower) or
              LOrder.MusteriAdres.ToLower.Contains(FSearchText.ToLower)) then
        Continue;
    end;

    FFilteredOrders.Add(LOrder);
  end;
end;

procedure TFrmSiparisler.ApplySearch(const AText: string);
begin
  FSearchText := AText;
  ApplyFilter;
end;

procedure TFrmSiparisler.OnFilterChange(AFilter: TSiparisFilter);
begin
  FCurrentFilter := AFilter;
  ApplyFilter;
end;

procedure TFrmSiparisler.OnSearchChange(const AText: string);
begin
  ApplySearch(AText);
end;

procedure TFrmSiparisler.OnOrderClick(AOrderId: Integer);
begin
  // Navigate to order detail
end;

procedure TFrmSiparisler.OnLoadMore;
begin
  if FHasMore then
  begin
    Inc(FCurrentPage);
    LoadOrders;
  end;
end;

procedure TFrmSiparisler.OnRefresh;
begin
  FOrders.Clear;
  FCurrentPage := 1;
  FHasMore := True;
  LoadOrders;
end;

function TFrmSiparisler.GetOrderCount: Integer;
begin
  Result := FOrders.Count;
end;

function TFrmSiparisler.GetFilteredCount: Integer;
begin
  Result := FFilteredOrders.Count;
end;

end.
