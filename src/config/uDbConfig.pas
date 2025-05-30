unit uDbConfig;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client;

type
  TDbConfig = class
  strict private
    class var FConnection: TFDConnection;
  public
    class procedure InitConnection(pConnection: TFDConnection);
    class function Connection: TFDConnection;
    class procedure Finalize;
  end;

implementation

{
  TDbConfig:
  Singleton para armazenar a conex�o ativa do banco de dados.
}

class function TDbConfig.Connection: TFDConnection;
begin
  if not(Assigned(FConnection)) then
    raise Exception.Create('Falha ao obter a conex�o com o banco de dados!');
  Result := FConnection;
end;

class procedure TDbConfig.Finalize;
begin
  FreeAndNil(FConnection);
end;

class procedure TDbConfig.InitConnection(pConnection: TFDConnection);
begin
  if not(Assigned(pConnection)) then
    raise Exception.Create('Conex�o com o banco de dados n�o inicializada!');
  FConnection := pConnection;
end;

end.
