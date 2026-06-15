unit uFrmLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  FMX.Effects,
  uConstants;

type
  TFrmLogin = class(TForm)
    LayoutMain: TLayout;
    LayoutLogo: TLayout;
    ImgLogo: TImage;
    LblAppName: TLabel;
    LayoutForm: TLayout;
    RectFormBg: TRectangle;
    LayoutFormContent: TLayout;
    LblKullaniciAdi: TLabel;
    EdtKullaniciAdi: TEdit;
    LblSifre: TLabel;
    EdtSifre: TEdit;
    ChkBeniHatirla: TCheckBox;
    BtnGiris: TCornerButton;
    LayoutError: TLayout;
    LblError: TLabel;
    LayoutVersion: TLayout;
    LblVersion: TLabel;
    procedure BtnGirisClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FLoginSuccess: Boolean;
    procedure DoLogin;
    procedure ShowError(const AMessage: string);
    procedure ClearError;
    procedure SaveCredentials;
    procedure LoadCredentials;
  public
    property LoginSuccess: Boolean read FLoginSuccess;
  end;

var
  FrmLogin: TFrmLogin;

implementation

{$R *.fmx}

uses
  uApiService, uAuthService;

procedure TFrmLogin.FormCreate(Sender: TObject);
begin
  FLoginSuccess := False;
  LblVersion.Text := 'v' + APP_VERSION;
  ClearError;
  LoadCredentials;
end;

procedure TFrmLogin.BtnGirisClick(Sender: TObject);
begin
  ClearError;
  DoLogin;
end;

procedure TFrmLogin.DoLogin;
var
  LResponse: TApiResponse;
  LRoot: TJSONObject;
  LData: TJSONObject;
  LUser, LTenant: TJSONObject;
  LResultArray: TJSONArray;
  LToken: string;
begin
  if EdtKullaniciAdi.Text.Trim = '' then
  begin
    ShowError('Kullanici adi giriniz');
    Exit;
  end;
  if EdtSifre.Text.Trim = '' then
  begin
    ShowError('Sifre giriniz');
    Exit;
  end;

  BtnGiris.Enabled := False;
  try
    LResponse := ApiService.Get(
      'rest/TSmAuth/Login/' +
      EdtKullaniciAdi.Text.Trim + '/' +
      EdtSifre.Text.Trim
    );
    try
      if not Assigned(LResponse) then
      begin
        ShowError('Sunucudan cevap alinamadi');
        Exit;
      end;

      if not LResponse.Success then
      begin
        ShowError('Baglanti hatasi: ' + LResponse.ErrorMessage);
        Exit;
      end;

      if not (LResponse.Data is TJSONObject) then
      begin
        ShowError('Gecersiz sunucu yaniti');
        Exit;
      end;

      LRoot := TJSONObject(LResponse.Data);

      if not LRoot.TryGetValue<TJSONArray>('result', LResultArray) then
      begin
        ShowError('Sunucu result bos dondu');
        Exit;
      end;

      if (LResultArray = nil) or (LResultArray.Count = 0) then
      begin
        ShowError('Sunucu result bos dondu');
        Exit;
      end;

      if not (LResultArray.Items[0] is TJSONObject) then
      begin
        ShowError('Gecersiz login yaniti');
        Exit;
      end;

      LData := TJSONObject(LResultArray.Items[0]);

      if not LData.GetValue<Boolean>('success', False) then
      begin
        ShowError(LData.GetValue<string>('message', 'Giris basarisiz'));
        Exit;
      end;

      LToken := LData.GetValue<string>('token', '');
      if LToken = '' then
      begin
        ShowError('Token bos geldi');
        Exit;
      end;

      ApiService.SetToken(LToken);

      LUser := LData.GetValue<TJSONObject>('user');
      if Assigned(LUser) then
        AuthService.SetUserInfo(
          LUser.GetValue<Integer>('userId', 0),
          LUser.GetValue<string>('kullaniciAdi', ''),
          LUser.GetValue<string>('adSoyad', ''),
          LUser.GetValue<Integer>('rolId', 0),
          LUser.GetValue<Boolean>('kurye', False)
        );

      LTenant := LData.GetValue<TJSONObject>('tenant');
      if Assigned(LTenant) then
        AuthService.SetTenantInfo(
          LTenant.GetValue<Integer>('tenantId', 0),
          LTenant.GetValue<string>('tenantAdi', '')
        );

      if ChkBeniHatirla.IsChecked then
        SaveCredentials;

      FLoginSuccess := True;
      Close;
    finally
      LResponse.Free;
    end;
  finally
    BtnGiris.Enabled := True;
  end;
end;

procedure TFrmLogin.ShowError(const AMessage: string);
begin
  LblError.Text := AMessage;
end;

procedure TFrmLogin.ClearError;
begin
  LblError.Text := '';
end;

procedure TFrmLogin.SaveCredentials;
begin
  // Platform-specific
end;

procedure TFrmLogin.LoadCredentials;
begin
  // Platform-specific
end;

end.
