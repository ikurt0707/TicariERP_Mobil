unit uFrmKuryeTakip;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.TabControl,
  FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base,
  System.Generics.Collections,
  uCourier, uOrder, uConstants;

type
  TKuryeTabFilter = (ktfTumu, ktfYolda, ktfTeslimEdildi, ktfBekliyor);

  TFrmKuryeTakip = class(TForm)
  private
    FCouriers: TObjectList<TCourier>;
    FOrders: TObjectList<TOrder>;
    FCurrentFilter: TKuryeTabFilter;
    FTotalOrders: Integer;
    FYoldaCount: Integer;
    FTeslimCount: Integer;
    FBekliyorCount: Integer;

    procedure LoadCouriers;
    procedure LoadOrders;
    procedure SetupUI;
    procedure UpdateCounts;
    procedure ApplyFilter(AFilter: TKuryeTabFilter);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure OnFilterChange(AFilter: TKuryeTabFilter);
    procedure OnRefreshClick(Sender: TObject);
    procedure OnCourierClick(ACourierId: Integer);

    function GetFilteredOrders: TObjectList<TOrder>;
    function GetCourierById(AId: Integer): TCourier;

    property CurrentFilter: TKuryeTabFilter read FCurrentFilter;
    property TotalOrders: Integer read FTotalOrders;
    property YoldaCount: Integer read FYoldaCount;
    property TeslimCount: Integer read FTeslimCount;
    property BekliyorCount: Integer read FBekliyorCount;
  end;

var
  FrmKuryeTakip: TFrmKuryeTakip;

implementation

{$R *.fmx}

{ TFrmKuryeTakip }

constructor TFrmKuryeTakip.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCouriers := TObjectList<TCourier>.Create(True);
  FOrders := TObjectList<TOrder>.Create(True);
  FCurrentFilter := ktfTumu;
  SetupUI;
  LoadCouriers;
  LoadOrders;
  UpdateCounts;
end;

destructor TFrmKuryeTakip.Destroy;
begin
  FCouriers.Free;
  FOrders.Free;
  inherited;
end;

procedure TFrmKuryeTakip.SetupUI;
begin
  Caption := 'Kurye Takip';
end;

procedure TFrmKuryeTakip.LoadCouriers;
begin
  FCouriers.Clear;
  // Will load from API
end;

procedure TFrmKuryeTakip.LoadOrders;
begin
  FOrders.Clear;
  // Will load from API
end;

procedure TFrmKuryeTakip.UpdateCounts;
var
  I: Integer;
begin
  FTotalOrders := FOrders.Count;
  FYoldaCount := 0;
  FTeslimCount := 0;
  FBekliyorCount := 0;

  for I := 0 to FOrders.Count - 1 do
  begin
    case FOrders[I].Durum of
      osYolda: Inc(FYoldaCount);
      osTeslimEdildi: Inc(FTeslimCount);
      osHazirlaniyor: Inc(FBekliyorCount);
    end;
  end;
end;

procedure TFrmKuryeTakip.ApplyFilter(AFilter: TKuryeTabFilter);
begin
  FCurrentFilter := AFilter;
  // Refresh UI
end;

procedure TFrmKuryeTakip.OnFilterChange(AFilter: TKuryeTabFilter);
begin
  ApplyFilter(AFilter);
end;

procedure TFrmKuryeTakip.OnRefreshClick(Sender: TObject);
begin
  LoadCouriers;
  LoadOrders;
  UpdateCounts;
end;

procedure TFrmKuryeTakip.OnCourierClick(ACourierId: Integer);
begin
  // Show courier details
end;

function TFrmKuryeTakip.GetFilteredOrders: TObjectList<TOrder>;
var
  I: Integer;
begin
  Result := TObjectList<TOrder>.Create(False); // Non-owning
  for I := 0 to FOrders.Count - 1 do
  begin
    case FCurrentFilter of
      ktfTumu:
        Result.Add(FOrders[I]);
      ktfYolda:
        if FOrders[I].Durum = osYolda then
          Result.Add(FOrders[I]);
      ktfTeslimEdildi:
        if FOrders[I].Durum = osTeslimEdildi then
          Result.Add(FOrders[I]);
      ktfBekliyor:
        if FOrders[I].Durum = osHazirlaniyor then
          Result.Add(FOrders[I]);
    end;
  end;
end;

function TFrmKuryeTakip.GetCourierById(AId: Integer): TCourier;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FCouriers.Count - 1 do
    if FCouriers[I].Id = AId then
    begin
      Result := FCouriers[I];
      Exit;
    end;
end;

end.
