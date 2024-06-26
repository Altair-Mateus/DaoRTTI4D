unit uDBColumnAttribute;

interface

uses

  System.SysUtils;

type
  TDBColumnAttribute = class(TCustomAttribute)
  private
    FIsPrimaryKey: Boolean;
    FIsAutoIncrement: Boolean;
    FFieldName: string;
    FAcceptNull: Boolean;

  public
    constructor Create(const AFieldName: string; AIsPrimaryKey: Boolean = False;
      AIsAutoIncrement: Boolean = False; AAcceptNull: Boolean = False);
    property FieldName: string read FFieldName;
    property IsPrimaryKey: Boolean read FIsPrimaryKey;
    property IsAutoIncrement: Boolean read FIsAutoIncrement;
    property AcceptNull: Boolean read FAcceptNull write FAcceptNull;
  end;

  TDBTable = class(TCustomAttribute)
  private
    FTableName: String;
  public
    constructor Create(const ATableName: String);
    property TableName: String read FTableName write FTableName;
  end;

implementation

{ TDBColumnAtrribute }

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
