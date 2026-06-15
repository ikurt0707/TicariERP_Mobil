unit uFrmYeniSiparis;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON, System.Generics.Collections, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.Edit, FMX.Memo,
  uCustomer, uOrder, uConstants;

type
  TSepetItem = record
    StokID: Integer;
    StokAdi: string;
    BirimFiyat: Currency;
    Miktar: Integer;
    function Toplam: Currency;
  end;

  TFrmYeniSiparis = class(TForm)
    LayoutMain: TLayout;
    LayoutHeader: TLayout;
    RectHeader: TRectangle;
    BtnBack: TSpeedButton;
    LblHeaderTitle: TLabel;
    LayoutContent: TLayout;
    ScrollContent: TVertScrollBox;
    LayoutMusteri: TLayout;
    LblMusteriLabel: TLabel;
    LayoutMusteriSec: TLayout;
    LblMusteriAdi: TLabel;
    BtnMusteriSec: TCornerButton;
    LayoutUrunArama: TLayout;
    LblUrunLabel: TLabel;
    EdtUrunArama: TEdit;
    ListViewUrunler: TListView;
    LayoutSepet: TLayout;
    LblSepetLabel: TLabel;
    ListViewSepet: TListView;
    LayoutNot: TLayout;
    LblNotTitle: TLabel;
    RectNot: TRectangle;
    MemoNot: TMemo;
    LayoutFooter: TLayout;
    RectFooter: TRectangle;
    LayoutTotal: TLayout;
    LblToplamLabel: TLabel;
    LblToplamTutar: TLabel;
    BtnSiparisiKaydet: TCornerButton;
    procedure BtnBackClick(Sender: TObject);
    procedure BtnMusteriSecClick(Sender: TObject);
    procedure BtnSiparisiKaydetClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EdtUrunAramaChangeTracking(Sender: TObject);
    procedure ListViewUrunlerItemClick(const Sender: TObject;
      const AItem: TListViewItem);
  private
    FSepet: TList<TSepetItem>;
    FAramaLogID: Integer;
    FCariID: Integer;
    FSearchTimer: TTimer;
    procedure UpdateTotal;
    procedure UpdateSepetListView;
    procedure SearchProducts(const AQuery: string);
    procedure OnSearchTimer(Sender: TObject);
    procedure OnMusteriSelected(ACariID: Integer; const ACariAdi, ATelefon: string);
    procedure AddToSepet(AStokID: Integer; const AStokAdi: string; AFiyat: Currency);
  public
    procedure SetFromIncomingCall(AAramaLogID: Integer; const ATelefon, ACariAdi: string);
    procedure ResetForm;
  end;

var
  FrmYeniSiparis: TFrmYeniSiparis;

implementation

{$R *.fmx}

uses
  uApiService, uHelpers, uFrmMusteriSec;

{ TSepetItem }

function TSepetItem.Toplam: Currency;
begin
  Result := BirimFiyat * Miktar;
end;

{ TFrmYeniSiparis }

procedure TFrmYeniSiparis.FormCreate(Sender: TObject);
begin
  FSepet := TList<TSepetItem>.Create;
  FAramaLogID := 0;
  FCariID := 0;

  FSearchTimer := TTimer.Create(Self);
  FSearchTimer.Interval := 500;
  FSearchTimer.Enabled := False;
  FSearchTimer.OnTimer := OnSearchTimer;
end;

procedure TFrmYeniSiparis.ResetForm;
begin
  FAramaLogID := 0;
  FCariID := 0;
  FSepet.Clear;
  MemoNot.Text := '';
  LblMusteriAdi.Text := 'Musteri seciniz';
  LblHeaderTitle.Text := 'Yeni Siparis';
  EdtUrunArama.Text := '';
  ListViewUrunler.Items.Clear;
  UpdateSepetListView;
  UpdateTotal;
end;

procedure TFrmYeniSiparis.SetFromIncomingCall(AAramaLogID: Integer;
  const ATelefon, ACariAdi: string);
begin
  ResetForm;
  FAramaLogID := AAramaLogID;
  if ACariAdi <> '' then
    LblMusteriAdi.Text := ACariAdi
  else
    LblMusteriAdi.Text := ATelefon + ' (Kayitsiz)';
  LblHeaderTitle.Text := 'Yeni Siparis (Gelen Cagri)';
end;

procedure TFrmYeniSiparis.OnMusteriSelected(ACariID: Integer;
  const ACariAdi, ATelefon: string);
begin
  FCariID := ACariID;
  LblMusteriAdi.Text := ACariAdi;
end;

procedure TFrmYeniSiparis.EdtUrunAramaChangeTracking(Sender: TObject);
begin
  FSearchTimer.Enabled := False;
  FSearchTimer.Enabled := True;
end;

procedure TFrmYeniSiparis.OnSearchTimer(Sender: TObject);
begin
  FSearchTimer.Enabled := False;
  if EdtUrunArama.Text.Length >= 2 then
    SearchProducts(EdtUrunArama.Text)
  else
    ListViewUrunler.Items.Clear;
end;

procedure TFrmYeniSiparis.SearchProducts(const AQuery: string);
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LItem: TListViewItem;
  LObj: TJSONObject;
  I: Integer;
