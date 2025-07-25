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
    btnInsertMultiplos: TButton;
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
    procedure btnInsertMultiplosClick(Sender: TObject);
  private
    procedure Insert;
    procedure InsertMultiplasTabelas;

    procedure UpdateByPk;
    procedure UpdateByTextSQL;
    procedure UpdateByProp;

    procedure DeleteByPk;
    procedure DeleteByTextSQL;
    procedure DeleteByProp;

    procedure LoadByPk;

  public
    { Public declarations }
  end;

var
  frmTelaPrincipal: TfrmTelaPrincipal;

implementation

{$R *.dfm}


uses
  uUsuario,
  uObsUsuarios,
  uTransactionScope;

procedure TfrmTelaPrincipal.btnDeleteByPKClick(Sender: TObject);
begin
  DeleteByPk;
end;

procedure TfrmTelaPrincipal.btnDeletePropClick(Sender: TObject);
begin
  DeleteByProp;
end;

procedure TfrmTelaPrincipal.btnDeleteSQLClick(Sender: TObject);
begin
  DeleteByTextSQL;
end;

procedure TfrmTelaPrincipal.btnGithubClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://github.com/Altair-Mateus', nil, nil,
    SW_SHOWNORMAL);
end;

procedure TfrmTelaPrincipal.btnInsertClick(Sender: TObject);
begin
  Insert;
end;

procedure TfrmTelaPrincipal.btnInsertMultiplosClick(Sender: TObject);
begin
  InsertMultiplasTabelas;
end;

procedure TfrmTelaPrincipal.btnLinkedinClick(Sender: TObject);
begin
  ShellExecute(0, 'open',
    'https://www.linkedin.com/in/altair-mateus-t-alencastro/', nil, nil,
    SW_SHOWNORMAL);
end;

procedure TfrmTelaPrincipal.btnLoadClick(Sender: TObject);
begin
  LoadByPk;
end;

procedure TfrmTelaPrincipal.btnUpdatePKClick(Sender: TObject);
begin
  UpdateByPk;
end;

procedure TfrmTelaPrincipal.btnUpdatePropClick(Sender: TObject);
begin
  UpdateByProp;
end;

procedure TfrmTelaPrincipal.btnUpdateSQLClick(Sender: TObject);
begin
  UpdateByTextSQL;
end;

procedure TfrmTelaPrincipal.DeleteByPk;
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try
    try
      lUsuario.Id := 9;

      if lUsuario.DeleteByPk then
        ShowMessage('Registro EXCLUIDO')
    except
      on E: Exception do
      begin
        // Tratar a exceção - (User Interface)
        Application.MessageBox(PWideChar(E.Message),
          'Erro ao deletar registro pela Primary Key!', MB_OK + MB_ICONERROR);
      end;
    end;
  finally
    lUsuario.Free;
  end;
end;

procedure TfrmTelaPrincipal.DeleteByProp;
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try
    try
      lUsuario.Login := '10';
      lUsuario.Senha := 'teste';

      lUsuario.AddPropertyToWhere('login');
      lUsuario.AddPropertyToWhere('senha');

      if lUsuario.DeleteByProp then
        ShowMessage('Registro EXCLUIDO')
    except
      on E: Exception do
      begin
        // Tratar a exceção no UI - (User Interface)
        Application.MessageBox(PWideChar(E.Message),
          'Erro ao deletar registro pelas Propertys Informadas!',
          MB_OK + MB_ICONERROR);
      end;
    end;
  finally
    lUsuario.Free;
  end;

end;

procedure TfrmTelaPrincipal.DeleteByTextSQL;
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try
    try
      lUsuario.Id := 3;

      if lUsuario.DeleteBySQLText('ID = ' + IntToStr(lUsuario.Id)) then
        ShowMessage('Registro EXCLUIDO')
    except
      on E: Exception do
      begin
        // Tratar a exceção no UI - (User Interface)
        Application.MessageBox(PWideChar(E.Message),
          'Erro ao deletar registro pelo SQL!', MB_OK + MB_ICONERROR);
      end;
    end;
  finally
    lUsuario.Free;
  end;

end;

procedure TfrmTelaPrincipal.Insert;
var
  lUsuario: TUsuario;
begin
  lUsuario := TUsuario.Create;
  try
    try
      lUsuario.Nome := 'Altair Mateus';
      lUsuario.Login := 'altair123';
      lUsuario.Senha := '12345';
      lUsuario.Status := 'A';
      lUsuario.Data_Cadastro := Now;
      lUsuario.User_Admin := 'N';

      if (lUsuario.Insert) then
        ShowMessage('Registro gravado')

    except
      on E: Exception do
      begin
        // Tratar a exceção no UI - (User Interface)
        Application.MessageBox(PWideChar(E.Message),
          'Erro ao inserir registro!', MB_OK + MB_ICONERROR);
      end;
    end;
  finally
    lUsuario.Free;
  end;
