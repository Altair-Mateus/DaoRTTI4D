unit uDaoRTTI;

interface

uses
  SysUtils,
  RTTI,
  Data.DB,
  FireDAC.Comp.Client,
  System.Variants,
  uDBAttributes,
  System.Classes;

type
  TDaoRTTI = class
  private
    FPropertiesToWhere: TStringList;
    class var FConnection: TFDConnection;

    // Verifica se a classe possui o atributo com o nome da tabela
    function CheckTableAttribute(pType: TRttiType): Boolean;
    // Verifica se a property tem o atributo com o nome da coluna do Banco de dados
    function CheckColumnsAttribute(pProperty: TRttiProperty): Boolean;
    // Realiza a conversão do tipo Variant
    function GetParameterValue(const pObject: TObject;
      const pProperty: TRttiProperty): Variant;
    // Localiza a property com o atributo de Primary Key no banco de dados
    function FindPrimaryKeyProperty(const pType: TRttiType): TRttiProperty;

  public

    function Insert(const pObject: TObject): Boolean;

    // Atualiza com base no SQL passado por parametro
    function UpdateBySQLText(const pObject: TObject;
      const pWhereClause: string = ''): Boolean;
    // Atualiza usando a property mapeada como Primary Key na property
    function UpdateByPK(const pObject: TObject): Boolean;
    // Atualiza usando as propertys passada como parametro
    function UpdateByProp(const pObject: TObject): Boolean;

    // Deleta com base no SQL passado por parametro
    function DeleteBySQLText(const pObject: TObject; const pWhereClause: string = ''): Boolean;
    // Deleta usando a property mapeada como Primary Key na property
    function DeleteByPK(const pObject: TObject): Boolean;
    // Atualiza usando as propertys passada como parametro
    function DeleteByProp(const pObject: TObject): Boolean;

    // Carrega os dados para as propertys usando a PK
    function LoadObjectByPK(const pObject: TObject): Boolean;

    // Reseta o valor das propriedades deixando o valor padrao
    procedure ResetPropertiesToDefault(const pObject: TObject);

    // Adiciona em um StringList as propertys que serão usadas no Where de um Update ou Delete
    procedure AddPropertyToWhere(const pPropertyName: string);
    // Retorna a String List usada no Where de um Update ou Delete
    function GetPropertiesToWhere: TStringList;

    constructor Create;
    destructor Destroy; override;

    // Define a conexão com o banco de dados. Deve ser definido no DM a conexão para esta property
    class property Connection: TFDConnection read FConnection write FConnection;

  end;

implementation

  {
    A classe uDaoRTTI tem por objetivo otimizar e facilitar os processos com o
    banco de dados utilizando RTTI, para que o desenvolvedor tenha mais facilidade
    ao criar novas campos ou tabelas em seu banco de dados de maneira fácil e prática.
  }

uses
  Vcl.Dialogs;

function TDaoRTTI.CheckTableAttribute(pType: TRttiType): Boolean;
begin

  Result := False;

  // Verifica se a classe possui o atributo com o nome da tabela
  if (pType.HasAttribute<TDBTable>) and
    (pType.GetAttribute<TDBTable>.TableName <> '') then
  begin
    Result := True;
  end;

end;

constructor TDaoRTTI.Create;
begin
  FPropertiesToWhere := TStringList.Create;
end;

function TDaoRTTI.UpdateByProp(const pObject: TObject): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty: TRttiProperty;
  lSQL, lSets, lTable: string;
  lQuery: TFDQuery;
  lWhereClause: string;
  lparamValue: Variant;
