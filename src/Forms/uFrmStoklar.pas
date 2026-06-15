unit uFrmStoklar;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.Edit, FMX.ListBox,
  uConstants;

type
  TFrmStoklar = class(TForm)
    LayoutMain: TLayout;
    LayoutHeader: TLayout;
    RectHeader: TRectangle;
    BtnBack: TSpeedButton;
    LblTitle: TLabel;
    BtnStokEkle: TSpeedButton;
    LayoutSearch: TLayout;
    EdtSearch: TEdit;
    ListViewStoklar: TListView;
    LayoutEklePanel: TLayout;
    RectEklePanel: TRectangle;
    LblEkleTitle: TLabel;
    LblStokAdiLabel: TLabel;
    EdtStokAdi: TEdit;
    LblAlisFiyatLabel: TLabel;
    EdtAlisFiyat: TEdit;
    LblSatisFiyatLabel: TLabel;
    EdtSatisFiyat: TEdit;
    LblKategoriLabel: TLabel;
    CmbKategori: TComboBox;
    BtnKaydet: TCornerButton;
    BtnIptal: TCornerButton;
    procedure BtnBackClick(Sender: TObject);
    procedure BtnStokEkleClick(Sender: TObject);
    procedure BtnKaydetClick(Sender: TObject);
    procedure BtnIptalClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure EdtSearchChangeTracking(Sender: TObject);
  private
    FSearchTimer: TTimer;
    procedure LoadStoklar;
    procedure LoadKategoriler;
    procedure SearchStok(const AQuery: string);
    procedure OnSearchTimer(Sender: TObject);
    procedure ShowEklePanel(AVisible: Boolean);
    procedure SaveStok;
  public
  end;

var
  FrmStoklar: TFrmStoklar;

implementation

{$R *.fmx}

uses
  uApiService, uHelpers;

procedure TFrmStoklar.FormCreate(Sender: TObject);
begin
  FSearchTimer := TTimer.Create(Self);
  FSearchTimer.Interval := 500;
  FSearchTimer.Enabled := False;
  FSearchTimer.OnTimer := OnSearchTimer;
  LayoutEklePanel.Visible := False;
end;

procedure TFrmStoklar.FormShow(Sender: TObject);
begin
  LoadStoklar;
  LoadKategoriler;
end;

procedure TFrmStoklar.LoadStoklar;
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LItem: TListViewItem;
  LObj: TJSONObject;
  I: Integer;
begin
  ListViewStoklar.Items.Clear;
  LResponse := ApiService.Get('rest/TSmStok/GetStokList/1/100');
  try
    LData := ExtractDSResult(LResponse);
    if Assigned(LData) and LData.TryGetValue<TJSONArray>('data', LArray) then
    begin
      for I := 0 to LArray.Count - 1 do
      begin
        LObj := LArray.Items[I] as TJSONObject;
        LItem := ListViewStoklar.Items.Add;
        LItem.Text := LObj.GetValue<string>('stokAdi', '');
        LItem.Detail := LObj.GetValue<string>('stokKod', '') + ' | ' +
                        THelpers.FormatCurrency(LObj.GetValue<Double>('satisFiyat', 0)) +
                        ' | ' + LObj.GetValue<string>('kategori', '');
        LItem.Tag := LObj.GetValue<Integer>('stokId', 0);
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TFrmStoklar.LoadKategoriler;
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LObj: TJSONObject;
  I: Integer;
begin
  CmbKategori.Items.Clear;
  LResponse := ApiService.Get('rest/TSmStok/GetKategoriler/');
  try
    LData := ExtractDSResult(LResponse);
    if Assigned(LData) and LData.TryGetValue<TJSONArray>('data', LArray) then
    begin
      for I := 0 to LArray.Count - 1 do
      begin
        LObj := LArray.Items[I] as TJSONObject;
        CmbKategori.Items.AddObject(
          LObj.GetValue<string>('kategoriAdi', ''),
          TObject(LObj.GetValue<Integer>('kategoriId', 0))
        );
      end;
    end;
  finally
    LResponse.Free;
  end;
  if CmbKategori.Items.Count > 0 then
    CmbKategori.ItemIndex := 0;
