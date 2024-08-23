unit uTeste;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, uDBAttributes;

type
  TForm1 = class(TForm)
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
  Form1: TForm1;

implementation

{$R *.dfm}

uses uUsuario;

procedure TForm1.btnDeletePropClick(Sender: TObject);
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

procedure TForm1.btnInsertClick(Sender: TObject);
var
  lUsuario : TUsuario;
begin
  lUsuario := TUsuario.Create;
  try

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

procedure TForm1.btnUpdateSQLClick(Sender: TObject);
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

procedure TForm1.btnDeleteSQLClick(Sender: TObject);
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

procedure TForm1.btnLoadClick(Sender: TObject);
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

procedure TForm1.btnUpdatePKClick(Sender: TObject);
var
  lUsuario : TUsuario;

begin
  lUsuario := TUsuario.Create;


  try

    lUsuario.Id := 3;
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

procedure TForm1.btnUpdatePropClick(Sender: TObject);
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

procedure TForm1.btnDeleteByPKClick(Sender: TObject);
var
  lUsuario : TUsuario;

begin

  lUsuario := TUsuario.Create;

  try

    lUsuario.Id := 9;


    if lUsuario.DeleteByPk then
      ShowMessage('Registro EXCLUIDO')

  finally
    lUsuario.Free;

  end;

end;

end.
