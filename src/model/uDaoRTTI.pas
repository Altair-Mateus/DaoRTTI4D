unit uDaoRTTI;

interface

uses
  SysUtils,
  RTTI,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Comp.DataSet,
  FireDAC.Phys,
  FireDAC.Phys.Intf,
  FireDAC.DApt,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.VCLUI.Wait,
  System.Variants,
  uDBAttributes,
  System.Classes,
  System.TypInfo,
  System.UITypes,
  System.Generics.Collections;

type
  TDaoRTTI = class
  private
    FContext: TRttiContext;
    FPropertiesToWhere: TStringList;
    FConnection: TFDConnection;

    // Verifica se a classe possui o atributo com o nome da tabela
    function CheckTableAttribute(pType: TRttiType): Boolean;
    // Verifica se a property tem o atributo com o nome da coluna do Banco de dados
    function CheckColumnsAttribute(pProperty: TRttiProperty): Boolean;
    // Verifica se a property tem o atributo de auto incremento
    function CheckAutoIncAttribute(const pProperty: TRttiProperty): Boolean;
    // Verifica se a property tem o atributo que aceita valores nulos
    function CheckAcepptNullAttribute(const pProperty: TRttiProperty): Boolean;
    // Realiza a conversão do tipo Variant
    function GetParameterValue(const pObject: TObject;
      const pProperty: TRttiProperty): Variant;

    // Localiza a property com o atributo de Primary Key no banco de dados
    function FindPrimaryKeyProperty(const pType: TRttiType): TRttiProperty;

    function GetRttiType(const pObject: TObject): TRttiType;
    function ExtractColumnProps(const pType: TRttiType): TArray<TRttiProperty>;
    function BuildInsertSQL(const pTable: String;
      const pColumns: TArray<TRttiProperty>): String;
    function BuildUpdateSQL(const pTable: String;
      const pSetCols, pWhereCols: TArray<TRttiProperty>): String;
    function BuildDeleteSQL(const pTable: String;
      const pWhereCols: TArray<TRttiProperty>): String;
    function GetParamValue(const pObject: TObject;
      const pProperty: TRttiProperty): Variant;
    function ExecuteSQL(const pSql: String;
      const pParamDict: TDictionary<String, Variant>): Boolean;

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
    function DeleteBySQLText(const pObject: TObject;
      const pWhereClause: string = ''): Boolean;
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

  end;

implementation

{
  A classe uDaoRTTI tem por objetivo otimizar e facilitar os processos com o
  banco de dados utilizando RTTI, para que o desenvolvedor tenha mais facilidade
  ao criar novas campos ou tabelas em seu banco de dados de maneira fácil e prática.
}

uses
  uDbConfig,
  uDaoRTTIExceptions;

function TDaoRTTI.CheckTableAttribute(pType: TRttiType): Boolean;
begin

  // Verifica se a classe possui o atributo com o nome da tabela
  Result := (pType.HasAttribute<TDBTable>) and
    (pType.GetAttribute<TDBTable>.TableName <> '');

end;

constructor TDaoRTTI.Create;
begin
  FConnection := TDbConfig.Connection;
  FPropertiesToWhere := TStringList.Create;
end;

function TDaoRTTI.UpdateByProp(const pObject: TObject): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty: TRttiProperty;
  lSQL, lTable: string;
  lQuery: TFDQuery;
  lWhereClause: string;
  lparamValue: Variant;
  lSets: TStringList;