begin

  Result := False;
  lSQL := '';
  lSets := '';
  lTable := '';
  lWhereClause := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);

  try

    // Localiza a classe
    lType := lContext.GetType(pObject.ClassType);

    // Verifica se a classe possui o atributo referente a tabela do BD
    if not CheckTableAttribute(lType) then
    begin
      raise Exception.Create('A classe ' + lType.Name +
        ' possui o atributo TDBTable vazio ou inexistente!');
      exit;
    end;

    lTable := lType.GetAttribute<TDBTable>.TableName;

    // Percorre as propriedades para montar a cláusula SET do update
    for lProperty in lType.GetProperties do
    begin
      if CheckColumnsAttribute(lProperty) then
      begin
        lSets := lSets + lProperty.GetAttribute<TDBColumnAttribute>.FieldName +
          ' = :' + lProperty.Name + ', ';
      end;
    end;

    // Remove a última vírgula
    lSets := Copy(lSets, 1, Length(lSets) - 2);

    // Constrói a cláusula WHERE baseada na lista de propriedades fornecida
    for lProperty in lType.GetProperties do
    begin
      if CheckColumnsAttribute(lProperty) and
        (FPropertiesToWhere.IndexOf(lProperty.Name) > -1) then
      begin
        if not lWhereClause.IsEmpty then
          lWhereClause := lWhereClause + ' AND ';
        lWhereClause := lWhereClause +
          lProperty.GetAttribute<TDBColumnAttribute>.FieldName + ' = :' +
          lProperty.Name;
      end;
    end;

    if lWhereClause.IsEmpty then
    begin
      raise Exception.Create
        ('Nenhuma propriedade válida fornecida para construir a cláusula WHERE!');
      exit;
    end;

    // Monta a consulta UPDATE
    lSQL := 'UPDATE ' + lTable + ' SET ' + lSets + ' WHERE ' + lWhereClause;

    try

      lQuery.Connection := FConnection;
      lQuery.Close;
      lQuery.SQL.Clear;
      lQuery.SQL.Add(lSQL);

      // Definindo parâmetros
      for lProperty in lType.GetProperties do
      begin
        if CheckColumnsAttribute(lProperty) then
        begin
          lparamValue := GetParameterValue(pObject, lProperty);

          // Define o valor do parâmetro, ou NULL se for o caso
          if VarIsNull(lparamValue) then
            lQuery.Params.ParamByName(lProperty.Name).Clear // Define como NULL
          else
            lQuery.Params.ParamByName(lProperty.Name).Value := lparamValue;
        end;
      end;

      lQuery.Prepare;
      lQuery.ExecSQL;
      Result := True;

    except
      on E: Exception do
      begin
        raise Exception.Create('Erro ao atualizar registro na tabela ' + lTable
          + ': ' + E.Message);
      end;
    end;
  finally
    lQuery.Free;
    lContext.Free;
  end;
end;

function TDaoRTTI.DeleteByPK(const pObject: TObject): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lPk: TRttiProperty;
  lSQL, lTable: String;
  lQuery: TFDQuery;
  lPkValue : Variant;
begin

  Result := False;
  lSQL := '';
  lTable := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);
  lPkValue := 0;
  try

    // Localiza a classe
    lType := lContext.GetType(pObject.ClassType);

    // Verifica se a classe possui o atributo com o nome da tabela
    if not CheckTableAttribute(lType) then
    begin
      raise Exception.Create('Classe ' + lType.Name +
        ' está com o atributo TDBTable em branco ou inexistente!');
      exit;
    end;

    // Encontra a propriedade com o atributo Chave Primária (PrimaryKey)
    lPk := FindPrimaryKeyProperty(lType);

    // Valida se existe uma property com o atributo de Primary Key
    if lPk = nil then
    begin
      raise Exception.Create('A classe ' + lType.Name +
        ' não possui uma propriedade marcada como Chave Primária!');
      exit;
    end;

     // Pega a ID associada a propriedade PK
    lPkValue := GetParameterValue(pObject, lPk);

    if (lPkValue <= 0) then
    begin
      raise Exception.Create('Id da PK não pode ser menor ou igual a zero!');
      exit;
    end;

    lTable := lType.GetAttribute<TDBTable>.TableName;

    // Monta o SQL para o Delete
    lSQL := 'DELETE FROM ' + lTable + ' WHERE ' +
      lPk.GetAttribute<TDBColumnAttribute>.FieldName + ' = :' + lPk.Name;

    try

      lQuery.Connection := FConnection;
      lQuery.Close;
      lQuery.SQL.Clear;
      lQuery.SQL.Add(lSQL);

      // Parametro da PK
      lQuery.Params.ParamByName(lPk.Name).Value := lPkValue;

      lQuery.Prepare;
      lQuery.ExecSQL;
      Result := True;

    except
      on E: Exception do
      begin
        raise Exception.Create('Erro ao atualizar registro na tabela ' + lTable
          + E.Message);
      end;
    end;

  finally
    lQuery.Free;
    lContext.Free;
  end;

