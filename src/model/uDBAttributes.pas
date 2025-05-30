unit uDBAttributes;

interface

uses
  System.SysUtils;

type
  // Atributo para a coluna da tabela
  TDBColumnAttribute = class(TCustomAttribute)
  private
    FFieldName: string;
  public
    constructor Create(const AFieldName: string);

    // Nome da coluna no banco de dados
    property FieldName: string read FFieldName;
  end;

  // Atributo que armazena o nome da tabela
  TDBTable = class(TCustomAttribute)
  private
    FTableName: String;
  public
    constructor Create(const ATableName: String);
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

implementation

{
  A classe uDBAttributes tem por objetivo criar atributos personalizados
  que irão auxiliar a Classse uDaoRTTI para realizar as operações com o banco
  de dados. A mesma indica as propriedades das tabelas e colunas do banco de dados.
}

constructor TDBColumnAttribute.Create(const AFieldName: string);
begin
  FFieldName := AFieldName;
end;

{ TDBTable }

constructor TDBTable.Create(const ATableName: String);
begin
  FTableName := ATableName;
end;

end.