begin

  Result := False;
  lSQL := '';
  lTable := '';
  lWhereClause := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);
  lSets := TStringList.Create;
  try
    try
      // Localiza a classe
      lType := lContext.GetType(pObject.ClassType);

      // Verifica se a classe possui o atributo referente a tabela do BD
      if not CheckTableAttribute(lType) then
      begin
        raise Exception.Create('A classe ' + lType.Name +
          ' possui o atributo TDBTable vazio ou inexistente!');
      end;

      lTable := lType.GetAttribute<TDBTable>.TableName;

      // Percorre as propriedades para montar a cláusula SET do update
      for lProperty in lType.GetProperties do
      begin
        if CheckColumnsAttribute(lProperty) then
        begin
          lSets.Add(lProperty.GetAttribute<TDBColumnAttribute>.FieldName + '=:'
            + lProperty.Name);
        end;
      end;

      // Constrói a cláusula WHERE baseada na lista de propriedades fornecida
      for lProperty in lType.GetProperties do
      begin
        if CheckColumnsAttribute(lProperty) and
          (FPropertiesToWhere.IndexOf(lProperty.Name) > -1) then
        begin
          if not(lWhereClause.Trim.IsEmpty) then
            lWhereClause := lWhereClause + ' AND ';
          lWhereClause := lWhereClause +
            lProperty.GetAttribute<TDBColumnAttribute>.FieldName + '=:' +
            lProperty.Name;
        end;
      end;

      if (lWhereClause.Trim.IsEmpty) then
      begin
        raise Exception.Create
          ('Nenhuma propriedade válida fornecida para construir a cláusula WHERE!');
      end;

      // Monta a consulta UPDATE
      lSQL := 'UPDATE ' + lTable + ' SET ' + lSets.CommaText + ' WHERE ' +
        lWhereClause;

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
            lQuery.Params.ParamByName(lProperty.Name).Clear
            // Define como NULL
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
    lSets.Free;
  end;
end;

function TDaoRTTI.DeleteByPK(const pObject: TObject): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lPk: TRttiProperty;
  lSQL, lTable: String;
  lQuery: TFDQuery;
  lPkValue: Variant;
begin

  Result := False;
  lSQL := '';
  lTable := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);
  lPkValue := 0;
  try
    try
      // Localiza a classe
      lType := lContext.GetType(pObject.ClassType);

      // Verifica se a classe possui o atributo com o nome da tabela
      if not CheckTableAttribute(lType) then
      begin
        raise Exception.Create('Classe ' + lType.Name +
          ' está com o atributo TDBTable em branco ou inexistente!');
      end;

      // Encontra a propriedade com o atributo Chave Primária (PrimaryKey)
      lPk := FindPrimaryKeyProperty(lType);

      // Valida se existe uma property com o atributo de Primary Key
      if not(Assigned(lPk)) then
      begin
        raise Exception.Create('A classe ' + lType.Name +
          ' não possui uma propriedade marcada como Chave Primária!');
      end;

      // Pega a ID associada a propriedade PK
      lPkValue := GetParameterValue(pObject, lPk);

      if (lPkValue <= 0) then
      begin
        raise Exception.Create('Id da PK não pode ser menor ou igual a zero!');
      end;

      lTable := lType.GetAttribute<TDBTable>.TableName;

      // Monta o SQL para o Delete
      lSQL := 'DELETE FROM ' + lTable + ' WHERE ' +
        lPk.GetAttribute<TDBColumnAttribute>.FieldName + ' = :' + lPk.Name;

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
    try
      // Localiza a classe
      lType := lContext.GetType(pObject.ClassType);

      // Verifica se a classe possui o atributo com o nome da tabela
      if not CheckTableAttribute(lType) then
      begin
        raise Exception.Create('A classe ' + lType.Name +
          ' possui o atributo TDBTable vazio ou inexistente!');
      end;

      lTable := lType.GetAttribute<TDBTable>.TableName;

      // Constrói a cláusula WHERE baseada na lista de propriedades fornecida
      for lProperty in lType.GetProperties do
      begin
        if (CheckColumnsAttribute(lProperty)) and
          (FPropertiesToWhere.IndexOf(lProperty.Name) > -1) then
        begin
          if not(lWhereClause.Trim.IsEmpty) then
            lWhereClause := lWhereClause + ' AND ';
          lWhereClause := lWhereClause +
            lProperty.GetAttribute<TDBColumnAttribute>.FieldName + '=:' +
            lProperty.Name;
        end;
      end;

      if (lWhereClause.Trim.IsEmpty) then
      begin
        raise Exception.Create
          ('Nenhuma propriedade válida fornecida para construir a cláusula WHERE!');
      end;

      // Monta o SQL para o delete
      lSQL := 'DELETE FROM ' + lTable + ' WHERE ' + lWhereClause;

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
          if not(lWhereClause.Trim.IsEmpty) then
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
  lSQL, lTable: string;
  lQuery: TFDQuery;

