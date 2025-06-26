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

    // Localiza a property com o atributo de Primary Key no banco de dados
    function FindPrimaryKeyProperty(const pType: TRttiType): TRttiProperty;

    function GetRttiType(const pObject: TObject): TRttiType;

    // Monta e executa os SQLs
    function BuildInsertSQL(const pTable: String; const pColumns: TArray<TRttiProperty>): String;
    function BuildUpdateSQL(const pTable: String; const pSetCols, pWhereCols: TArray<TRttiProperty>): String;
    function BuildDeleteSQL(const pTable: String; const pWhereCols: TArray<TRttiProperty>): String;
    function ExecuteSQL(const pSql: String; const pParamDict: TDictionary<String, Variant>): Boolean;
    function ExtractColumnProps(const pType: TRttiType): TArray<TRttiProperty>;

    // Realiza a conversão do tipo Variant
    function GetParamValue(const pObject: TObject; const pProperty: TRttiProperty): Variant;

  public

    function Insert(const pObject: TObject): Boolean;

    // Atualiza com base no SQL passado por parametro
    function UpdateBySQLText(const pObject: TObject; const pWhereClause: string = ''): Boolean;
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
  FContext := TRttiContext.Create;
end;

function TDaoRTTI.UpdateByProp(const pObject: TObject): Boolean;
var
  lType: TRttiType;
  lTable, lSQL: String;
  lColumns, lWhereColumns: TArray<TRttiProperty>;
  lParamDict: TDictionary<String, Variant>;
  lProperty: TRttiProperty;
  lProp: String;
begin

  Result := False;
  lType := GetRttiType(pObject);
  lTable := lType.GetAttribute<TDBTable>.TableName;

  if (FPropertiesToWhere.Count = 0) then
    raise ESemPropriedadeLista.Create;

  lColumns := ExtractColumnProps(lType);

  lWhereColumns := [];
  for lProp in FPropertiesToWhere do
  begin

    for lProperty in lType.GetProperties do
    begin
      if ((SameText(lProperty.Name, lProp.Trim)) and (lProperty.HasAttribute<TDBColumnAttribute>)) then
      begin
        lWhereColumns := lWhereColumns + [lProperty];
        Break;
      end;
    end;

  end;

  if (Length(lWhereColumns) = 0) then
    raise EWhereVazio.Create;

  lSQL := BuildUpdateSQL(lTable, lColumns, lWhereColumns);

  lParamDict := TDictionary<String, Variant>.Create;
  try

    for lProperty in lColumns do
    begin
      lParamDict.Add(lProperty.Name, GetParamValue(pObject, lProperty));
    end;

    Result := ExecuteSQL(lSQL, lParamDict);

  finally
    lParamDict.Free;
    FPropertiesToWhere.Clear;
  end;

end;

function TDaoRTTI.DeleteByPK(const pObject: TObject): Boolean;
var
  lType: TRttiType;
  lTable, lSQL: String;
  lPk: TRttiProperty;
  lPkValue: Variant;
  lParamDict: TDictionary<String, Variant>;
begin

  Result := False;

  lType := GetRttiType(pObject);
  lTable := lType.GetAttribute<TDBTable>.TableName;

  lPk := FindPrimaryKeyProperty(lType);
  if (lPk = nil) then
    raise ESemAtributoChavePrimaria.Create(lTable);

  lPkValue := GetParamValue(pObject, lPk);
  if ((VarIsNull(lPkValue)) or (lPkValue <= 0)) then
    raise EChavePrimariaNula.Create;

  lSQL := BuildDeleteSQL(lTable, TArray<TRttiProperty>.Create(lPk));

  lParamDict := TDictionary<String, Variant>.Create;
  try

    lParamDict.Add(lPk.Name, lPkValue);

    Result := ExecuteSQL(lSQL, lParamDict);

  finally
    lParamDict.Free;
  end;

end;

function TDaoRTTI.DeleteByProp(const pObject: TObject): Boolean;
var
  lType: TRttiType;
  lTable, lSQL: String;
  lWhereColumns: TArray<TRttiProperty>;
  lParamDict: TDictionary<String, Variant>;
  lProperty: TRttiProperty;
  lProp: String;
begin

  Result := False;

  lType := GetRttiType(pObject);
  lTable := lType.GetAttribute<TDBTable>.TableName;

  if (FPropertiesToWhere.Count = 0) then
    raise ESemPropriedadeLista.Create;

  lWhereColumns := [];
  for lProp in FPropertiesToWhere do
  begin

    for lProperty in lType.GetProperties do
    begin
      if ((SameText(lProperty.Name, lProp.Trim)) and (lProperty.HasAttribute<TDBColumnAttribute>)) then
      begin
        lWhereColumns := lWhereColumns + [lProperty];
        Break;
      end;
    end;

  end;

  if (Length(lWhereColumns) = 0) then
    raise EWhereVazio.Create;

  lSQL := BuildDeleteSQL(lTable, lWhereColumns);

  lParamDict := TDictionary<String, Variant>.Create;
  try

    for lProperty in lWhereColumns do
    begin
      lParamDict.Add(lProperty.Name, GetParamValue(pObject, lProperty));
    end;

    Result := ExecuteSQL(lSQL, lParamDict);

  finally
    lParamDict.Free;
    FPropertiesToWhere.Clear;
  end;

