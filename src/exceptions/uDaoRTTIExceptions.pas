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

  EWhereVazio = class(Exception)
  public
    constructor Create;
  end;

  ESemAtributoChavePrimaria = class(Exception)
  public
    constructor Create(const pNomeClasse: String);
  end;

  EChavePrimariaNula = class(Exception)
  public
    constructor Create;
  end;

  ESemPropriedadeLista = class(Exception)
  public
    constructor Create;
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

{ EWhereVazio }

constructor EWhereVazio.Create;
begin
  inherited Create('É necessário informar uma condição para executar um Update!');
end;

{ ESemAtributoChavePrimaria }

constructor ESemAtributoChavePrimaria.Create(const pNomeClasse: String);
begin
  inherited CreateFmt('Classe %s não possui propriedade marcada como chave primária!', [pNomeClasse]);
end;

{ EChavePrimariaNula }

constructor EChavePrimariaNula.Create;
begin
  inherited Create('Id da PK não pode ser nulo ou menor/igual a zero!');
end;

{ ESemPropriedadeLista }

constructor ESemPropriedadeLista.Create;
begin
  inherited Create('Nenhuma propriedade fornecida para construir a cláusula WHERE!');
end;

end.
