unit uDBColumnAttribute;

interface

uses
  System.SysUtils;

type
  //  Atributo para a coluna da tabela
  TDBColumnAttribute = class(TCustomAttribute)
  private
    FIsPrimaryKey: Boolean;
    FIsAutoIncrement: Boolean;
    FFieldName: string;
    FAcceptNull: Boolean;

  public
    constructor Create(const AFieldName: string; AIsPrimaryKey: Boolean = False;
      AIsAutoIncrement: Boolean = False; AAcceptNull: Boolean = False);

    //  Nome da coluna no banco de dados
    property FieldName: string read FFieldName;
    //  Indica se a coluna é Primary Key ou não
    property IsPrimaryKey: Boolean read FIsPrimaryKey;
    // Indica se a coluna é auto incremento ou não
    property IsAutoIncrement: Boolean read FIsAutoIncrement;
    // Indica se a coluna aceita valores Nulos no Insert/Update
    property AcceptNull: Boolean read FAcceptNull write FAcceptNull;
  end;

  // Atributo que armazena o nome da tabela
  TDBTable = class(TCustomAttribute)
  private
    FTableName: String;
  public
    constructor Create(const ATableName: String);
    property TableName: String read FTableName write FTableName;
  end;

implementation

{
  A classe uDBColumnAttribute tem por objetivo criar atributos personalizados
  que irão auxiliar a Classse uDaoRTTI para realizar as operações com o banco
  de dados. A mesma indica as propriedades das tabelas e colunas do banco de dados.
}

constructor TDBColumnAttribute.Create(const AFieldName: string; AIsPrimaryKey: Boolean = False;
      AIsAutoIncrement: Boolean = False; AAcceptNull: Boolean = False);
begin
  FFieldName := AFieldName;
  FIsPrimaryKey := AIsPrimaryKey;
  FIsAutoIncrement := AIsAutoIncrement;
  FAcceptNull := AAcceptNull;
end;

{ TDBTable }

constructor TDBTable.Create(const ATableName: String);
begin
  FTableName := ATableName;
end;

end.