end;

function TDaoRTTI.DeleteBySQLText(const pObject: TObject;
  const pWhereClause: string = ''): Boolean;
var
  lType: TRttiType;
  lTable, lSQL: String;
begin

  Result := False;

  if (pWhereClause.Trim.IsEmpty) then
    raise EWhereVazio.Create;

  lType := GetRttiType(pObject);
  lTable := lType.GetAttribute<TDBTable>.TableName;

  lSQL := Format('DELETE FROM %s WHERE %s', [lTable, pWhereClause]);

  Result := ExecuteSQL(lSQL, nil);

end;

destructor TDaoRTTI.Destroy;
begin
  FPropertiesToWhere.Free;
  FContext.Free;
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

      if Assigned(pParamDict) then
      begin
        for lPair in pParamDict do
        begin
          if (VarIsNull(lPair.Value)) then
            lQuery.Params.ParamByName(lPair.Key).Clear
          else
            lQuery.Params.ParamByName(lPair.Key).Value := lPair.Value;
        end;
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

function TDaoRTTI.GetParamValue(const pObject: TObject;
  const pProperty: TRttiProperty): Variant;
var
  lValue: TValue;
begin

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

  // Converte o TValue para tipos específicos para persistir no banco de dados
  if (lValue.TypeInfo = TypeInfo(TDate)) then
    Result := FormatDateTime('yyyy/mm/dd', lValue.AsExtended)
  else if (lValue.TypeInfo = TypeInfo(TDateTime)) then
    Result := FormatDateTime('yyyy/mm/dd hh:MM:ss', lValue.AsExtended)
  else
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
  lAttrColumn: TDBColumnAttribute;
  lWhereClause: String;
  I: Integer;
begin
  Result := '';

  for I := 0 to High(pWhereCols) do
  begin

    lAttrColumn := pWhereCols[I].GetAttribute<TDBColumnAttribute>;

    if (I > 0) then
      lWhereClause := lWhereClause + ' AND ';

    lWhereClause := lWhereClause + Format('%s=:%s', [lAttrColumn.FieldName, pWhereCols[I].Name]);

  end;

  Result := Format('DELETE FROM %s WHERE %s', [pTable, lWhereClause]);
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
  lSetList: TStringList;
  lProperty: TRttiProperty;
  lAttrColumn: TDBColumnAttribute;
  lWhereClause: String;
  I: Integer;
begin
  Result := '';

  lSetList := TStringList.Create;
  lWhereClause := '';
  try

    for lProperty in pSetCols do
    begin
      lAttrColumn := lProperty.GetAttribute<TDBColumnAttribute>;
      lSetList.Add(Format('%s=:%s', [lAttrColumn.FieldName, lProperty.Name]));
    end;

    for I := 0 to High(pWhereCols) do
    begin

      lAttrColumn := pWhereCols[I].GetAttribute<TDBColumnAttribute>;

      if (I > 0) then
        lWhereClause := lWhereClause + ' AND ';

      lWhereClause := lWhereClause + Format('%s=:%s', [lAttrColumn.FieldName, pWhereCols[I].Name]);

    end;

    Result := Format('UPDATE %s SET %s WHERE %s', [pTable, lSetList.CommaText,
      lWhereClause]);

  finally
    lSetList.Free;
  end;

end;

function TDaoRTTI.GetRttiType(const pObject: TObject): TRttiType;
begin
  Result := FContext.GetType(pObject.ClassType);
  if not(CheckTableAttribute(Result)) then
    raise ESemAtributoTabela.Create(Result.Name);
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
  lContextType: TRttiType;
  lProperty: TRttiProperty;
  lSQL, lTable: string;
  lColumns: TArray<TRttiProperty>;
  lParamDict: TDictionary<String, Variant>;
begin
  Result := False;

  lContextType := GetRttiType(pObject);
  lTable := lContextType.GetAttribute<TDBTable>.TableName;
  lColumns := ExtractColumnProps(lContextType);

  if (Length(lColumns) = 0) then
    raise EClasseNaoMapeada.Create(lContextType.Name);

  lSQL := BuildInsertSQL(lTable, lColumns);

  lParamDict := TDictionary<String, Variant>.Create;
  try

    for lProperty in lColumns do
    begin
      lParamDict.Add(lProperty.Name, GetParamValue(pObject, lProperty));
    end;

    Result := ExecuteSQL(lSQL, lParamDict);

  finally
    lParamDict.Free;
  end;
end;

function TDaoRTTI.UpdateBySQLText(const pObject: TObject;
  const pWhereClause: string): Boolean;