end;

function TDaoRTTI.DeleteByProp(const pObject: TObject): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty: TRttiProperty;
  lSQL, lTable: string;
  lQuery: TFDQuery;
  lWhereClause: String;

begin

  Result := False;
  lSQL := '';
  lTable := '';
  lWhereClause := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);

  try

    // Localiza a classe
    lType := lContext.GetType(pObject.ClassType);

    // Verifica se a classe possui o atributo com o nome da tabela
    if not CheckTableAttribute(lType) then
    begin
      raise Exception.Create('A classe ' + lType.Name +
        ' possui o atributo TDBTable vazio ou inexistente!');
      exit;
    end;

    lTable := lType.GetAttribute<TDBTable>.TableName;

    // Constrói a cláusula WHERE baseada na lista de propriedades fornecida
    for lProperty in lType.GetProperties do
    begin
      if (CheckColumnsAttribute(lProperty)) and
        (FPropertiesToWhere.IndexOf(lProperty.Name) > -1) then
      begin
        if not lWhereClause.IsEmpty then
          lWhereClause := lWhereClause + ' AND ';
        lWhereClause := lWhereClause +
          lProperty.GetAttribute<TDBColumnAttribute>.FieldName + ' = :' +
          lProperty.Name;
      end;
    end;

    if lWhereClause.IsEmpty then
    begin
      raise Exception.Create
        ('Nenhuma propriedade válida fornecida para construir a cláusula WHERE!');
      exit;
    end;

    // Monta o SQL para o delete
    lSQL := 'DELETE FROM ' + lTable + ' WHERE ' + lWhereClause;

    try

      lQuery.Connection := FConnection;
      lQuery.Close;
      lQuery.SQL.Clear;
      lQuery.SQL.Add(lSQL);

      // Define os parametros
      for lProperty in lType.GetProperties do
      begin
        if (CheckColumnsAttribute(lProperty)) and
          (FPropertiesToWhere.IndexOf(lProperty.Name) > -1) then
        begin
          if not lWhereClause.IsEmpty then
            lQuery.Params.ParamByName(lProperty.Name).Value :=
              GetParameterValue(pObject, lProperty);
        end;
      end;

      lQuery.Prepare;
      lQuery.ExecSQL;
      Result := True;

    except
      on E: Exception do
      begin
        raise Exception.Create('Erro ao atualizar registro na tabela ' + lTable
          + ': ' + E.Message);
      end;
    end

  finally
    lContext.Free;
    lQuery.Free;
  end;

end;

function TDaoRTTI.DeleteBySQLText(const pObject: TObject;
  const pWhereClause: string = ''): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty: TRttiProperty;
  lSQL, lTable: string;
  lQuery: TFDQuery;

begin

  Result := False;
  lSQL := '';
  lTable := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);

  // Verifica se o where não veio vazio para evitar um update sem condição
  if pWhereClause = '' then
  begin
    raise Exception.Create
      ('É necessário informar uma condição para executar um Delete!');
    exit;
  end;

  try

    lType := lContext.GetType(pObject.ClassType);

    // Verifica o atributo TDBTable
    if not CheckTableAttribute(lType) then
    begin
      raise Exception.Create('A classe ' + lType.Name +
        ' possui o atributo TDBTable vazio ou inexistente!');
      exit;
    end;

    lTable := lType.GetAttribute<TDBTable>.TableName;

    // Monta o SQL para o Delete
    lSQL := 'DELETE FROM ' + lTable + ' WHERE ' + pWhereClause;

    try

      lQuery.Connection := FConnection;
      lQuery.Close;
      lQuery.SQL.Clear;
      lQuery.SQL.Add(lSQL);

      lQuery.Prepare;
      lQuery.ExecSQL;
      Result := True;

    except
      on E: Exception do
      begin
        raise Exception.Create('Erro ao deletar registro da tabela ' + lTable +
          ': ' + E.Message);
      end;
    end;

  finally
    lQuery.Free;
  end;