begin

  Result := False;
  lSQL := '';
  lTable := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);
  try
    try
      // Verifica se o where não veio vazio para evitar um update sem condição
      if pWhereClause = '' then
      begin
        raise Exception.Create
          ('É necessário informar uma condição para executar um Delete!');
      end;

      lType := lContext.GetType(pObject.ClassType);

      // Verifica o atributo TDBTable
      if not CheckTableAttribute(lType) then
      begin
        raise Exception.Create('A classe ' + lType.Name +
          ' possui o atributo TDBTable vazio ou inexistente!');
      end;

      lTable := lType.GetAttribute<TDBTable>.TableName;

      // Monta o SQL para o Delete
      lSQL := 'DELETE FROM ' + lTable + ' WHERE ' + pWhereClause;

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

function TDaoRTTI.ExecuteSQL(const pSql: String;
  const pParamDict: TDictionary<String, Variant>): Boolean;
var
  lQuery: TFDQuery;
  lPair: TPair<String, Variant>;
begin
  Result := False;

  lQuery := TFDQuery.Create(nil);
  try
    try

      lQuery.Connection := FConnection;
      lQuery.SQL.Text := pSql;

      for lPair in pParamDict do
      begin
        if (VarIsNull(lPair.Value)) then
          lQuery.Params.ParamByName(lPair.Key).Clear
        else
          lQuery.Params.ParamByName(lPair.Key).Value := lPair.Value;
      end;

      lQuery.Prepare;
      lQuery.ExecSQL;

      Result := True;
    except
      on E: Exception do
      begin
        raise EExecutarSQL.Create(E.Message);
      end;
    end;
  finally
    lQuery.Free;
  end;

end;

function TDaoRTTI.ExtractColumnProps(const pType: TRttiType)
  : TArray<TRttiProperty>;
var
  lProperty: TRttiProperty;
  lList: TList<TRttiProperty>;
begin
  lList := TList<TRttiProperty>.Create;
  try

    for lProperty in pType.GetProperties do
    begin
      if (lProperty.HasAttribute<TDBIsAutoIncrement>) then
        Continue;
      lList.Add(lProperty);
    end;

    Result := lList.ToArray;
  finally
    lList.Free;
  end;
end;

function TDaoRTTI.FindPrimaryKeyProperty(const pType: TRttiType): TRttiProperty;
var
  lProperty: TRttiProperty;
begin

  Result := nil;

  // Percorre todas a propertys em busca da que tenha o atributo Primary Key
  for lProperty in pType.GetProperties do
  begin
    if lProperty.HasAttribute(TDBIsPrimaryKey) then
    begin
      Result := lProperty;
      Exit;
    end;
  end;

end;

function TDaoRTTI.GetParameterValue(const pObject: TObject;
  const pProperty: TRttiProperty): Variant;
var
  lValue: TValue;
begin

  lValue := pProperty.GetValue(pObject);

  {
    Se a propriedade ter o atributo que aceita nulos, e
    de acordo com seu tipo etiver vazia irá encerrar a
    função e retornar Null
  }
  if (CheckAcepptNullAttribute(pProperty)) then
  begin
    case lValue.Kind of

      tkString, tkLString, tkUString, tkWString:
        begin
          if (lValue.AsString = '') then
            Exit(Null);
        end;

      tkInteger, tkInt64:
        begin
          if (lValue.AsInteger = 0) then
            Exit(Null);
        end;

      tkFloat:
        begin
          if (lValue.AsExtended = 0) or
            (lValue.AsExtended = EncodeDate(1899, 12, 30)) then
            Exit(Null);
        end;

    end;
  end;

  // Converte o TValue para tipos específicos para persistir no banco de dados
  if (lValue.TypeInfo = TypeInfo(TDate)) then
    Result := FormatDateTime('yyyy/mm/dd', lValue.AsExtended)
  else if (lValue.TypeInfo = TypeInfo(TDateTime)) then
    Result := FormatDateTime('yyyy/mm/dd hh:MM:ss', lValue.AsExtended)
  else
    Result := lValue.AsVariant;

end;

function TDaoRTTI.GetParamValue(const pObject: TObject;
  const pProperty: TRttiProperty): Variant;
var
  lAttrColumn: TDBColumnAttribute;
  lValue: TValue;
