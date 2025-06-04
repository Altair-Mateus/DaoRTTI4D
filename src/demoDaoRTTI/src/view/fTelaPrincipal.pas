unit fTelaPrincipal;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Imaging.pngimage,
  ShellAPI;

type
  TfrmTelaPrincipal = class(TForm)
    pnlPrincipal: TPanel;
    pnlTitulo: TPanel;
    pnlCentral: TPanel;
    pnlFundoInserir: TPanel;
    pnlInserir: TPanel;
    pnlImgInserir: TPanel;
    Image1: TImage;
    pnlDadosInserir: TPanel;
    lblInserir: TLabel;
    btnInsert: TButton;
    pnlFundoBuscar: TPanel;
    pnlBuscar: TPanel;
    pnlImgBuscar: TPanel;
    imgBuscar: TImage;
    pnlDadosBuscar: TPanel;
    lblBuscar: TLabel;
    pnlFundoDeletar: TPanel;
    pnlDeletar: TPanel;
    pnlImgDeletar: TPanel;
    imgDeletar: TImage;
    pnlDadosDeletar: TPanel;
    lblDeletar: TLabel;
    pnlFundoAlterar: TPanel;
    pnlAlterar: TPanel;
    pnlImgAlterar: TPanel;
    imgAlterar: TImage;
    pnlDadosAlterar: TPanel;
    lblAlterar: TLabel;
    btnUpdateSQL: TButton;
    btnUpdatePK: TButton;
    btnUpdateProp: TButton;
    btnDeleteByPK: TButton;
    btnDeleteSQL: TButton;
    btnDeleteProp: TButton;
    btnLoad: TButton;
    pnlInferior: TPanel;
    lblDev: TLabel;
    btnGithub: TButton;
    btnLinkedin: TButton;
    procedure btnInsertClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnUpdateSQLClick(Sender: TObject);
    procedure btnUpdatePKClick(Sender: TObject);
    procedure btnUpdatePropClick(Sender: TObject);
    procedure btnDeleteSQLClick(Sender: TObject);
    procedure btnDeleteByPKClick(Sender: TObject);
    procedure btnDeletePropClick(Sender: TObject);
    procedure btnGithubClick(Sender: TObject);
    procedure btnLinkedinClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmTelaPrincipal: TfrmTelaPrincipal;

implementation

{$R *.dfm}

uses uUsuario;

procedure TfrmTelaPrincipal.btnDeleteByPKClick(Sender: TObject);
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try

    lUsuario.Id := 1;

    if lUsuario.DeleteByPk then
      ShowMessage('Registro EXCLUIDO')

  finally
    lUsuario.Free;
  end;
end;

procedure TfrmTelaPrincipal.btnDeletePropClick(Sender: TObject);
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try

    lUsuario.Login := '10';
    lUsuario.Senha := 'teste';

    lUsuario.AddPropertyToWhere('Login');
    lUsuario.AddPropertyToWhere('Senha');

    if lUsuario.DeleteByProp then
      ShowMessage('Registro EXCLUIDO')

  finally
    lUsuario.Free;
  end;
end;

procedure TfrmTelaPrincipal.btnDeleteSQLClick(Sender: TObject);
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try

    lUsuario.Id := 3;

    if lUsuario.DeleteBySQLText('ID = ' + IntToStr(lUsuario.Id)) then
      ShowMessage('Registro EXCLUIDO')

  finally
    lUsuario.Free;
  end;
end;

procedure TfrmTelaPrincipal.btnGithubClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://github.com/Altair-Mateus', nil, nil,
    SW_SHOWNORMAL);
end;

procedure TfrmTelaPrincipal.btnInsertClick(Sender: TObject);
var
  lUsuario: TUsuario;
begin
  lUsuario := TUsuario.Create;
  try

    lUsuario.Nome := 'Altair Mateus';
    lUsuario.Login := 'altair123';
    lUsuario.Senha := '12345';
    lUsuario.Status := 'A';
    lUsuario.Data_Cadastro := Now;
    lUsuario.User_Admin := 'N';

    if (lUsuario.Insert) then
      ShowMessage('Registro gravado')

  finally
    lUsuario.Free;
  end;
end;

procedure TfrmTelaPrincipal.btnLinkedinClick(Sender: TObject);
begin
ShellExecute(0, 'open', 'https://www.linkedin.com/in/altair-mateus-t-alencastro/', nil, nil,
    SW_SHOWNORMAL);
end;

procedure TfrmTelaPrincipal.btnLoadClick(Sender: TObject);
var
  lUsuario: TUsuario;
begin
  lUsuario := TUsuario.Create;
  try

    lUsuario.Id := 1;

    if lUsuario.LoadObjectByPK then
      ShowMessage(lUsuario.Nome + ' ' + lUsuario.Login)

  finally
    lUsuario.Free;
  end;
end;

procedure TfrmTelaPrincipal.btnUpdatePKClick(Sender: TObject);
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try

    lUsuario.Id := 1;
    lUsuario.Nome := 'teste UpdateByPK';
    lUsuario.Login := '10';
    lUsuario.Senha := '12345';
    lUsuario.Status := 'A';
    lUsuario.Data_Cadastro := Now;
    lUsuario.Senha_Temp := 'N';
    lUsuario.User_Admin := 'N';

    if lUsuario.UpdateByPK then
      ShowMessage('Registro Editado')

  finally
    lUsuario.Free;
  end;
end;

procedure TfrmTelaPrincipal.btnUpdatePropClick(Sender: TObject);
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try

    lUsuario.Nome := 'teste UpdateByProp';
    lUsuario.Login := 'altair123';
    lUsuario.Senha := '12345';
    lUsuario.Status := 'A';
    lUsuario.Data_Cadastro := Now;
    lUsuario.Senha_Temp := 'N';
    lUsuario.User_Admin := 'N';

    lUsuario.AddPropertyToWhere('login');

    if lUsuario.UpdateByProp then
      ShowMessage('Registro Editado')

  finally
    lUsuario.Free;
  end;
end;

procedure TfrmTelaPrincipal.btnUpdateSQLClick(Sender: TObject);
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try

    lUsuario.Id := 17;
    lUsuario.Nome := 'teste UpdateByText';
    lUsuario.Login := '10';
    lUsuario.Senha := '12345';
    lUsuario.Status := 'A';
    lUsuario.Data_Cadastro := Now;
    lUsuario.Senha_Temp := 'N';
    lUsuario.User_Admin := 'N';

    if lUsuario.UpdateBySQLText(' LOGIN = ' + QuotedStr(lUsuario.Login)) then
      ShowMessage('Registro EDITADO')

  finally
    lUsuario.Free;
  end;
end;

end.