end;

procedure TfrmTelaPrincipal.InsertMultiplasTabelas;
var
  lUsuario: TUsuario;
  lObs: TObsUsuarios;
  lTransaction: TTransactionScope;
begin

  lTransaction := TTransactionScope.Create;

  lUsuario := TUsuario.Create;
  lObs := TObsUsuarios.Create;
  try

    lUsuario.Id := 7;
    lUsuario.Nome := 'Altair';
    lUsuario.Login := '21';
    lUsuario.Senha := '12345';
    lUsuario.Status := 'A';
    lUsuario.Data_Cadastro := Now;
    lUsuario.Senha_Temp := 'N';
    lUsuario.User_Admin := 'S';
    lUsuario.UpdateByPk;

    lObs.IdUsuario := lUsuario.Id;
    lObs.Descricao := 'Usuário alterado para administrador';
    lObs.Insert;

    lTransaction.Commit;

  finally
    lUsuario.Free;
    lObs.Free;
    lTransaction.Free;
  end;
end;

procedure TfrmTelaPrincipal.LoadByPk;
var
  lUsuario: TUsuario;
begin
  lUsuario := TUsuario.Create;
  try
    try
      lUsuario.Id := 9;

      if lUsuario.LoadObjectByPK then
        ShowMessage(lUsuario.Nome + ' ' + lUsuario.Login)
    except
      on E: Exception do
      begin
        // Tratar a exceção no UI - (User Interface)
        Application.MessageBox(PWideChar(E.Message),
          'Erro ao buscar registro pela Primary Key!', MB_OK + MB_ICONERROR);
      end;
    end;
  finally
    lUsuario.Free;
  end;

end;

procedure TfrmTelaPrincipal.UpdateByPk;
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try
    try
      lUsuario.Id := 9;
      lUsuario.Nome := 'teste UpdateByPK';
      lUsuario.Login := '10';
      lUsuario.Senha := '12345';
      lUsuario.Status := 'A';
      lUsuario.Data_Cadastro := Now;
      lUsuario.Senha_Temp := 'N';
      lUsuario.User_Admin := 'N';

      if lUsuario.UpdateByPk then
        ShowMessage('Registro Editado')
    except
      on E: Exception do
      begin
        // Tratar a exceção no UI - (User Interface)
        Application.MessageBox(PWideChar(E.Message),
          'Erro ao atualizar registro pela Primary Key!', MB_OK + MB_ICONERROR);
      end;
    end;
  finally
    lUsuario.Free;
  end;

end;

procedure TfrmTelaPrincipal.UpdateByProp;
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try
    try
      lUsuario.Nome := 'teste UpdateByProp';
      lUsuario.Login := 'altair123';
      lUsuario.Senha := '12345';
      lUsuario.Status := 'A';
      lUsuario.Data_Cadastro := Now;
      lUsuario.Senha_Temp := 'N';
      lUsuario.User_Admin := 'N';

      lUsuario.AddPropertyToWhere('login');
      lUsuario.AddPropertyToWhere('status');

      if lUsuario.UpdateByProp then
        ShowMessage('Registro Editado')
    except
      on E: Exception do
      begin
        // Tratar a exceção no UI - (User Interface)
        Application.MessageBox(PWideChar(E.Message),
          'Erro ao atualizar registro pelas Propertys Informadas!',
          MB_OK + MB_ICONERROR);
      end;
    end;
  finally
    lUsuario.Free;
  end;

end;

procedure TfrmTelaPrincipal.UpdateByTextSQL;
var
  lUsuario: TUsuario;
begin

  lUsuario := TUsuario.Create;
  try
    try
      lUsuario.Nome := 'teste UpdateByText';
      lUsuario.Login := '10';
      lUsuario.Senha := '12345';
      lUsuario.Status := 'A';
      lUsuario.Data_Cadastro := Now;
      lUsuario.Senha_Temp := 'N';
      lUsuario.User_Admin := 'N';

      if lUsuario.UpdateBySQLText(' LOGIN = ' + QuotedStr(lUsuario.Login)) then
        ShowMessage('Registro EDITADO')
    except
      on E: Exception do
      begin
        // Tratar a exceção no UI - (User Interface)
        Application.MessageBox(PWideChar(E.Message),
          'Erro ao atualizar registro por SQL!', MB_OK + MB_ICONERROR);
      end;

    end;
  finally
    lUsuario.Free;
  end;

end;

end.
