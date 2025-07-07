unit uDbConfigExceptions;

interface

uses
  System.SysUtils;

type

  EInitConnection = class(Exception)
  public
    constructor Create;
  end;

  EGetConnection = class(Exception)
  public
    constructor Create;
  end;

  EInitTransaction = class(Exception)
  public
    constructor Create(const pErro: String);
  end;

  EDbCommit = class(Exception)
  public
    constructor Create(const pErro: String);
  end;

  EDbRollback = class(Exception)
  public
    constructor Create(const pErro: String);
  end;

  EDbCommitRetaining = class(Exception)
  public
    constructor Create(const pErro: String);
  end;

  EDbRollbackRetaining = class(Exception)
  public
    constructor Create(const pErro: String);
  end;

implementation

{ EInitConnection }

constructor EInitConnection.Create;
begin
  inherited Create('Conex�o com o banco de dados n�o inicializada!');
end;

{ EDbRollback }

constructor EDbRollback.Create(const pErro: String);
begin
  inherited CreateFmt('Falha ao executar o rollback no banco de dados: %s', [pErro]);
end;

{ EGetConnection }

constructor EGetConnection.Create;
begin
  inherited Create('Falha ao obter a conex�o com o banco de dados!');
end;

{ EInitTransaction }

constructor EInitTransaction.Create(const pErro: String);
begin
  inherited CreateFmt('Falha o iniciar transa��o: %s', [pErro]);
end;

{ EDbCommit }

constructor EDbCommit.Create(const pErro: String);
begin
  inherited CreateFmt('Falha ao executar o commit no banco de dados: %s', [pErro]);
end;

{ EDbCommitRetaining }

constructor EDbCommitRetaining.Create(const pErro: String);
begin
  inherited CreateFmt('Falha ao executar o commit retaining no banco de dados: %s', [pErro]);
end;

{ EDbRollbackRetaining }

constructor EDbRollbackRetaining.Create(const pErro: String);
begin
  inherited CreateFmt('Falha ao executar o rollback retaining no banco de dados: %s', [pErro]);
end;

end.
