unit fTesteDaoRTTI;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, uDBAttributes;

type
  TfrmTesteDaoRTTI = class(TForm)
    btnInsert: TButton;
    btnUpdateSQL: TButton;
    btnDeleteSQL: TButton;
    btnLoad: TButton;
    btnUpdatePK: TButton;
    btnUpdateProp: TButton;
    btnDeleteByPK: TButton;
    btnDeleteProp: TButton;
    procedure btnInsertClick(Sender: TObject);
    procedure btnUpdateSQLClick(Sender: TObject);
    procedure btnDeleteSQLClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnUpdatePropClick(Sender: TObject);
    procedure btnUpdatePKClick(Sender: TObject);
    procedure btnDeleteByPKClick(Sender: TObject);
    procedure btnDeletePropClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmTesteDaoRTTI: TfrmTesteDaoRTTI;

implementation

{$R *.dfm}

uses uUsuario;

procedure TfrmTesteDaoRTTI.btnDeletePropClick(Sender: TObject);
var
  lUsuario : TUsuario;

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

procedure TfrmTesteDaoRTTI.btnInsertClick(Sender: TObject);
var
  lUsuario : TUsuario;
begin
  lUsuario := TUsuario.Create;
  try
    lUsuario.Id := 11;
    lUsuario.Nome := 'Mateus';
    lUsuario.Login := '10';
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

procedure TfrmTesteDaoRTTI.btnUpdateSQLClick(Sender: TObject);
var
  lUsuario : TUsuario;

begin

  lUsuario := TUsuario.Create;

  try

    lUsuario.Id := 17;
    lUsuario.Nome := 'teste UpdateByText';
    lUsuario.Login := '10';
    lUsuario.Senha := '12345';
    lUsuario.Status := 'A';
    lUsuario.Data_Cadastro := now;
    lUsuario.Senha_Temp := 'N';
    lUsuario.User_Admin := 'N';

   if lUsuario.UpdateBySQLText(' LOGIN = ' + QuotedStr(lUsuario.Login)) then
      ShowMessage('Registro EDITADO')

  finally
    lUsuario.Free;

  end;

end;

procedure TfrmTesteDaoRTTI.btnDeleteSQLClick(Sender: TObject);
var
  lUsuario : TUsuario;

begin

  lUsuario := TUsuario.Create;

  try

    lUsuario.Id := 19;


    if lUsuario.DeleteBySQLText('ID = ' + IntToStr(lUsuario.Id)) then
      ShowMessage('Registro EXCLUIDO')

  finally
    lUsuario.Free;

  end;

end;

procedure TfrmTesteDaoRTTI.btnLoadClick(Sender: TObject);
var
  lUsuario : TUsuario;

begin
  lUsuario := TUsuario.Create;

  try

    lUsuario.Id := 19;


    if lUsuario.LoadObjectByPK then
      ShowMessage(lUsuario.Nome + ' ' + lUsuario.Login)

  finally
    lUsuario.Free;

  end;

end;

procedure TfrmTesteDaoRTTI.btnUpdatePKClick(Sender: TObject);
var
  lUsuario : TUsuario;

begin
  lUsuario := TUsuario.Create;


  try

    lUsuario.Id := 10;
    lUsuario.Nome := 'teste UpdateByPK';
    lUsuario.Login := '10';
    lUsuario.Senha := 'batata';
    lUsuario.Status := 'A';
    lUsuario.Data_Cadastro := now;
    lUsuario.Senha_Temp := 'N';
    lUsuario.User_Admin := 'N';

    if lUsuario.UpdateByPK then
      ShowMessage('Registro Editado')

  finally
    lUsuario.Free;

  end;

end;

procedure TfrmTesteDaoRTTI.btnUpdatePropClick(Sender: TObject);
var
  lUsuario : TUsuario;

begin
  lUsuario := TUsuario.Create;


  try


    lUsuario.Nome := 'teste UpdateByProp';
    lUsuario.Login := '10';
    lUsuario.Senha := 'batata';
    lUsuario.Status := 'A';
    lUsuario.Data_Cadastro := now;
    lUsuario.Senha_Temp := 'N';
    lUsuario.User_Admin := 'N';

    lUsuario.AddPropertyToWhere('login');

    if lUsuario.UpdateByProp then
      ShowMessage('Registro Editado')

  finally
    lUsuario.Free;

  end;

end;

procedure TfrmTesteDaoRTTI.btnDeleteByPKClick(Sender: TObject);
var
  lUsuario : TUsuario;

begin

  lUsuario := TUsuario.Create;

  try

    lUsuario.Id := 10;


    if lUsuario.DeleteByPk then
      ShowMessage('Registro EXCLUIDO')

  finally
    lUsuario.Free;

  end;

end;

end.
