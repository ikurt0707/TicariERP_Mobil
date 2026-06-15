unit uFrmMusteriSec;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.SearchBox, FMX.Edit,
  uConstants, uCustomer;

type
  TOnMusteriSelected = procedure(ACariID: Integer; const ACariAdi, ATelefon: string) of object;

  TFrmMusteriSec = class(TForm)
    LayoutMain: TLayout;
    LayoutHeader: TLayout;
    RectHeader: TRectangle;
    BtnGeri: TSpeedButton;
    LblTitle: TLabel;
    LayoutSearch: TLayout;
    RectSearchBg: TRectangle;
    EdtSearch: TSearchBox;
    LayoutContent: TLayout;
    ListViewMusteriler: TListView;
    procedure BtnGeriClick(Sender: TObject);
    procedure EdtSearchChangeTracking(Sender: TObject);
    procedure ListViewMusterilerItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure FormCreate(Sender: TObject);
  private
    FOnMusteriSelected: TOnMusteriSelected;
    FSearchTimer: TTimer;
    procedure DoSearch(const AQuery: string);
    procedure OnSearchTimer(Sender: TObject);
  public
    property OnMusteriSelected: TOnMusteriSelected read FOnMusteriSelected write FOnMusteriSelected;
  end;

var
  FrmMusteriSec: TFrmMusteriSec;

implementation

{$R *.fmx}

uses
  uApiService;

procedure TFrmMusteriSec.FormCreate(Sender: TObject);
begin
  FSearchTimer := TTimer.Create(Self);
  FSearchTimer.Interval := 500;
  FSearchTimer.Enabled := False;
  FSearchTimer.OnTimer := OnSearchTimer;
end;

procedure TFrmMusteriSec.BtnGeriClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmMusteriSec.EdtSearchChangeTracking(Sender: TObject);
begin
  FSearchTimer.Enabled := False;
  FSearchTimer.Enabled := True;
end;

procedure TFrmMusteriSec.OnSearchTimer(Sender: TObject);
begin
  FSearchTimer.Enabled := False;
  if EdtSearch.Text.Length >= 2 then
    DoSearch(EdtSearch.Text);
end;

procedure TFrmMusteriSec.DoSearch(const AQuery: string);
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LItem: TListViewItem;
  LObj: TJSONObject;
  I: Integer;
begin
  ListViewMusteriler.Items.Clear;

  LResponse := ApiService.Get('rest/TSmCari/SearchCari/' + AQuery + '/1/20');
  try
    if LResponse.Success and Assigned(LResponse.Data) and (LResponse.Data is TJSONObject) then
    begin
      LData := TJSONObject(LResponse.Data);
      if LData.TryGetValue<TJSONArray>('data', LArray) then
      begin
        for I := 0 to LArray.Count - 1 do
        begin
          LObj := LArray.Items[I] as TJSONObject;
          LItem := ListViewMusteriler.Items.Add;
          LItem.Text := LObj.GetValue<string>('cariAdi', '');
          LItem.Detail := LObj.GetValue<string>('telefon', '') + ' - ' +
                          LObj.GetValue<string>('adres', '');
          LItem.Tag := LObj.GetValue<Integer>('cariId', 0);
          LItem.Data['telefon'] := LObj.GetValue<string>('telefon', '');
        end;
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TFrmMusteriSec.ListViewMusterilerItemClick(const Sender: TObject;
  const AItem: TListViewItem);
var
  LCariID: Integer;
  LCariAdi, LTelefon: string;
begin
  LCariID := AItem.Tag;
  LCariAdi := AItem.Text;
  LTelefon := AItem.Data['telefon'].ToString;

  if Assigned(FOnMusteriSelected) then
    FOnMusteriSelected(LCariID, LCariAdi, LTelefon);

  Close;
end;

end.