begin
  ListViewUrunler.Items.Clear;
  LResponse := ApiService.Get('rest/TSmStok/SearchStok/' + AQuery);
  try
    LData := ExtractDSResult(LResponse);
    if Assigned(LData) and LData.TryGetValue<TJSONArray>('data', LArray) then
    begin
      for I := 0 to LArray.Count - 1 do
      begin
        LObj := LArray.Items[I] as TJSONObject;
        LItem := ListViewUrunler.Items.Add;
        LItem.Text := LObj.GetValue<string>('stokAdi', '');
        LItem.Detail := THelpers.FormatCurrency(LObj.GetValue<Double>('satisFiyat', 0)) +
                        ' | ' + LObj.GetValue<string>('kategori', '');
        LItem.Tag := LObj.GetValue<Integer>('stokId', 0);
        LItem.Data['fiyat'] := LObj.GetValue<Double>('satisFiyat', 0);
        LItem.Data['stokAdi'] := LObj.GetValue<string>('stokAdi', '');
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TFrmYeniSiparis.ListViewUrunlerItemClick(const Sender: TObject;
  const AItem: TListViewItem);
var
  LStokID: Integer;
  LStokAdi: string;
  LFiyat: Double;
  LFiyatStr: string;
begin
  LStokID := AItem.Tag;
  LStokAdi := AItem.Data['stokAdi'].ToString;
  LFiyat := Double(AItem.Data['fiyat'].AsExtended);

  LFiyatStr := FloatToStr(LFiyat);
  if InputQuery('Fiyat', 'Birim fiyat (degistirebilirsiniz):', LFiyatStr) then
  begin
    LFiyat := StrToFloatDef(LFiyatStr, LFiyat);
    AddToSepet(LStokID, LStokAdi, LFiyat);
  end;
end;

procedure TFrmYeniSiparis.AddToSepet(AStokID: Integer; const AStokAdi: string; AFiyat: Currency);
var
  I: Integer;
  LItem: TSepetItem;
begin
  for I := 0 to FSepet.Count - 1 do
  begin
    if FSepet[I].StokID = AStokID then
    begin
      LItem := FSepet[I];
      LItem.Miktar := LItem.Miktar + 1;
      LItem.BirimFiyat := AFiyat;
      FSepet[I] := LItem;
      UpdateSepetListView;
      UpdateTotal;
      Exit;
    end;
  end;

  LItem.StokID := AStokID;
  LItem.StokAdi := AStokAdi;
  LItem.BirimFiyat := AFiyat;
  LItem.Miktar := 1;
  FSepet.Add(LItem);
  UpdateSepetListView;
  UpdateTotal;
end;

procedure TFrmYeniSiparis.UpdateSepetListView;
var
  I: Integer;
  LItem: TListViewItem;
begin
  ListViewSepet.Items.Clear;
  for I := 0 to FSepet.Count - 1 do
  begin
    LItem := ListViewSepet.Items.Add;
    LItem.Text := FSepet[I].StokAdi + ' x' + IntToStr(FSepet[I].Miktar);
    LItem.Detail := THelpers.FormatCurrency(FSepet[I].Toplam);
    LItem.Tag := I;
  end;
end;

procedure TFrmYeniSiparis.UpdateTotal;
var
  I: Integer;
  LTotal: Currency;
begin
  LTotal := 0;
  for I := 0 to FSepet.Count - 1 do
    LTotal := LTotal + FSepet[I].Toplam;
  LblToplamTutar.Text := THelpers.FormatCurrency(LTotal);
end;

procedure TFrmYeniSiparis.BtnBackClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmYeniSiparis.BtnMusteriSecClick(Sender: TObject);
var
  LForm: TFrmMusteriSec;
begin
  LForm := TFrmMusteriSec.Create(Application);
  LForm.OnMusteriSelected := OnMusteriSelected;
  LForm.Show;
end;

procedure TFrmYeniSiparis.BtnSiparisiKaydetClick(Sender: TObject);
var
  LBody: TJSONObject;
  LItems: TJSONArray;
  LItem: TJSONObject;
  LResponse: TApiResponse;
  LData: TJSONObject;
  I: Integer;
begin
  if FCariID <= 0 then
  begin
    ShowMessage('Lutfen musteri seciniz.');
    Exit;
  end;
  if FSepet.Count = 0 then
  begin
    ShowMessage('Lutfen en az bir urun ekleyiniz.');
    Exit;
  end;

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('cariId', TJSONNumber.Create(FCariID));
    LBody.AddPair('aciklama', MemoNot.Text);
    LBody.AddPair('siparisKaynak', 'Mobil');

    if FAramaLogID > 0 then
    begin
      LBody.AddPair('aramaLogId', TJSONNumber.Create(FAramaLogID));
      LBody.AddPair('siparisKaynak', 'CallerID');
    end;

    LItems := TJSONArray.Create;
    for I := 0 to FSepet.Count - 1 do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('stokId', TJSONNumber.Create(FSepet[I].StokID));
      LItem.AddPair('stokAdi', FSepet[I].StokAdi);
      LItem.AddPair('miktar', TJSONNumber.Create(FSepet[I].Miktar));
      LItem.AddPair('birimFiyat', TJSONNumber.Create(Double(FSepet[I].BirimFiyat)));
      LItems.AddElement(LItem);
    end;
    LBody.AddPair('items', LItems);

    LResponse := ApiService.Post('rest/TSmSiparis/CreateSiparis/', LBody);
    try
      LData := ExtractDSResult(LResponse);
      if Assigned(LData) and LData.GetValue<Boolean>('success', False) then
      begin
        ShowMessage('Siparis basariyla kaydedildi!');
        ResetForm;
        Close;
      end
      else
        ShowMessage('Hata: ' + LResponse.ErrorMessage);
    finally
      LResponse.Free;
    end;
  finally
    LBody.Free;
  end;
end;

end.
