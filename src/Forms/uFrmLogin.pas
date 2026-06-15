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
    procedure DoLogin;
    procedure ShowError(const AMessage: string);
    procedure ClearError;
    procedure SaveCredentials;
    procedure LoadCredentials;
  public
  end;

var
  FrmLogin: TFrmLogin;

implementation

{$R *.fmx}

uses
  uApiService, uAuthService, uFrmMain;

procedure TFrmLogin.FormCreate(Sender: TObject);
begin
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
  LData: TJSONObject;
  LUser, LTenant, LDb: TJSONObject;
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

      // DataSnap result wrapper'dan veriyi cikar
      LData := ExtractDSResult(LResponse);
      if not Assigned(LData) then
      begin
        ShowError('Sunucu result bos dondu');
        Exit;
      end;

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

      // Extract user info
      LUser := LData.GetValue<TJSONObject>('user');
      if Assigned(LUser) then
      begin
        AuthService.SetUserInfo(
          LUser.GetValue<Integer>('userId', 0),
          LUser.GetValue<string>('kullaniciAdi', ''),
          LUser.GetValue<string>('adSoyad', ''),
          LUser.GetValue<Integer>('rolId', 0),
          LUser.GetValue<Boolean>('kurye', False)
        );
      end;

      // Extract tenant info
      LTenant := LData.GetValue<TJSONObject>('tenant');
      if Assigned(LTenant) then
        AuthService.SetTenantInfo(
          LTenant.GetValue<Integer>('tenantId', 0),
          LTenant.GetValue<string>('tenantAdi', '')
        );

      if ChkBeniHatirla.IsChecked then
        SaveCredentials;

      FrmMain.Show;
      Self.Hide;
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
  // Save to SharedPreferences/IsolatedStorage
  // Platform-specific implementation
end;

procedure TFrmLogin.LoadCredentials;
begin
  // Load from SharedPreferences/IsolatedStorage
  // Platform-specific implementation
end;

end.