end;

destructor TDaoRTTI.Destroy;
begin
  FPropertiesToWhere.Free;
  inherited;
end;

function TDaoRTTI.FindPrimaryKeyProperty(const pType: TRttiType): TRttiProperty;
var
  lProperty: TRttiProperty;
begin

  Result := nil;

  // Percorre todas a propertys em busca da que tenha o atributo Primary Key
  for lProperty in pType.GetProperties do
  begin
    if lProperty.GetAttribute<TDBColumnAttribute> is TDBColumnAttribute then
    begin
      if lProperty.GetAttribute<TDBColumnAttribute>.IsPrimaryKey then
      begin
        Result := lProperty;
        exit;
      end;
    end;
  end;

end;

function TDaoRTTI.GetParameterValue(const pObject: TObject;
  const pProperty: TRttiProperty): Variant;
var
  Value: TValue;
  defaultDate: TDateTime;
begin
  Value := pProperty.GetValue(pObject);

  // Verifica se a propriedade aceita nulos e se o valor é o valor padrão
  // que o Delphi atribui para a propriedade
  if pProperty.GetAttribute<TDBColumnAttribute>.AcceptNull then
  begin
    case Value.Kind of

      tkInteger, tkInt64:
        if Value.AsInteger = 0 then
        begin
          Result := Null;
          exit;
        end;

      tkFloat:
        if (Value.TypeInfo = TypeInfo(TDate)) or
          (Value.TypeInfo = TypeInfo(TDateTime)) then
        begin
          // Data padrao do delphi quando não é atribuido nada a propriedade do Obj
          defaultDate := EncodeDate(1899, 12, 30);
          if Value.AsExtended = defaultDate then
          begin
            Result := Null;
            exit;
          end;
        end
        else if Value.AsExtended = 0 then
        begin
          Result := Null;
          exit;
        end;

      tkString, tkUString, tkLString, tkWString:
        if Value.AsString = '' then
        begin
          Result := Null;
          exit;
        end;
    end;
  end;

  // Converte o TValue para tipos específicos para persistir no banco de dados
  if Value.TypeInfo = TypeInfo(TDate) then
    Result := FormatDateTime('yyyy/mm/dd', Value.AsExtended)
  else if Value.TypeInfo = TypeInfo(TDateTime) then
    Result := FormatDateTime('yyyy/mm/dd hh:MM:ss', Value.AsExtended)
  else
    Result := Value.AsVariant;
end;

procedure TDaoRTTI.AddPropertyToWhere(const pPropertyName: string);
begin
  FPropertiesToWhere.Add(pPropertyName);
end;

function TDaoRTTI.GetPropertiesToWhere: TStringList;
begin
  Result := FPropertiesToWhere;
end;

function TDaoRTTI.CheckColumnsAttribute(pProperty: TRttiProperty): Boolean;
var
  lAttr: TDBColumnAttribute;
begin

  Result := False;
  lAttr := pProperty.GetAttribute<TDBColumnAttribute>;

  // Verifica se a property possui o atributo com o nome da coluna
  if Assigned(lAttr) then
    // Verifica se o atributo não é Auto incremento
    if (not lAttr.IsAutoIncrement) then
      Result := True;

end;

function TDaoRTTI.Insert(const pObject: TObject): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty: TRttiProperty;
  lSQL, lColumns, lValues, lTable: string;
  lQuery: TFDQuery;
  lparamValue: Variant;