begin

  lAttrColumn := pProperty.GetAttribute<TDBColumnAttribute>;
  lValue := pProperty.GetValue(pObject);

  // Retorna null para gravar no banco
  if (pProperty.HasAttribute<TDBAcceptNull>) then
  begin

    case lValue.Kind of

      tkString, tkLString, tkUString, tkWString:
        begin
          if (lValue.AsString.Trim.IsEmpty) then
            Exit(Null);
        end;

      tkInteger, tkInt64:
        begin
          if (lValue.AsInteger = 0) then
            Exit(Null);
        end;

      tkFloat:
        begin
          if ((lValue.AsExtended = 0) or (Trunc(lValue.AsExtended) = Trunc(EncodeDate(1899, 12, 30)))) then
            Exit(Null);
        end;

    end;

  end;

  if (pProperty.PropertyType.Handle = TypeInfo(TDateTime)) then
    Exit(lValue.AsExtended);

  Result := lValue.AsVariant;
end;

procedure TDaoRTTI.AddPropertyToWhere(const pPropertyName: string);
begin
  FPropertiesToWhere.Add(pPropertyName);
end;

function TDaoRTTI.GetPropertiesToWhere: TStringList;
begin
  Result := FPropertiesToWhere;
end;

function TDaoRTTI.BuildDeleteSQL(const pTable: String;
  const pWhereCols: TArray<TRttiProperty>): String;
var
  lWhereList: TStringList;
  lProperty: TRttiProperty;
  lAttrColumn: TDBColumnAttribute;
begin
  Result := '';

  lWhereList := TStringList.Create;
  try

    for lProperty in pWhereCols do
    begin
      lAttrColumn := lProperty.GetAttribute<TDBColumnAttribute>;
      lWhereList.Add(Format('%s = %s', [lAttrColumn.FieldName, lProperty.Name]));
    end;

    Result := Format('DELETE FROM %s WHERE %s', [pTable, lWhereList.CommaText]);

  finally
    lWhereList.Free;
  end;
end;

function TDaoRTTI.BuildInsertSQL(const pTable: String;
  const pColumns: TArray<TRttiProperty>): String;
var
  lColumnsList, lParamsList: TStringList;
  lProperty: TRttiProperty;
  lAttrColumn: TDBColumnAttribute;
begin
  Result := '';

  lColumnsList := TStringList.Create;
  lParamsList := TStringList.Create;
  try

    for lProperty in pColumns do
    begin
      lAttrColumn := lProperty.GetAttribute<TDBColumnAttribute>;
      lColumnsList.Add(lAttrColumn.FieldName);
      lParamsList.Add(':' + lProperty.Name);
    end;

    Result := Format('INSERT INTO %s (%s) VALUES (%s)',
      [pTable, lColumnsList.CommaText, lParamsList.CommaText]);

  finally
    lColumnsList.Free;
    lParamsList.Free;
  end;

end;

function TDaoRTTI.BuildUpdateSQL(const pTable: String;
  const pSetCols, pWhereCols: TArray<TRttiProperty>): String;
var
  lSetList, lWhereList: TStringList;
  lProperty: TRttiProperty;
  lAttrColumn: TDBColumnAttribute;
begin
  Result := '';

  lSetList := TStringList.Create;
  lWhereList := TStringList.Create;
  try

    for lProperty in pSetCols do
    begin
      lAttrColumn := lProperty.GetAttribute<TDBColumnAttribute>;
      lSetList.Add(Format('%s = %s', [lAttrColumn.FieldName, lProperty.Name]));
    end;

    for lProperty in pWhereCols do
    begin
      lAttrColumn := lProperty.GetAttribute<TDBColumnAttribute>;
      lWhereList.Add(Format('%s = %s', [lAttrColumn.FieldName,
        lProperty.Name]));
    end;

    Result := Format('UPDATE %s SET %s WHERE %s', [pTable, lSetList.CommaText,
      lWhereList.CommaText]);

  finally
    lSetList.Free;
    lWhereList.Free;
  end;

end;

function TDaoRTTI.GetRttiType(const pObject: TObject): TRttiType;
begin
  Result := FContext.GetType(pObject.ClassType);
  if not(Result.HasAttribute<TDBTable>) then
    raise ESemAtributoTabela.Create(Result.Name);
end;

function TDaoRTTI.CheckAcepptNullAttribute(const pProperty
  : TRttiProperty): Boolean;
begin
  // Verifica se a propriedade tem o atributo que aceita valores nulos
  Result := (pProperty.HasAttribute<TDBAcceptNull>);
end;

