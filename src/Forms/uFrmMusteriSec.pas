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
    BtnMusteriEkle: TSpeedButton;
    LayoutSearch: TLayout;
    EdtSearch: TEdit;
    ListViewMusteriler: TListView;
    LayoutEklePanel: TLayout;
    RectEklePanel: TRectangle;
    LblEkleTitle: TLabel;
    LblAdSoyadLabel: TLabel;
    EdtAdSoyad: TEdit;
    LblTelefonLabel: TLabel;
    EdtTelefon: TEdit;
    LblAdresLabel: TLabel;
    EdtAdres: TEdit;
    BtnKaydet: TCornerButton;
    BtnIptal: TCornerButton;
    BtnRehberdenEkle: TCornerButton;
    procedure BtnGeriClick(Sender: TObject);
    procedure EdtSearchChangeTracking(Sender: TObject);
    procedure ListViewMusterilerItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnMusteriEkleClick(Sender: TObject);
    procedure BtnKaydetClick(Sender: TObject);
    procedure BtnIptalClick(Sender: TObject);
    procedure BtnRehberdenEkleClick(Sender: TObject);
  private
    FOnMusteriSelected: TOnMusteriSelected;
    FSearchTimer: TTimer;
    FIsSelectMode: Boolean;
    procedure DoSearch(const AQuery: string);
    procedure OnSearchTimer(Sender: TObject);
    procedure ShowEklePanel(AVisible: Boolean);
    procedure SaveMusteri;
    procedure LoadAllMusteriler;
    procedure ImportPhoneContacts;
  public
    property OnMusteriSelected: TOnMusteriSelected read FOnMusteriSelected write FOnMusteriSelected;
    property IsSelectMode: Boolean read FIsSelectMode write FIsSelectMode;
  end;

var
  FrmMusteriSec: TFrmMusteriSec;

implementation

{$R *.fmx}

uses
  uApiService, uContactService;

procedure TFrmMusteriSec.FormCreate(Sender: TObject);
begin
  FSearchTimer := TTimer.Create(Self);
  FSearchTimer.Interval := 500;
  FSearchTimer.Enabled := False;
  FSearchTimer.OnTimer := OnSearchTimer;
  FIsSelectMode := False;
  LayoutEklePanel.Visible := False;
end;

procedure TFrmMusteriSec.FormShow(Sender: TObject);
begin
  LoadAllMusteriler;
end;

procedure TFrmMusteriSec.LoadAllMusteriler;
var
  LResponse: TApiResponse;
  LData: TJSONObject;
  LArray: TJSONArray;
  LItem: TListViewItem;
  LObj: TJSONObject;
  I: Integer;
begin
  ListViewMusteriler.Items.Clear;
  LResponse := ApiService.Get('rest/TSmCari/GetCariList/1/50');
  try
    LData := ExtractDSResult(LResponse);
    if Assigned(LData) and LData.TryGetValue<TJSONArray>('data', LArray) then
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
  finally
    LResponse.Free;
  end;
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
    DoSearch(EdtSearch.Text)
  else
    LoadAllMusteriler;
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
    LData := ExtractDSResult(LResponse);
    if Assigned(LData) and LData.TryGetValue<TJSONArray>('data', LArray) then
    begin
      for I := 0 to LArray.Count - 1 do
      begin
        LObj := LArray.Items[I] as TJSONObject;
        LItem := ListViewMusteriler.Items.Add;
        LItem.Text := LObj.GetValue<string>('cariAdi', '');
        LItem.Detail := LObj.GetValue<string>('telefon', '');
        LItem.Tag := LObj.GetValue<Integer>('cariId', 0);
        LItem.Data['telefon'] := LObj.GetValue<string>('telefon', '');
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
  LTelefon := '';
  if Assigned(AItem.Data['telefon']) then
    LTelefon := AItem.Data['telefon'].ToString;

  if Assigned(FOnMusteriSelected) then
  begin
    FOnMusteriSelected(LCariID, LCariAdi, LTelefon);
    Close;
  end;
end;

procedure TFrmMusteriSec.ShowEklePanel(AVisible: Boolean);
begin
  LayoutEklePanel.Visible := AVisible;
  if AVisible then
  begin
    EdtAdSoyad.Text := '';
    EdtTelefon.Text := '';
    EdtAdres.Text := '';
  end;
end;

procedure TFrmMusteriSec.BtnMusteriEkleClick(Sender: TObject);
begin
  ShowEklePanel(True);
end;

procedure TFrmMusteriSec.BtnIptalClick(Sender: TObject);
begin
  ShowEklePanel(False);
end;

procedure TFrmMusteriSec.BtnKaydetClick(Sender: TObject);
begin
  SaveMusteri;
end;

procedure TFrmMusteriSec.SaveMusteri;
var
  LBody: TJSONObject;
  LResponse: TApiResponse;
  LData: TJSONObject;
begin
  if EdtAdSoyad.Text.Trim = '' then
  begin
    ShowMessage('Ad soyad giriniz');
    Exit;
  end;

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('cariAdi', EdtAdSoyad.Text.Trim);
    LBody.AddPair('cariTip', 'Alici');
    LBody.AddPair('telefon', EdtTelefon.Text.Trim);
    LBody.AddPair('adres', EdtAdres.Text.Trim);

    LResponse := ApiService.Post('rest/TSmCari/CreateCariMobil/', LBody);
    try
      LData := ExtractDSResult(LResponse);
      if Assigned(LData) and LData.GetValue<Boolean>('success', False) then
      begin
        ShowMessage('Musteri basariyla eklendi!');
        ShowEklePanel(False);
        LoadAllMusteriler;
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

procedure TFrmMusteriSec.BtnRehberdenEkleClick(Sender: TObject);
begin
  ImportPhoneContacts;
end;

procedure TFrmMusteriSec.ImportPhoneContacts;
var
  LContacts: TJSONArray;
  LBody: TJSONObject;
  LResponse: TApiResponse;
  LData: TJSONObject;
begin
  LContacts := ContactService.GetAllPhoneContacts;
  if (LContacts = nil) or (LContacts.Count = 0) then
  begin
    ShowMessage('Rehberde kisi bulunamadi veya izin verilmedi.');
    LContacts.Free;
    Exit;
  end;

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('contacts', LContacts);
    LResponse := ApiService.Post('rest/TSmCari/ImportContacts/', LBody);
    try
      LData := ExtractDSResult(LResponse);
      if Assigned(LData) and LData.GetValue<Boolean>('success', False) then
      begin
        ShowMessage('Rehber kisileri basariyla eklendi! Eklenen: ' +
                    LData.GetValue<string>('eklenen', '0'));
        LoadAllMusteriler;
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