begin
  Result := False;
  lColumns := '';
  lSQL := '';
  lTable := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);

  try
    lType := lContext.GetType(pObject.ClassType);

    // Verifica se a classe possui o atributo com o nome da tabela
    if not CheckTableAttribute(lType) then
    begin
      raise Exception.Create('Classe ' + lType.Name +
        ' está com o atributo TDBTable em branco ou inexistente!');
      exit;
    end;

    lTable := lType.GetAttribute<TDBTable>.TableName;

    // Percorre as propriedades para montar as colunas para o SQL
    for lProperty in lType.GetProperties do
    begin
      // Verifica se a propriedade possui o atributo com o nome da coluna e se a mesma não é PK
      if CheckColumnsAttribute(lProperty) then
      begin
        lColumns := lColumns + lProperty.GetAttribute<TDBColumnAttribute>.
          FieldName + ', ';
        lValues := lValues + ':' + lProperty.Name + ', ';
      end;
    end;

    // Remove a última vírgula
    lColumns := Copy(lColumns, 1, Length(lColumns) - 2);
    lValues := Copy(lValues, 1, Length(lValues) - 2);

    // Monta a query
    lSQL := 'INSERT INTO ' + lTable + ' (' + lColumns + ') VALUES (' +
      lValues + ')';

    try
      lQuery.Connection := FConnection;
      lQuery.Close;
      lQuery.SQL.Clear;
      lQuery.SQL.Add(lSQL);

      // Definindo parâmetros
      for lProperty in lType.GetProperties do
      begin
        if CheckColumnsAttribute(lProperty) then
        begin
          lparamValue := GetParameterValue(pObject, lProperty);

          // Define o valor do parâmetro, ou NULL se for o caso
          if VarIsNull(lparamValue) then
            lQuery.Params.ParamByName(lProperty.Name).Clear // Define como NULL
          else
            lQuery.Params.ParamByName(lProperty.Name).Value := lparamValue;
        end;
      end;

      lQuery.Prepare;
      lQuery.ExecSQL;

      Result := True;
    except
      on E: Exception do
      begin
        raise Exception.Create('Erro ao inserir registro na tabela ' + lTable +
          ': ' + E.Message);
      end;
    end;
  finally
    lQuery.Free;
    lContext.Free;
  end;
end;

function TDaoRTTI.UpdateBySQLText(const pObject: TObject;
  const pWhereClause: string = ''): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty: TRttiProperty;
  lSQL, lSets, lTable: string;
  lQuery: TFDQuery;
  lparamValue: Variant;
begin

  Result := False;
  lSets := '';
  lSQL := '';
  lTable := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);

  // Verifica se o where não veio vazio para evitar um update sem condição
  if pWhereClause = '' then
  begin
    raise Exception.Create
      ('É necessário informar uma condição para executar um Update!');
    exit;
  end;

  try
    lType := lContext.GetType(pObject.ClassType);

    // Verifica o atributo TDBTable
    if not CheckTableAttribute(lType) then
    begin
      raise Exception.Create('A classe ' + lType.Name +
        ' possui o atributo TDBTable vazio ou inexistente!');
      exit;
    end;

    lTable := lType.GetAttribute<TDBTable>.TableName;

    // Percorre as propriedades para montar a cláusula SET do update
    for lProperty in lType.GetProperties do
    begin
      if CheckColumnsAttribute(lProperty) then
      begin
        lSets := lSets + lProperty.GetAttribute<TDBColumnAttribute>.FieldName +
          ' = :' + lProperty.Name + ', ';
      end;
    end;

    // Remove a última vírgula
    lSets := Copy(lSets, 1, Length(lSets) - 2);

    // Monta a consulta UPDATE
    lSQL := 'UPDATE ' + lTable + ' SET ' + lSets + ' WHERE ' + pWhereClause;

    try
      lQuery.Connection := FConnection;
      lQuery.Close;
      lQuery.SQL.Clear;
      lQuery.SQL.Add(lSQL);

      // Definindo parâmetros
      for lProperty in lType.GetProperties do
      begin
        if CheckColumnsAttribute(lProperty) then
        begin
          lparamValue := GetParameterValue(pObject, lProperty);

          // Define o valor do parâmetro, ou NULL se for o caso
          if VarIsNull(lparamValue) then
            lQuery.Params.ParamByName(lProperty.Name).Clear // Define como NULL
          else
            lQuery.Params.ParamByName(lProperty.Name).Value := lparamValue;
        end;
      end;

      lQuery.Prepare;
      lQuery.ExecSQL;
      Result := True;

    except
      on E: Exception do
      begin
        raise Exception.Create('Erro ao atualizar registro na tabela ' + lTable
          + E.Message);
      end;
    end;
  finally
    lQuery.Free;
    lContext.Free;
  end;