end;

procedure TFrmStoklar.SearchStok(const AQuery: string);
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LItem: TListViewItem;
  LObj: TJSONObject;
  I: Integer;
begin
  ListViewStoklar.Items.Clear;
  LResponse := ApiService.Get('rest/TSmStok/SearchStok/' + AQuery);
  try
    LData := ExtractDSResult(LResponse);
    if Assigned(LData) and LData.TryGetValue<TJSONArray>('data', LArray) then
    begin
      for I := 0 to LArray.Count - 1 do
      begin
        LObj := LArray.Items[I] as TJSONObject;
        LItem := ListViewStoklar.Items.Add;
        LItem.Text := LObj.GetValue<string>('stokAdi', '');
        LItem.Detail := LObj.GetValue<string>('stokKod', '') + ' | ' +
                        THelpers.FormatCurrency(LObj.GetValue<Double>('satisFiyat', 0));
        LItem.Tag := LObj.GetValue<Integer>('stokId', 0);
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TFrmStoklar.EdtSearchChangeTracking(Sender: TObject);
begin
  FSearchTimer.Enabled := False;
  FSearchTimer.Enabled := True;
end;

procedure TFrmStoklar.OnSearchTimer(Sender: TObject);
begin
  FSearchTimer.Enabled := False;
  if EdtSearch.Text.Length >= 2 then
    SearchStok(EdtSearch.Text)
  else
    LoadStoklar;
end;

procedure TFrmStoklar.ShowEklePanel(AVisible: Boolean);
begin
  LayoutEklePanel.Visible := AVisible;
  if AVisible then
  begin
    EdtStokAdi.Text := '';
    EdtAlisFiyat.Text := '';
    EdtSatisFiyat.Text := '';
    if CmbKategori.Items.Count > 0 then
      CmbKategori.ItemIndex := 0;
  end;
end;

procedure TFrmStoklar.BtnBackClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmStoklar.BtnStokEkleClick(Sender: TObject);
begin
  ShowEklePanel(True);
end;

procedure TFrmStoklar.BtnIptalClick(Sender: TObject);
begin
  ShowEklePanel(False);
end;

procedure TFrmStoklar.BtnKaydetClick(Sender: TObject);
begin
  SaveStok;
end;

procedure TFrmStoklar.SaveStok;
var
  LBody: TJSONObject;
  LResponse: TApiResponse;
  LData: TJSONObject;
  LKategoriAdi: string;
begin
  if EdtStokAdi.Text.Trim = '' then
  begin
    ShowMessage('Stok adi giriniz');
    Exit;
  end;

  LKategoriAdi := '';
  if (CmbKategori.ItemIndex >= 0) and (CmbKategori.ItemIndex < CmbKategori.Items.Count) then
    LKategoriAdi := CmbKategori.Items[CmbKategori.ItemIndex];

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('stokAdi', EdtStokAdi.Text.Trim);
    LBody.AddPair('alisFiyat', TJSONNumber.Create(StrToFloatDef(EdtAlisFiyat.Text, 0)));
    LBody.AddPair('satisFiyat', TJSONNumber.Create(StrToFloatDef(EdtSatisFiyat.Text, 0)));
    LBody.AddPair('kategori', LKategoriAdi);

    LResponse := ApiService.Post('rest/TSmStok/CreateStok/', LBody);
    try
      LData := ExtractDSResult(LResponse);
      if Assigned(LData) and LData.GetValue<Boolean>('success', False) then
      begin
        ShowMessage('Stok basariyla eklendi!');
        ShowEklePanel(False);
        LoadStoklar;
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