function TDaoRTTI.CheckAutoIncAttribute(const pProperty: TRttiProperty)
  : Boolean;
begin
  // Verifica se a propriedade tem o atributo  Auto incremento
  Result := (pProperty.HasAttribute(TDBIsAutoIncrement));
end;

function TDaoRTTI.CheckColumnsAttribute(pProperty: TRttiProperty): Boolean;
begin

  // Verifica se a property possui o atributo com o nome da coluna
  // Verifica se o atributo não é Auto incremento
  Result := (pProperty.HasAttribute(TDBColumnAttribute)) and
    (not CheckAutoIncAttribute(pProperty));

end;

function TDaoRTTI.Insert(const pObject: TObject): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty: TRttiProperty;
  lSQL, lTable: string;
  lQuery: TFDQuery;
  lparamValue: Variant;
  lColumns, lValues: TStringList;
begin
  Result := False;

  lSQL := '';
  lTable := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);
  lColumns := TStringList.Create;
  lValues := TStringList.Create;
  try
    try
      lType := lContext.GetType(pObject.ClassType);

      // Verifica se a classe possui o atributo com o nome da tabela
      if not CheckTableAttribute(lType) then
      begin
        raise Exception.Create('Classe ' + lType.Name +
          ' está com o atributo TDBTable em branco ou inexistente!');
      end;

      lTable := lType.GetAttribute<TDBTable>.TableName;

      // Percorre as propriedades para montar as colunas para o SQL
      for lProperty in lType.GetProperties do
      begin
        // Verifica se a propriedade possui o atributo com o nome da coluna e se a mesma não é PK
        if CheckColumnsAttribute(lProperty) then
        begin
          lColumns.Add(lProperty.GetAttribute<TDBColumnAttribute>.FieldName);
          lValues.Add(':' + lProperty.Name);
        end;

      end;

      // Monta a query
      lSQL := 'INSERT INTO ' + lTable + ' (' + lColumns.CommaText + ') VALUES ('
        + lValues.CommaText + ')';

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
            lQuery.Params.ParamByName(lProperty.Name).Clear
            // Define como NULL
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
    lColumns.Free;
    lValues.Free;
  end;
end;

function TDaoRTTI.UpdateBySQLText(const pObject: TObject;
  const pWhereClause: string = ''): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty: TRttiProperty;
  lSQL, lTable: string;
  lQuery: TFDQuery;
  lparamValue: Variant;
  lSets: TStringList;
begin

  Result := False;
  lSQL := '';
  lTable := '';
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);
  lSets := TStringList.Create;

  try
    try

      // Verifica se o where não veio vazio para evitar um update sem condição
      if pWhereClause = '' then
      begin
        raise Exception.Create
          ('É necessário informar uma condição para executar um Update!');
      end;

      lType := lContext.GetType(pObject.ClassType);

      // Verifica o atributo TDBTable
      if not CheckTableAttribute(lType) then
      begin
        raise Exception.Create('A classe ' + lType.Name +
          ' possui o atributo TDBTable vazio ou inexistente!');
      end;

      lTable := lType.GetAttribute<TDBTable>.TableName;

      // Percorre as propriedades para montar a cláusula SET do update
      for lProperty in lType.GetProperties do
      begin
        if CheckColumnsAttribute(lProperty) then
        begin
          lSets.Add(lProperty.GetAttribute<TDBColumnAttribute>.FieldName +
            ' = :' + lProperty.Name);
        end;
      end;

      // Monta a consulta UPDATE
      lSQL := 'UPDATE ' + lTable + ' SET ' + lSets.CommaText + ' WHERE ' +
        pWhereClause;

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
            lQuery.Params.ParamByName(lProperty.Name).Clear
            // Define como NULL
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
    lSets.Free;
  end;
end;

function TDaoRTTI.UpdateByPK(const pObject: TObject): Boolean;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lProperty, lPk: TRttiProperty;
  lSQL, lTable: string;
  lQuery: TFDQuery;
  lparamValue: Variant;
  lPkValue: Variant;
  lCampos: TStringList;
