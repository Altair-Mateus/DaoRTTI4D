unit uDBAttributes;

interface

uses
  System.SysUtils;

type

  TDBBooleanType = (btSN, btAI, btZeroUm);

  // Atributo para a coluna da tabela
  TDBColumnAttribute = class(TCustomAttribute)
  private
    FFieldName: string;
  public
    constructor Create(const pFieldName: string);

    // Nome da coluna no banco de dados
    property FieldName: string read FFieldName;
  end;

  // Atributo que armazena o nome da tabela
  TDBTable = class(TCustomAttribute)
  private
    FTableName: String;
  public
    constructor Create(const pTableName: String);
    property TableName: String read FTableName write FTableName;
  end;

  // Atributo que Indica se a coluna é Primary Key ou não
  TDBIsPrimaryKey = class(TCustomAttribute)
  end;

  // Atributo que Indica se a coluna é auto incremento ou não
  TDBIsAutoIncrement = class(TCustomAttribute)
  end;

  // Atributo que  Indica se a coluna aceita valores Nulos no Insert/Update
  TDBAcceptNull = class(TCustomAttribute)
  end;

  TDBSaveBoolean = class(TCustomAttribute)
  private
    FBooleanType: TDBBooleanType;
  public
    constructor Create(const pBooleanType: TDBBooleanType);
    property BooleanType: TDBBooleanType read FBooleanType write FBooleanType;
  end;

implementation

{
  A classe uDBAttributes tem por objetivo criar atributos personalizados
  que irão auxiliar a Classse uDaoRTTI para realizar as operações com o banco
  de dados. A mesma indica as propriedades das tabelas e colunas do banco de dados.
}

constructor TDBColumnAttribute.Create(const pFieldName: string);
begin
  FFieldName := pFieldName;
end;

{ TDBTable }

constructor TDBTable.Create(const pTableName: String);
begin
  FTableName := pTableName;
end;

{ TDBSaveBoolean }

constructor TDBSaveBoolean.Create(const pBooleanType: TDBBooleanType);
begin
  FBooleanType := pBooleanType;
end;

end.
