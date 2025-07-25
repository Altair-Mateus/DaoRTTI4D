unit uITransactionScope;

interface

type
  ITransactionScope = interface
    ['{8588EFB8-D859-4E8F-88C2-A1DAB7001953}']
    procedure Commit;
    procedure CommitRetaining(const pEndScope: Boolean = False);
    procedure Rollback;
    procedure RollbackRetaining;
  end;

implementation

end.
