unit uUsuario;

interface

uses
  uDBAttributes, uDaoRTTI, SistemaFinanceiro.Model.uSFQuery,
  System.SysUtils, Vcl.Forms, Winapi.Windows, BCrypt;

type

  [TDBTable('USUARIOS')]
  TUsuario = class

  private
    FDaoRTTI: TDaoRTTI;
    FLogin: String;
    FNome: String;
    FId: Integer;
    FSenha_Temp: String;
    FSenha: String;
    FStatus: String;
    FData_Cadastro: TDate;
    FUser_Admin: String;
    FTable_Name: String;

  CONST
    TEMP_PASSWORD = '12345';
  public

    [TDBColumnAttribute('ID', True)]
    property Id: Integer read FId write FId;
    [TDBColumnAttribute('NOME')]
    property Nome: String read FNome write FNome;
    [TDBColumnAttribute('LOGIN')]
    property Login: String read FLogin write FLogin;
    [TDBColumnAttribute('SENHA')]
    property Senha: String read FSenha write FSenha;
    [TDBColumnAttribute('STATUS')]
    property Status: String read FStatus write FStatus;
    [TDBColumnAttribute('DATA_CADASTRO')]
    property Data_Cadastro: TDate read FData_Cadastro write FData_Cadastro;
//    [TDBColumnAttribute('SENHA_TEMP', False, False, True)]
    property Senha_Temp: String read FSenha_Temp write FSenha_Temp;
//    [TDBColumnAttribute('USER_ADMIN', False, False, True)]
    property User_Admin: String read FUser_Admin write FUser_Admin;

    function Insert: Boolean;
    function UpdateBySQLText(const pWhereClause: string = ''): Boolean;
    function UpdateByPK: Boolean;
    function UpdateByProp: Boolean;
    function DeleteBySQLText(const pWhere: String = ''): Boolean;
    function DeleteByPk: Boolean;
    function DeleteByProp: Boolean;
    function LoadObjectByPK: Boolean;
    procedure ResetPropertiesToDefault;
    procedure AddPropertyToWhere(const APropertyName: String);

    constructor Create;
    destructor Destroy; override;

    function Existe(const pId: Integer;
      const pCarrega: Boolean = False): Boolean;

  end;

implementation

procedure TUsuario.AddPropertyToWhere(const APropertyName: String);
begin
  FDaoRTTI.AddPropertyToWhere(APropertyName);
end;

constructor TUsuario.Create;
begin
  FDaoRTTI := TDaoRTTI.Create;
  ResetPropertiesToDefault;
end;

function TUsuario.DeleteByPk: Boolean;
begin
  Result := FDaoRTTI.DeleteByPk(Self);
end;

function TUsuario.DeleteByProp: Boolean;
begin
  Result := FDaoRTTI.DeleteByProp(Self);
end;

function TUsuario.DeleteBySQLText(const pWhere: String): Boolean;
begin
  Result := FDaoRTTI.DeleteBySQLText(Self, pWhere);
end;

destructor TUsuario.Destroy;
begin
  FDaoRTTI.Free;
  inherited;
end;

function TUsuario.Existe(const pId: Integer; const pCarrega: Boolean): Boolean;
var
  lQuery: TSFQuery;
begin
  Result := False;
  lQuery := TSFQuery.Create(nil);
  try
    try
      lQuery.Close;
      lQuery.SQL.Clear;
      lQuery.SQL.Add(' SELECT ID FROM USUARIOS ');
      lQuery.SQL.Add(' WHERE ID = :ID          ');
      lQuery.ParamByName('ID').AsInteger := pId;
      lQuery.Open;

      if (lQuery.RecordCount > 0) then
      begin
        if pCarrega then
        begin
          FId := pId;
          Result := LoadObjectByPK;
        end
        else
        begin
          Result := True;
        end;
      end;

    except
      on E: Exception do
      begin
        Application.MessageBox(PWideChar('Erro ao realizar a consulta: ' +
          E.Message), 'Atenção', MB_OK + MB_ICONERROR);
      end;
    end;
  finally
    lQuery.Free;
  end;

end;

function TUsuario.Insert: Boolean;
begin
  Result := FDaoRTTI.Insert(Self);
end;

function TUsuario.LoadObjectByPK: Boolean;
begin
  Result := FDaoRTTI.LoadObjectByPK(Self);
end;

procedure TUsuario.ResetPropertiesToDefault;
begin
  FDaoRTTI.ResetPropertiesToDefault(Self);
end;

function TUsuario.UpdateByPK: Boolean;
begin
  Result := FDaoRTTI.UpdateByPK(Self);
end;

function TUsuario.UpdateByProp: Boolean;
begin
  Result := FDaoRTTI.UpdateByProp(Self);
end;

function TUsuario.UpdateBySQLText(const pWhereClause: string): Boolean;
begin
  Result := FDaoRTTI.UpdateBySQLText(Self, pWhereClause);
end;

end.
