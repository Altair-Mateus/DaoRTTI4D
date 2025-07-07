program DemoDaoRTTI;

uses
  Vcl.Forms,
  fTelaPrincipal in 'src\view\fTelaPrincipal.pas' {frmTelaPrincipal},
  uDaoRTTI in '..\model\uDaoRTTI.pas',
  uDBAttributes in '..\model\uDBAttributes.pas',
  uDbConfig in '..\config\uDbConfig.pas',
  uDbConnector in 'src\model\uDbConnector.pas',
  uUsuario in 'src\model\uUsuario.pas',
  System.SysUtils,
  System.UITypes,
  Vcl.Dialogs,
  Winapi.Windows,
  uDaoRTTIExceptions in '..\exceptions\uDaoRTTIExceptions.pas',
  uITransactionScope in '..\interfaces\uITransactionScope.pas',
  uTransactionScope in '..\transactions\uTransactionScope.pas',
  uDbConfigExceptions in '..\exceptions\uDbConfigExceptions.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  try

    TDbConnector.Connect;

  except
    on E: Exception do
    begin
      MessageDlg('Erro ao conectar ao banco de dados:'#13#10 + E.Message,
        mtError, [mbOK], 0);
      ExitProcess(1); // encerra o processo de forma limpa
    end;
  end;

  Application.CreateForm(TfrmTelaPrincipal, frmTelaPrincipal);
  Application.Run;

  TDbConfig.Finalize;

end.
