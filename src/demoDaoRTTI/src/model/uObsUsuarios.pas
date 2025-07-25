unit uObsUsuarios;

interface

uses
  uDBAttributes,
  uDaoRTTI;

type

  [TDBTable('TBL_OBS_USUARIOS')]
  TObsUsuarios = class
  private
    FDaoRTTI: TDaoRTTI;
    FId: Integer;
    FDescricao: String;
    FIdUsuario: Integer;
  public
    [TDBColumn('ID'), TDBIsPrimaryKey, TDBIsAutoIncrement]
    property Id: Integer read FId write FId;
    [TDBColumn('DESCRICAO'), TDBAcceptNull]
    property Descricao: String read FDescricao write FDescricao;
    [TDBColumn('ID_USUARIO')]
    property IdUsuario: Integer read FIdUsuario write FIdUsuario;

    constructor Create;
    destructor Destroy; override;

    function Insert: Boolean;
    function UpdateBySQLText(const pWhereClause: string = ''): Boolean;
    function UpdateByPK: Boolean;
    function UpdateByProp: Boolean;
    function DeleteBySQLText(const pWhere: String = ''): Boolean;
    function DeleteByPk: Boolean;
    function DeleteByProp: Boolean;
    function LoadObjectByPK: Boolean;
    procedure ResetPropertiesToDefault;
    procedure AddPropertyToWhere(const pPropertyName: String);

  end;

implementation

{ TObsUsuarios }

procedure TObsUsuarios.AddPropertyToWhere(const pPropertyName: String);
begin
  FDaoRTTI.AddPropertyToWhere(pPropertyName)
end;

constructor TObsUsuarios.Create;
begin
  FDaoRTTI := TDaoRTTI.Create;
  ResetPropertiesToDefault;
end;

function TObsUsuarios.DeleteByPk: Boolean;
begin
  Result := FDaoRTTI.DeleteByPk(Self);
end;

function TObsUsuarios.DeleteByProp: Boolean;
begin
  Result := FDaoRTTI.DeleteByProp(Self);
end;

function TObsUsuarios.DeleteBySQLText(const pWhere: String): Boolean;
begin
  Result := FDaoRTTI.DeleteBySQLText(Self, pWhere);
end;

destructor TObsUsuarios.Destroy;
begin
  FDaoRTTI.Free;
  inherited;
end;

function TObsUsuarios.Insert: Boolean;
begin
  Result := FDaoRTTI.Insert(Self);
end;

function TObsUsuarios.LoadObjectByPK: Boolean;
begin
  Result := FDaoRTTI.LoadObjectByPK(Self);
end;

procedure TObsUsuarios.ResetPropertiesToDefault;
begin
  FDaoRTTI.ResetPropertiesToDefault(Self);
end;

function TObsUsuarios.UpdateByPK: Boolean;
begin
  Result := FDaoRTTI.UpdateByPK(Self);
end;

function TObsUsuarios.UpdateByProp: Boolean;
begin
  Result := FDaoRTTI.UpdateByProp(Self);
end;

function TObsUsuarios.UpdateBySQLText(const pWhereClause: string): Boolean;
begin
  Result := FDaoRTTI.UpdateBySQLText(Self, pWhereClause);
end;

end.