end;

function TDaoRTTI.UpdateByPK(const pObject: TObject): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty, lPk: TRttiProperty;
  lSQL, lSets, lTable: string;
  lQuery: TFDQuery;
  lparamValue: Variant;
  lPkValue : Variant;
begin

  Result := False;
  lSets := '';
  lSQL := '';
  lTable := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);
  lPkValue := 0;
  try
    lType := lContext.GetType(pObject.ClassType);

    // Verifica se a classe possui o atributo com o nome da tabela
    if not CheckTableAttribute(lType) then
    begin
      raise Exception.Create('Classe ' + lType.Name +
        ' está com o atributo TDBTable em branco ou inexistente!');
      exit;
    end;

    // Encontra a propriedade com o atributo Chave Primária (PrimaryKey)
    lPk := FindPrimaryKeyProperty(lType);

    if lPk = nil then
    begin
      raise Exception.Create('A classe ' + lType.Name +
        ' não possui uma propriedade marcada como Chave Primária!');
      exit;
    end;

    // Pega a ID associada a propriedade PK
    lPkValue := GetParameterValue(pObject, lPk);

    if (lPkValue <= 0) then
    begin
      raise Exception.Create('Id da PK não pode ser menor ou igual a zero!');
      exit;
    end;

    lTable := lType.GetAttribute<TDBTable>.TableName;

    // Percorre as propriedades para montar a cláusula SET do update
    for lProperty in lType.GetProperties do
    begin
      if CheckColumnsAttribute(lProperty) then
      begin
        lSets := lSets + lProperty.GetAttribute<TDBColumnAttribute>.FieldName +
          ' = :' + lProperty.Name + ', ';
      end;
    end;

    // Remove a última vírgula
    lSets := Copy(lSets, 1, Length(lSets) - 2);

    // Monta a consulta UPDATE
    lSQL := 'UPDATE ' + lTable + ' SET ' + lSets + ' WHERE ' +
      lPk.GetAttribute<TDBColumnAttribute>.FieldName + ' = :' + lPk.Name;

    try
      lQuery.Connection := FConnection;
      lQuery.Close;
      lQuery.SQL.Clear;
      lQuery.SQL.Add(lSQL);

      // Definindo parâmetros
      for lProperty in lType.GetProperties do
      begin
        if CheckColumnsAttribute(lProperty) then
        begin
          lparamValue := GetParameterValue(pObject, lProperty);

          // Define o valor do parâmetro, ou NULL se for o caso
          if VarIsNull(lparamValue) then
            lQuery.Params.ParamByName(lProperty.Name).Clear // Define como NULL
          else
            lQuery.Params.ParamByName(lProperty.Name).Value := lparamValue;
        end;
      end;

      // Parametro da PK
      lQuery.Params.ParamByName(lPk.Name).Value := lPkValue;

      lQuery.Prepare;
      lQuery.ExecSQL;
      Result := True;

    except
      on E: Exception do
      begin
        raise Exception.Create('Erro ao atualizar registro na tabela ' + lTable
          + E.Message);
      end;
    end;

  finally
    lContext.Free;
    lQuery.Free;
  end;

end;

function TDaoRTTI.LoadObjectByPK(const pObject: TObject): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty: TRttiProperty;
  lSQL, lTable, lFieldName: string;
  lQuery: TFDQuery;

