program TicariERP_Mobil;

uses
  System.StartUpCopy,
  FMX.Forms,
  uFrmMain in 'src\Forms\uFrmMain.pas' {FrmMain},
  uFrmGelenArama in 'src\Forms\uFrmGelenArama.pas' {FrmGelenArama},
  uFrmYeniSiparis in 'src\Forms\uFrmYeniSiparis.pas' {FrmYeniSiparis},
  uFrmKuryeTakip in 'src\Forms\uFrmKuryeTakip.pas' {FrmKuryeTakip},
  uFrmSiparisler in 'src\Forms\uFrmSiparisler.pas' {FrmSiparisler},
  uCustomer in 'src\Models\uCustomer.pas',
  uOrder in 'src\Models\uOrder.pas',
  uProduct in 'src\Models\uProduct.pas',
  uCourier in 'src\Models\uCourier.pas',
  uDailySummary in 'src\Models\uDailySummary.pas',
  uApiService in 'src\Services\uApiService.pas',
  uAuthService in 'src\Services\uAuthService.pas',
  uOrderService in 'src\Services\uOrderService.pas',
  uCustomerService in 'src\Services\uCustomerService.pas',
  uConstants in 'src\Utils\uConstants.pas',
  uHelpers in 'src\Utils\uHelpers.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
