# uDaoRTTI

`uDaoRTTI` é uma biblioteca **leve** e **flexível** para Delphi que **automatiza** operações CRUD (Create, Read, Update, Delete) de forma **genérica**, sem acoplamento à camada de dados.

* **Produtividade**: elimina a escrita manual de SQL, bastando decorar suas classes com atributos.
* **Portabilidade**: suporta **qualquer** banco SQL que o FireDAC acesse (Firebird, MySQL, PostgreSQL, SQL Server etc.).
* **Manutenção simplificada**: mudanças na estrutura de dados exigem apenas ajustes em atributos, não em queries.
* **Desempenho**: minimiza overhead de RTTI reutilizando contextos e gerando SQL enxuto.

## Como funciona

1. **Mapeamento por atributos** (`uDBAttributes` – `src/model`):

   * `[TDBTable('TABELA')]` na classe para definir o nome da tabela.
   * `[TDBColumnAttribute('COLUNA')]` em cada propriedade para definir o campo.
   * `[TDBIsPrimaryKey]`, `[TDBIsAutoIncrement]` e `[TDBAcceptNull]` para indicar chave primária, auto‑incremento e campos nulos.

2. **Configuração da conexão** (`uDbConfig` – `src/config`):

   * `TDbConfig.InitConnection(lConexao: TFDConnection)` registra a conexão do FireDAC.
   * `TDbConfig.Connection` é usada internamente pelo `TDaoRTTI`.
   * `TDbConfig.Finalize` libera a conexão.

3. **Tratamento de exceções** (`uDaoRTTIExceptions` – `src/exceptions`):

   * Exceções específicas para cada cenário (tabela não mapeada, SQL vazio, chave primária ausente, etc.).

4. **Classe principal** (`uDaoRTTI` – `src/model`):

   * Extrai metadados RTTI e valida atributos.
   * Monta dinamicamente instruções SQL (`INSERT`, `UPDATE`, `DELETE`, `SELECT`).
   * Executa via `TFDQuery`, convertendo valores conforme `GetParamValue`.
   * Permite filtrar atualizações/deleções por propriedade (`AddPropertyToWhere`, `UpdateByProp`, `DeleteByProp`).

5. **Exemplo de classe de domínio**:

   ```pascal
   [TDBTable('USUARIOS')]
   TUsuario = class
     private
       FDaoRTTI: TDaoRTTI;
       FId: Integer;
       FNome: String;
     public
       [TDBColumnAttribute('ID'), TDBIsPrimaryKey, TDBIsAutoIncrement]
       property Id: Integer read FId write FId;

       [TDBColumnAttribute('NOME')]
       property Nome: String read FNome write FNome;

       constructor Create;
       destructor Destroy; override;

       function Insert: Boolean;
   end;

   implementation

   constructor TUsuario.Create;
   begin
     FDaoRTTI := TDaoRTTI.Create;
   end;

   destructor TUsuario.Destroy;
   begin
     FDaoRTTI.Free;
     inherited;
   end;

   function TUsuario.Insert: Boolean;
   begin
     Result := FDaoRTTI.Insert(Self);
   end;
   ```

## Tecnologias usadas

* **Delphi** (Object Pascal)
* **FireDAC** (acesso a dados)
* **RTTI** (Run-Time Type Information)
* **Atributos personalizados** (`uDBAttributes`)

## Como incluir no seu projeto

1. **Adicione** ao seu projeto os units:

   * `uDaoRTTI.pas` (em **src/model**)
   * `uDBAttributes.pas` (em **src/model**)
   * `uDaoRTTIExceptions.pas` (em **src/exceptions**)
   * `uDbConfigExceptions.pas` (em **src/exceptions**)
   * `uDbConfig.pas` (em **src/config**)
   * `uITransactionScope.pas` (em **src/interfaces**)
   * `uTransactionScope.pas` (em **src/transactions**)