begin
  Result := False;
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);
  lFieldName := '';
  lSQL := '';
  lTable := '';

  try
    lType := lContext.GetType(pObject.ClassType);

    // Verifica se a classe possui o atributo com o nome da tabela
    if not CheckTableAttribute(lType) then
    begin
      raise Exception.Create('Classe ' + lType.Name +
        ' está com o atributo TDBTable em branco ou inexistente!');
      exit;
    end;

    lQuery.Connection := FConnection;

    // Encontra a propriedade com o atributo Chave Primária (PrimaryKey)
    lProperty := FindPrimaryKeyProperty(lType);

    if lProperty = nil then
    begin
      raise Exception.Create('A classe ' + lType.Name +
        ' não possui uma propriedade marcada como Chave Primária!');
      exit;
    end;

    // Monta a consulta SQL
    lTable := lType.GetAttribute<TDBTable>.TableName;
    lSQL := 'SELECT * FROM ' + lTable + ' WHERE ' +
      lProperty.GetAttribute<TDBColumnAttribute>.FieldName + ' = :' +
      lProperty.Name;

    // Executa a consulta SQL
    try
      lQuery.Close;
      lQuery.SQL.Clear;
      lQuery.SQL.Add(lSQL);
      lQuery.Params.ParamByName(lProperty.Name).Value := GetParameterValue(pObject, lProperty);
      lQuery.Open;

      if lQuery.RecordCount > 0 then
      begin
        Result := True;

        // Atribui os valores das colunas às propriedades do objeto
        for lProperty in lType.GetProperties do
        begin
          lFieldName := lProperty.GetAttribute<TDBColumnAttribute>.FieldName;

          if lQuery.FindField(lFieldName) <> nil then
          begin
            if not lQuery.FieldByName(lFieldName).IsNull then
            begin
              //  Verificação de propriedades do tipo Data
              if (lProperty.PropertyType.TypeKind = tkFloat) and (lProperty.PropertyType.Handle = TypeInfo(TDateTime)) then
                  lProperty.SetValue(pObject, TValue.From<TDateTime>(lQuery.FieldByName(lFieldName).AsDateTime))
              else
                lProperty.SetValue(pObject, TValue.FromVariant(lQuery.FieldByName(lFieldName).Value));
            end;
          end;
        end;
      end;

    except
      on E: Exception do
      begin
        raise Exception.Create('Erro ao executar a consulta SQL: ' + E.Message);
      end;
    end;

  finally
    lContext.Free;
    lQuery.Free;
  end;

end;

procedure TDaoRTTI.ResetPropertiesToDefault(const pObject: TObject);
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty: TRttiProperty;
  lValue: TValue;
begin

  lContext := TRttiContext.Create;
  try
    lType := lContext.GetType(pObject.ClassType);

    for lProperty in lType.GetProperties do
    begin
      //  Verifica se a propriedade pode ser escrita e se tem o atributo
      if (lProperty.IsWritable) and (CheckColumnsAttribute(lProperty)) then
      begin
        case lProperty.PropertyType.TypeKind of

          tkInteger, tkInt64:
            lValue := TValue.From<Integer>(0);

          tkFloat:
            if lProperty.PropertyType.Handle = TypeInfo(TDateTime) then
              lValue := TValue.From<TDateTime>(0)
            else if lProperty.PropertyType.Handle = TypeInfo(TDate) then
              lValue := TValue.From<TDate>(0)
            else
              lValue := TValue.From<Double>(0.0);

          tkChar, tkWChar:
            lValue := TValue.From<WideChar>(#0);

          tkString, tkUString, tkLString, tkWString:
            lValue := TValue.From<string>('');

          tkEnumeration:
            if lProperty.PropertyType.Handle = TypeInfo(Boolean) then
              lValue := TValue.From<Boolean>(False)
            else
              lValue := TValue.FromOrdinal(lProperty.PropertyType.Handle, 0);

          tkVariant:
            lValue := TValue.Empty;
        else
          Continue;
        end;

        //  Seta o valor na property
        lProperty.SetValue(pObject, lValue);
      end;
    end;

  finally
    lContext.Free;
  end;
end;

end.
