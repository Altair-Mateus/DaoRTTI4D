unit uDaoRTTIExceptions;

interface

uses
  System.SysUtils;

type
  ESemAtributoTabela = class(Exception)
  public
    constructor Create(const pNomeTabela: String);
  end;

  EExecutarSQL = class(Exception)
  public
    constructor Create(const pErro: String);
  end;

  EClasseNaoMapeada = class(Exception)
  public
    constructor Create(const pNomeClasse: String);
  end;

implementation

{ ESemAtributoTabela }

constructor ESemAtributoTabela.Create(const pNomeTabela: String);
begin
  inherited CreateFmt('Classe %s não possui atributo [TDBTable].',
    [pNomeTabela])
end;

{ EExecutarSQL }

constructor EExecutarSQL.Create(const pErro: String);
begin
  inherited Create('Erro ao executar SQL: ' + pErro);
end;

{ EClasseNaoMapeada }

constructor EClasseNaoMapeada.Create(const pNomeClasse: String);
begin
  inherited CreateFmt('Classe %s não possui propiedades mapeadas ou somente propriedade com AutoInc', [pNomeClasse]);
end;

end.