var
  lContextType: TRttiType;
  lColumns: TArray<TRttiProperty>;
  lProperty: TRttiProperty;
  lSQL, lTable: string;
  lParamDict: TDictionary<String, Variant>;
  lSets: TStringList;
begin

  Result := False;

  if (pWhereClause.Trim.IsEmpty) then
    raise EWhereVazio.Create;

  lContextType := GetRttiType(pObject);
  lTable := lContextType.GetAttribute<TDBTable>.TableName;

  lColumns := ExtractColumnProps(lContextType);
  if (Length(lColumns) = 0) then
    raise EClasseNaoMapeada.Create(lContextType.Name);

  lSets := TStringList.Create;
  lParamDict := TDictionary<String, Variant>.Create;
  try

    for lProperty in lColumns do
    begin
      lSets.Add(Format('%s=:%s', [lProperty.GetAttribute<TDBColumnAttribute>.FieldName, lProperty.Name]));
      lParamDict.Add(lProperty.Name, GetParamValue(pObject, lProperty));
    end;

    lSQL := Format('UPDATE %s SET %s WHERE %s', [lTable, lSets.CommaText, pWhereClause]);

    Result := ExecuteSQL(lSQL, lParamDict);

  finally
    lSets.Free;
    lParamDict.Free;
  end;

end;

function TDaoRTTI.UpdateByPK(const pObject: TObject): Boolean;
var
  lType: TRttiType;
  lProperty, lPk: TRttiProperty;
  lSQL, lTable: string;
  lPkValue: Variant;
  lColumns: TArray<TRttiProperty>;
  lParamDict: TDictionary<String, Variant>;
begin

  Result := False;

  lType := GetRttiType(pObject);
  lTable := lType.GetAttribute<TDBTable>.TableName;

  lPk := FindPrimaryKeyProperty(lType);
  if (lPk = nil) then
    raise ESemAtributoChavePrimaria.Create(lTable);

  lPkValue := GetParamValue(pObject, lPk);
  if ((VarIsNull(lPkValue)) or (lPkValue <= 0)) then
    raise EChavePrimariaNula.Create;

  lColumns := ExtractColumnProps(lType);
  lSQL := BuildUpdateSQL(lTable, lColumns, TArray<TRttiProperty>.Create(lPk));

  lParamDict := TDictionary<String, Variant>.Create;
  try

    for lProperty in lColumns do
    begin
      lParamDict.Add(lProperty.Name, GetParamValue(pObject, lProperty));
    end;

    lParamDict.Add(lPk.Name, lPkValue);

    Result := ExecuteSQL(lSQL, lParamDict);

  finally
    lParamDict.Free;
  end;

end;

function TDaoRTTI.LoadObjectByPK(const pObject: TObject): Boolean;
var
  lType: TRttiType;
  lProperty, lPk: TRttiProperty;
  lSQL, lTable, lFieldName: string;
  lQuery: TFDQuery;
  lPkValue: Variant;
  lAttr: TDBColumnAttribute;
begin

  Result := False;

  lType := GetRttiType(pObject);
  lTable := lType.GetAttribute<TDBTable>.TableName;

  lPk := FindPrimaryKeyProperty(lType);
  if (lPk = nil) then
    raise ESemAtributoChavePrimaria.Create(lTable);

  lPkValue := GetParamValue(pObject, lPk);
  if ((VarIsNull(lPkValue)) or (lPkValue <= 0)) then
    raise EChavePrimariaNula.Create;

  lSQL := Format('SELECT * FROM %s WHERE %s = :%s', [lTable, lPk.GetAttribute<TDBColumnAttribute>.FieldName, lPk.Name]);

  lQuery := TFDQuery.Create(nil);
  try

    lQuery.Connection := FConnection;
    lQuery.SQL.Text := lSQL;
    lQuery.ParamByName(lPk.Name).Value := lPkValue;
    lQuery.Open;

    if not(lQuery.IsEmpty) then
    begin

      for lProperty in lType.GetProperties do
      begin

        if (lProperty.HasAttribute<TDBColumnAttribute>) then
        begin

          lAttr := lProperty.GetAttribute<TDBColumnAttribute>;
          lFieldName := lAttr.FieldName;

          if ((lQuery.FindField(lFieldName) <> nil) and (not lQuery.FieldByName(lFieldName).IsNull)) then
          begin
            if ((lProperty.PropertyType.TypeKind = tkFloat) and (lProperty.PropertyType.Handle = TypeInfo(TDateTime)))
            then
              lProperty.SetValue(pObject, TValue.From<TDateTime>(lQuery.FieldByName(lFieldName).AsDateTime))
            else
              lProperty.SetValue(pObject, TValue.FromVariant(lQuery.FieldByName(lFieldName).Value));
          end;

        end;

      end;

      Result := True;

    end;

  finally
    lQuery.Free;
  end;

end;

procedure TDaoRTTI.ResetPropertiesToDefault(const pObject: TObject);
var
  lType: TRttiType;
  lProperty: TRttiProperty;
  lValue: TValue;
begin

  lType := GetRttiType(pObject);

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

end;

end.
