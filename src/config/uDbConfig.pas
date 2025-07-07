unit uDbConfig;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Option;

type
  TDbConfig = class
  strict private
    class var FConnection: TFDConnection;
  public
    class procedure InitConnection(pConnection: TFDConnection);
    class function Connection: TFDConnection;
    class procedure Finalize;

    class procedure InitTransaction;
    class procedure Commit;
    class procedure CommitRetainig;
    class procedure Rollback;
    class procedure RollbackRetaining;
  end;

implementation

{
  TDbConfig:
  Singleton para armazenar a conexão ativa do banco de dados.
}

uses
  uDbConfigExceptions;

class procedure TDbConfig.Commit;
begin
  try
    Connection.Commit;
  except
    on E: Exception do
    begin
      raise EDbCommit.Create(E.Message);
    end;
  end;
end;

class procedure TDbConfig.CommitRetainig;
begin
  try
    Connection.CommitRetaining;
  except
    on E: Exception do
    begin
      raise EDbCommitRetaining.Create(E.Message);
    end;
  end;
end;

class function TDbConfig.Connection: TFDConnection;
begin
  if not(Assigned(FConnection)) then
    raise EGetConnection.Create;
  Result := FConnection;
end;

class procedure TDbConfig.Finalize;
begin
  FreeAndNil(FConnection);
end;

class procedure TDbConfig.InitConnection(pConnection: TFDConnection);
begin
  if not(Assigned(pConnection)) then
    raise EInitConnection.Create;
  FConnection := pConnection;
end;

class procedure TDbConfig.InitTransaction;
begin
  try
    Connection.StartTransaction;
  except
    on E: Exception do
    begin
      raise EInitTransaction.Create(E.Message);
    end;
  end;
end;

class procedure TDbConfig.Rollback;
begin
  try
    Connection.Rollback;
  except
    on E: Exception do
    begin
      raise EDbRollback.Create(E.Message);
    end;
  end;
end;

class procedure TDbConfig.RollbackRetaining;
begin
  try
    Connection.RollbackRetaining;
  except
    on E: Exception do
    begin
      raise EDbRollbackRetaining.Create(E.Message);
    end;
  end;
end;

end.