2. **Inicialize** a conexão antes de usar o DAO e **finalize** ao encerrar a execução do seu projeto. Você pode fazer isso em qualquer parte do seu código. A seguir dois exemplos extraídos da demo:

   **a) Inicialização via `TDbConnector.Connect`:**

   ```pascal
   unit uDbConnector;

   interface

   uses
     System.SysUtils,
     FireDAC.Comp.Client,
     FireDAC.Stan.Def,
     FireDAC.Phys.FB,
     uDbConfig;

   /// Cria e registra a conexão Firebird
   type
     TDbConnector = class
     public
       class procedure Connect;
     end;

   implementation

   class procedure TDbConnector.Connect;
   var
     lConexao: TFDConnection;
     lCaminhoBanco: string;
   begin
     lConexao := TFDConnection.Create(nil);
     try
       lCaminhoBanco := ExtractFilePath(ParamStr(0)) + 'src\dados\BANCODEMO.FDB';

       lConexao.DriverName := 'FB';
       lConexao.Params.Database := lCaminhoBanco;
       lConexao.Params.UserName := 'SYSDBA';
       lConexao.Params.Password := 'masterkey';
       lConexao.Params.Add('CharacterSet=UTF8');

       lConexao.Connected := True;

       // Registra a conexão na DAO RTTI
       TDbConfig.InitConnection(lConexao);
     except
       lConexao.Free;
       raise;
     end;
   end;

   end.
   ```

   **b) Exemplo de uso no `.dpr` (View Source):**

   ```pascal
   begin
     Application.Initialize;
     Application.MainFormOnTaskbar := True;

     try
       TDbConnector.Connect;  // cria a conexão e InitConnection
     except
       on E: Exception do
       begin
         MessageDlg('Erro ao conectar ao banco de dados:'#13#10 + E.Message,
           mtError, [mbOK], 0);
         ExitProcess(1); // encerra o processo de forma limpa
       end;
     end;

     Application.CreateForm(TfrmTelaPrincipal, frmTelaPrincipal);
     Application.Run;

     // Libera a conexão da memória
     TDbConfig.Finalize;
   end;
   ```

3. **Defina** suas classes usando os atributos de mapeamento e delegue CRUD aos métodos do objeto:

   ```pascal
   function TUsuario.Insert: Boolean;
   begin
     Result := FDaoRTTI.Insert(Self);
   end;
   ```
## Transações Avançadas

Com a versão mais recente, **uDaoRTTI** agora integra suporte a transações via `TTransactionScope`, para que você possa agrupar múltiplas operações CRUD em diferentes tabelas dentro de um mesmo bloco transacional:

1. **Definição do escopo transacional**:

   ```pascal
   uses
     uTransactionScope, uUsuario, uObsUsuarios;

   procedure TfrmTelaPrincipal.InsertMultiplasTabelas;
   var
     lUsuario: TUsuario;
     lObs: TObsUsuarios;
     lTransaction: ITransactionScope;
   begin
     lTransaction := TTransactionScope.Create;
     try
       // Atualiza usuário
       lUsuario := TUsuario.Create;
       try
         lUsuario.Id := 7;
         lUsuario.Nome := 'Altair';
         // ... outros campos ...
         lUsuario.UpdateByPK;
       finally
         lUsuario.Free;
       end;

       // Insere observação de log
       lObs := TObsUsuarios.Create;
       try
         lObs.IdUsuario := 7;
         lObs.Descricao := 'Usuário alterado para administrador';
         lObs.Insert;
       finally
         lObs.Free;
       end;

       // Confirma transação (commit)
       lTransaction.Commit;
     except
       on E: Exception do
       begin
         // Em caso de erro, rollback automático no destructor
         ShowMessage('Erro ao processar transação: ' + E.Message);
       end;
     end;
   end;
   ```

2. **Como funciona**:

   * O construtor de `TTransactionScope` chama `InitTransaction`.
   * `Commit` finaliza e libera o escopo.
   * Se você chamar `CommitRetaining(True)`, ainda mantém a transação ativa até o commit final.
   * Se o escopo for destruído sem `Commit`, será executado `Rollback` automaticamente.

3. **Exceções**:

   * Qualquer falha em `InitTransaction`, `Commit`, `Rollback` etc. usa as exceções de `uDbConfigExceptions` para mensagens claras e consistentes.

Com isso, o `uDaoRTTI` passa a oferecer não só CRUD dinâmico, mas também **controle transacional completo** para cenários de múltiplas tabelas e operações atômicas.


## Projeto de exemplo completo

No repositório há um projeto demo em **src/demoDaoRTTI/** contendo:

* **uDbConnector.pas**: inicializa `TFDConnection` com Firebird e chama `TDbConfig.InitConnection`.
* **Formulário** com botões para todas operações CRUD do `uDaoRTTI`.
* **Classe `TUsuario`** modelada com atributos e métodos de conveniência.
* **Banco de dados de exemplo** (`BANCODEMO.FDB`).

Para executar:

1. Abra o projeto demo no Delphi.
2. Compile e rode.
3. Use o formulário para testar inserção, atualização, consulta e remoção de registros.
