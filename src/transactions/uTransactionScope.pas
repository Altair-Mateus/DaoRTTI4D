unit uTransactionScope;

interface

uses
  uITransactionScope;

type
  TTransactionScope = class(TInterfacedObject, ITransactionScope)
  private
    FActive: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Commit;
    procedure CommitRetaining(const pEndScope: Boolean = False);
    procedure Rollback;
    procedure RollbackRetaining;

    property Active: Boolean read FActive;

  end;

implementation

{ TTransactionScope }

uses
  uDbConfig;

procedure TTransactionScope.Commit;
begin
  TDbConfig.Commit;
  FActive := False;
end;

procedure TTransactionScope.CommitRetaining(const pEndScope: Boolean = False);
begin
  TDbConfig.CommitRetainig;
  if (pEndScope) then
    FActive := False;
end;

constructor TTransactionScope.Create;
begin
  TDbConfig.InitTransaction;
  FActive := True;
end;

destructor TTransactionScope.Destroy;
begin
  if (FActive) then
    TDbConfig.Rollback;
  inherited;
end;

procedure TTransactionScope.Rollback;
begin
  TDbConfig.Rollback;
  FActive := False;
end;

procedure TTransactionScope.RollbackRetaining;
begin
  TDbConfig.RollbackRetaining;
end;

end.