begin

  Result := False;
  lSQL := '';
  lTable := '';
  lPkValue := 0;
  lContext := TRttiContext.Create;
  lQuery := TFDQuery.Create(nil);
  lCampos := TStringList.Create;
  try
    try
      lType := lContext.GetType(pObject.ClassType);

      // Verifica se a classe possui o atributo com o nome da tabela
      if not CheckTableAttribute(lType) then
      begin
        raise Exception.Create('Classe ' + lType.Name +
          ' está com o atributo TDBTable em branco ou inexistente!');
      end;

      // Encontra a propriedade com o atributo Chave Primária (PrimaryKey)
      lPk := FindPrimaryKeyProperty(lType);

      if not(Assigned(lPk)) then
      begin
        raise Exception.Create('A classe ' + lType.Name +
          ' não possui uma propriedade marcada como Chave Primária!');
      end;

      // Pega a ID associada a propriedade PK
      lPkValue := GetParameterValue(pObject, lPk);

      if (lPkValue <= 0) then
      begin
        raise Exception.Create('Id da PK não pode ser menor ou igual a zero!');
      end;

      lTable := lType.GetAttribute<TDBTable>.TableName;

      // Percorre as propriedades para montar a cláusula SET do update
      for lProperty in lType.GetProperties do
      begin
        if CheckColumnsAttribute(lProperty) then
        begin
          lCampos.Add(lProperty.GetAttribute<TDBColumnAttribute>.FieldName +
            '=:' + lProperty.Name);
        end;
      end;

      // Monta a consulta UPDATE
      lSQL := 'UPDATE ' + lTable + ' SET ' + lCampos.CommaText + ' WHERE ' +
        lPk.GetAttribute<TDBColumnAttribute>.FieldName + ' = :' + lPk.Name;

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
            lQuery.Params.ParamByName(lProperty.Name).Clear
            // Define como NULL
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
    lCampos.Free;
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
    try
      lType := lContext.GetType(pObject.ClassType);

      // Verifica se a classe possui o atributo com o nome da tabela
      if not CheckTableAttribute(lType) then
      begin
        raise Exception.Create('Classe ' + lType.Name +
          ' está com o atributo TDBTable em branco ou inexistente!');
      end;

      lQuery.Connection := FConnection;

      // Encontra a propriedade com o atributo Chave Primária (PrimaryKey)
      lProperty := FindPrimaryKeyProperty(lType);

      if lProperty = nil then
      begin
        raise Exception.Create('A classe ' + lType.Name +
          ' não possui uma propriedade marcada como Chave Primária!');
      end;

      // Monta a consulta SQL
      lTable := lType.GetAttribute<TDBTable>.TableName;
      lSQL := 'SELECT * FROM ' + lTable + ' WHERE ' +
        lProperty.GetAttribute<TDBColumnAttribute>.FieldName + ' = :' +
        lProperty.Name;

      // Executa a consulta SQL
      lQuery.Close;
      lQuery.SQL.Clear;
      lQuery.SQL.Add(lSQL);
      lQuery.Params.ParamByName(lProperty.Name).Value :=
        GetParameterValue(pObject, lProperty);
      lQuery.Open;

      if not(lQuery.IsEmpty) then
      begin

        // Atribui os valores das colunas às propriedades do objeto
        for lProperty in lType.GetProperties do
        begin
          lFieldName := lProperty.GetAttribute<TDBColumnAttribute>.FieldName;

          if lQuery.FindField(lFieldName) <> nil then
          begin
            if not lQuery.FieldByName(lFieldName).IsNull then
            begin
              // Verificação de propriedades do tipo Data
              if (lProperty.PropertyType.TypeKind = tkFloat) and
                (lProperty.PropertyType.Handle = TypeInfo(TDateTime)) then
                lProperty.SetValue(pObject,
                  TValue.From<TDateTime>(lQuery.FieldByName(lFieldName)
                  .AsDateTime))
              else
                lProperty.SetValue(pObject,
                  TValue.FromVariant(lQuery.FieldByName(lFieldName).Value));
            end;
          end;
        end;

        Result := True;
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
    try
      lType := lContext.GetType(pObject.ClassType);

      for lProperty in lType.GetProperties do
      begin
        // Verifica se a propriedade pode ser escrita e se tem o atributo
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

          // Seta o valor na property
          lProperty.SetValue(pObject, lValue);
        end;
      end;
    except
      on E: Exception do
      begin
        raise Exception.Create
          ('Erro ao resetar as propriedades para o valor padrão: ' + E.Message);
      end;
    end;
  finally
    lContext.Free;
  end;
end;

end.
