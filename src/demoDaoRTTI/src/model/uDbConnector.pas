unit uDbConnector;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Phys.FB,
  uDbConfig;

type
  TDbConnector = class
  public
    class procedure Connect;

  end;

implementation

{ TDbConnector }

class procedure TDbConnector.Connect;
var
  lConexao: TFDConnection;
  lCaminhobanco: String;
begin

  lConexao := TFDConnection.Create(nil);
  try

    lCaminhobanco := ExtractFilePath(ParamStr(0)) + 'src\dados\BANCODEMO.FDB';

    lConexao.DriverName := 'FB';
    lConexao.Params.Database := lCaminhobanco;
    lConexao.Params.UserName := 'SYSDBA';
    lConexao.Params.Password := 'masterkey';
    lConexao.Params.Add(Format('CharacterSet=%s', ['UTF8']));

    lConexao.Connected := True;

    TDbConfig.InitConnection(lConexao);

  except
    on E: Exception do
    begin
      raise;
    end;
  end;

end;

end.
