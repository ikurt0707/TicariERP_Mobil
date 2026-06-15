unit uFrmGelenArama;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base,
  uConstants;

type
  TFrmGelenArama = class(TForm)
    LayoutMain: TLayout;
    LayoutHeader: TLayout;
    RectHeader: TRectangle;
    BtnBack: TSpeedButton;
    LblTitle: TLabel;
    ListViewAramalar: TListView;
    LayoutDetail: TLayout;
    RectDetail: TRectangle;
    LblDetailTitle: TLabel;
    LblCariAdi: TLabel;
    LblTelefon: TLabel;
    LblAdres: TLabel;
    LblSonSiparisTitle: TLabel;
    ListViewSonSiparisler: TListView;
    BtnSiparisOlustur: TCornerButton;
    BtnDetailKapat: TCornerButton;
    procedure BtnBackClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListViewAramalarItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure BtnSiparisOlusturClick(Sender: TObject);
    procedure BtnDetailKapatClick(Sender: TObject);
  private
    FSelectedAramaLogID: Integer;
    FSelectedTelefon: string;
    FSelectedCariAdi: string;
    FSelectedCariID: Integer;
    procedure LoadAramalar;
    procedure ShowCallDetail(AAramaLogID: Integer; const ATelefon: string);
    procedure ShowDetailPanel(AVisible: Boolean);
  public
  end;

var
  FrmGelenArama: TFrmGelenArama;

implementation

{$R *.fmx}

uses
  uApiService, uHelpers, uFrmYeniSiparis;

procedure TFrmGelenArama.FormCreate(Sender: TObject);
begin
  FSelectedAramaLogID := 0;
  FSelectedCariID := 0;
  LayoutDetail.Visible := False;
end;

procedure TFrmGelenArama.FormShow(Sender: TObject);
begin
  LoadAramalar;
end;

procedure TFrmGelenArama.LoadAramalar;
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LItem: TListViewItem;
  LObj: TJSONObject;
  I: Integer;
begin
  ListViewAramalar.Items.Clear;
  LResponse := ApiService.Get('rest/TSmCallerID/GetSonAramalar/50');
  try
    LData := ExtractDSResult(LResponse);
    if Assigned(LData) and LData.TryGetValue<TJSONArray>('data', LArray) then
    begin
      for I := 0 to LArray.Count - 1 do
      begin
        LObj := LArray.Items[I] as TJSONObject;
        LItem := ListViewAramalar.Items.Add;
        LItem.Text := LObj.GetValue<string>('cariAdi', LObj.GetValue<string>('telefon', 'Bilinmeyen'));
        LItem.Detail := LObj.GetValue<string>('telefon', '') + ' - ' +
                        LObj.GetValue<string>('tarih', '');
        LItem.Tag := LObj.GetValue<Integer>('aramaLogId', 0);
        LItem.Data['telefon'] := LObj.GetValue<string>('telefon', '');
        LItem.Data['cariAdi'] := LObj.GetValue<string>('cariAdi', '');
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TFrmGelenArama.ListViewAramalarItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  FSelectedAramaLogID := AItem.Tag;
  FSelectedTelefon := '';
  FSelectedCariAdi := '';
  if Assigned(AItem.Data['telefon']) then
    FSelectedTelefon := AItem.Data['telefon'].ToString;
  if Assigned(AItem.Data['cariAdi']) then
    FSelectedCariAdi := AItem.Data['cariAdi'].ToString;
  ShowCallDetail(FSelectedAramaLogID, FSelectedTelefon);
end;

procedure TFrmGelenArama.ShowCallDetail(AAramaLogID: Integer; const ATelefon: string);
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LCari: TJSONObject;
  LSiparisler: TJSONArray;
  LItem: TListViewItem;
  LObj: TJSONObject;
  I: Integer;
begin
  LblCariAdi.Text := '';
  LblTelefon.Text := ATelefon;
  LblAdres.Text := '';
  ListViewSonSiparisler.Items.Clear;
  FSelectedCariID := 0;

  // Cari bilgisini telefon ile bul
  LResponse := ApiService.Get('rest/TSmCari/GetCariByTelefon/' + ATelefon);
  try
    LData := ExtractDSResult(LResponse);
    if Assigned(LData) and LData.GetValue<Boolean>('found', False) then
    begin
      LCari := LData.GetValue<TJSONObject>('data');
      if Assigned(LCari) then
      begin
        FSelectedCariID := LCari.GetValue<Integer>('cariId', 0);
        FSelectedCariAdi := LCari.GetValue<string>('cariAdi', '');
        LblCariAdi.Text := FSelectedCariAdi;
        LblAdres.Text := LCari.GetValue<string>('adres', '');
      end;
    end
    else
    begin
      LblCariAdi.Text := 'Kayitsiz Musteri';
    end;
  finally
    LResponse.Free;
  end;

  // Son 2 siparis
  if FSelectedCariID > 0 then
  begin
    LResponse := ApiService.Get('rest/TSmCallerID/GetCariSonSiparisler/' +
                                IntToStr(FSelectedCariID) + '/2');
    try
      LData := ExtractDSResult(LResponse);
      if Assigned(LData) and LData.TryGetValue<TJSONArray>('data', LSiparisler) then
      begin
        for I := 0 to LSiparisler.Count - 1 do
        begin
          LObj := LSiparisler.Items[I] as TJSONObject;
          LItem := ListViewSonSiparisler.Items.Add;
          LItem.Text := LObj.GetValue<string>('tarih', '') + ' - ' +
                        LObj.GetValue<string>('durum', '');
          LItem.Detail := THelpers.FormatCurrency(LObj.GetValue<Double>('genelToplam', 0));
        end;
      end;
    finally
      LResponse.Free;
    end;
  end;

  ShowDetailPanel(True);
end;

procedure TFrmGelenArama.ShowDetailPanel(AVisible: Boolean);
begin
  LayoutDetail.Visible := AVisible;
end;

procedure TFrmGelenArama.BtnSiparisOlusturClick(Sender: TObject);
var
  LForm: TFrmYeniSiparis;
begin
  LForm := TFrmYeniSiparis.Create(Application);
  LForm.SetFromIncomingCall(FSelectedAramaLogID, FSelectedTelefon, FSelectedCariAdi);
  LForm.Show;
  ShowDetailPanel(False);
end;

procedure TFrmGelenArama.BtnDetailKapatClick(Sender: TObject);
begin
  ShowDetailPanel(False);
end;

procedure TFrmGelenArama.BtnBackClick(Sender: TObject);
begin
  Close;
end;

end.
