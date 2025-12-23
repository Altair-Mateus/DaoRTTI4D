unit uDaoRTTIExceptions;

interface

uses
  System.SysUtils;

type
  EDaoRTTISemAtributoTabela = class(Exception)
  public
    constructor Create(const pNomeTabela: String);
  end;

  EDaoRTTIExecutarSQL = class(Exception)
  public
    constructor Create(const pErro: String);
  end;

  EDaoRTTIClasseNaoMapeada = class(Exception)
  public
    constructor Create(const pNomeClasse: String);
  end;

  EDaoRTTIWhereVazio = class(Exception)
  public
    constructor Create;
  end;

  EDaoRTTISemAtributoChavePrimaria = class(Exception)
  public
    constructor Create(const pNomeClasse: String);
  end;

  EDaoRTTIChavePrimariaNula = class(Exception)
  public
    constructor Create;
  end;

  EDaoRTTISemPropriedadeLista = class(Exception)
  public
    constructor Create;
  end;

  EDaoRTTIObjetoNulo = class(Exception)
  public
    constructor Create;
  end;

implementation

{ EDaoRTTISemAtributoTabela }

constructor EDaoRTTISemAtributoTabela.Create(const pNomeTabela: String);
begin
  inherited CreateFmt('Classe %s não possui atributo [TDBTable].',
    [pNomeTabela])
end;

{ EDaoRTTIExecutarSQL }

constructor EDaoRTTIExecutarSQL.Create(const pErro: String);
begin
  inherited Create('Erro ao executar SQL: ' + pErro);
end;

{ EDaoRTTIClasseNaoMapeada }

constructor EDaoRTTIClasseNaoMapeada.Create(const pNomeClasse: String);
begin
  inherited CreateFmt('Classe %s não possui propiedades mapeadas ou somente propriedade com AutoInc', [pNomeClasse]);
end;

{ EDaoRTTIWhereVazio }

constructor EDaoRTTIWhereVazio.Create;
begin
  inherited Create('É necessário informar uma condição para executar um Update!');
end;

{ EDaoRTTISemAtributoChavePrimaria }

constructor EDaoRTTISemAtributoChavePrimaria.Create(const pNomeClasse: String);
begin
  inherited CreateFmt('Classe %s não possui propriedade marcada como chave primária!', [pNomeClasse]);
end;

{ EDaoRTTIChavePrimariaNula }

constructor EDaoRTTIChavePrimariaNula.Create;
begin
  inherited Create('Id da PK não pode ser nulo ou menor/igual a zero!');
end;

{ EDaoRTTISemPropriedadeLista }

constructor EDaoRTTISemPropriedadeLista.Create;
begin
  inherited Create('Nenhuma propriedade fornecida para construir a cláusula WHERE!');
end;

{ EDaoRTTIObjetoNulo }

constructor EDaoRTTIObjetoNulo.Create;
begin
  inherited Create('Falha ao obter objeto da classe!');
end;

end.
