# Contexto do projeto: Report RLM Acumulados

Arquivo para retomar o trabalho, por uma pessoa ou por um assistente de IA, sem precisar reconstruir a investigação. Para a explicação de negócio e das medidas, veja [Documentacao_Report_RLM_Acumulados.md](./Documentacao_Report_RLM_Acumulados.md).

Última atualização: **16/10/2026**.

---

## 1. Resumo do projeto

- **O quê:** report Power BI **RLM**, página **Acumulados**. Compara o CUM embarcado pela Eaton (Oracle CUM keys) com o CUM recebido informado pelo cliente (schedule EDI).
- **Fonte:** Oracle EBS (módulo Release Management – RLM), via **Dataflows** do Power BI (workspace `5f0e4cee-9281-4b9e-88fb-7af2b207ce9f`).
- **Formato:** Power BI Project (`.pbip`), modelo em TMDL.
- **Responsável:** Eduardo Apolinário.

## 2. Restrições de trabalho

- **Não há acesso a consultas SQL no Oracle.** A validação é feita só pelas **telas do Oracle** (CUM Workbench, Release Management Workbench) e pelo próprio Power BI.
- **Não alterar os arquivos do `.pbip` diretamente.** O combinado é mandar as instruções (DAX, M, passos) para o responsável aplicar e testar no Power BI Desktop.
- Comunicação em **português**.

## 3. Estado do repositório

| Pasta | Conteúdo |
|---|---|
| `powerbi/` | Projeto PBIP (`RLM.pbip`, `RLM.Report/`, `RLM.SemanticModel/`). As três partes precisam ficar na mesma pasta |
| `dax/` | Versão **oficial** de cada medida alterada |
| `power-query/` | Código M das consultas alteradas ou criadas |
| `docs/` | Este contexto e a documentação funcional |
| `exports/` | CSVs exportados do report. **Ignorado pelo git** (dados de cliente) |

> ⚠️ **O `.pbip` em `powerbi/` é o snapshot de 15/10/2026, de ANTES das correções.** As alterações abaixo foram feitas no Power BI Desktop e **ainda não estão nos arquivos do repositório**. Para sincronizar, salve o projeto no Desktop e copie a pasta por cima de `powerbi/`.
>
> Alterações pendentes de sincronizar:
> 1. `RLM_SCHEDULE_LINES_ALL` (Power Query): colunas `SHIP_TO_ADDRESS_ID` e `CUST_PO_NUMBER` incluídas.
> 2. Medidas `CUM Eaton`, `CUM Cliente` e `Exibir Linha` conforme `dax/`, com os nomes já trocados (seção 6).
> 3. Tabela nova `HZ_CUST_SITE_USES_ALL` (conforme `power-query/`) + relacionamento 1:1 com `HZ_CUST_ACCT_SITES_ALL[CUST_ACCT_SITE_ID]`.
> 4. Visual da tabela e slicer TP Location usando `HZ_CUST_ACCT_SITES_ALL[ECE_TP_LOCATION_CODE]`.
> 5. Filtro do visual: `Exibir Linha = 1`. O filtro antigo "CUM … não está em branco" foi removido.
> 6. Coluna `Ship To` (de `HZ_CUST_SITE_USES_ALL`) adicionada à tabela.

## 4. Linha do tempo da investigação

| # | Sintoma relatado | Evidência | Causa | Correção |
|---|---|---|---|---|
| 1 | TP Location **78766** (John Deere Reman) não aparece no slicer, mas existe no Oracle | Leitura do `cache.abf`: 78766 **não existe** em `RLM_SCHEDULE_HEADERS_ALL.ECE_TP_LOCATION_CODE_EXT`, mas existe em `HZ_CUST_ACCT_SITES_ALL.ECE_TP_LOCATION_CODE` | O slicer usava o TP do **header** (envelope EDI). A John Deere envia todos os schedules com header `07076` | Slicer e tabela passaram a usar o TP do **site** (`HZ_CUST_ACCT_SITES_ALL[ECE_TP_LOCATION_CODE]`) |
| 2 | Usuário reporta "duplicado": PNs repetidos com um dos CUMs vazio (TP 03131) | Linhas repetidas por PN com `LAST_UPDATE_DATE` diferentes | CUM keys de **todos** os Ship Tos da conta agrupadas sob o TP do header | Resolvido pela correção 1 |
| 3 | CUM do schedule errado (R518328, TP 03131: **394.752** em vez de **47.136**) | Tabela de linhas CUMULATIVE: HEADER 7871224 (PO 5500123005) = 394.752; HEADER 7871223 (PO 5500123006) = 47.136. SHIP_TO 690157 → PO …005; SHIP_TO 1633000 → PO …006 | A medida pegava o schedule mais recente do **item**, de qualquer Ship To/PO | Medida do schedule filtra pelo **Ship To e PO da CUM key** |
| 4 | CUM das CUM keys sempre vazio no 78766 | Medida tinha `TREATAS(VALUES(RLM_SCHEDULE_HEADERS_ALL[TP Location]), HZ_CUST_ACCT_SITES_ALL[ECE_TP_LOCATION_CODE])` | Exigia que o TP do site aparecesse no header do EDI | Filtro removido (`dax/CUM Eaton.dax`) |
| 5 | Medida nova com fallback mostrava, no 78766, o CUM do schedule do 07076 | Valores idênticos aos do 07076 | Fallback para a regra antiga quando não há schedule do Ship To/PO | **Decisão:** sem fallback (fica em branco) + filtro `Exibir Linha = 1` |
| 6 | Nomes das medidas invertidos | Oracle Schedule Details: linha *Shipped/Received – Customer CUM – Cumulative* = acumulado do **cliente** | A medida do schedule se chamava "CUM Eaton" | Schedule = **CUM Cliente**; CUM keys = **CUM Eaton** |
| 7 | Ship To no BI diferente do Oracle (4444062 × ACCOUNT_NUMBER 010678766) | ACCOUNT_NUMBER é a conta; Ship To é o `LOCATION` do site use | Faltava a tabela de site uses | Incluída `HZ_CUST_SITE_USES_ALL` (coluna `Ship To`) |

### Análise de impacto da medida do schedule (CSV de 201 linhas, filtro "valor mudou")
- Nenhuma linha ficou vazia com a versão com fallback. Muitas mudaram para o valor do Ship To/PO correto.
- Foi combinado que **CUM Cliente ≠ CUM Eaton não é erro**. O critério de validação é "o valor vem do schedule do mesmo Ship To/PO", e não "bater com o outro CUM".

## 5. Dados de referência (para testes)

**John Deere Reman – Springfield** (ACCOUNT_NUMBER 010678766, CUM By Purchase Order, CUM Org Level Ship To/Ship From, Ship From Org SJC = 3383)

| Ship To (Oracle) | SHIP_TO_ADDRESS_ID | TP Location | Observação |
|---|---|---|---|
| 4444062 | 1571961 | 07076 | Ship To ativo; recebe os schedules |
| 010678766 | 698838 | 78766 | Sem schedule; CUM key parada desde 11/06/2026 |

| Item | Ship To | PO | CUM_QTY (CUM Eaton) | CUM do schedule (CUM Cliente) |
|---|---|---|---|---|
| R534237 | 4444062 / 07076 | 5500133533 | 18.200 (atualizada 15/10/2026 12:09) | 9.800 |
| R534237 | 4444062 / 07076 | 84000 | 12.600 | em branco (sem schedule com esse PO) |
| R534237 | 010678766 / 78766 | 5500133533 | 72.800 | em branco (sem schedule) |

**John Deere Engine Works** (ACCOUNT_NUMBER 021688858)

| Item | TP | SHIP_TO_ADDRESS_ID | PO | CUM Cliente esperado | CUM Eaton |
|---|---|---|---|---|---|
| R518328 | 03131 | 1633000 | 5500123006 | 47.136 | 48.864 |
| R518328 | 88858 | 690157 | 5500123005 | 394.752 | 394.752 |
| R520224 | 03131 | — | 5500126188 | 65.664 | 65.664 |

## 6. Estado final das medidas (tabela `HZ_CUST_ACCOUNTS`)

| Medida | Fonte | Arquivo |
|---|---|---|
| **CUM Eaton** | `RLM_CUST_ITEM_CUM_KEYS_ALL[CUM_QTY]` | [`dax/CUM Eaton.dax`](../dax/CUM%20Eaton.dax) |
| **CUM Cliente** | `RLM_SCHEDULE_LINES_ALL` (CUMULATIVE, mesmo Ship To/PO da CUM key, último schedule) | [`dax/CUM Cliente.dax`](../dax/CUM%20Cliente.dax) |
| **Exibir Linha** | Filtro do visual (= 1) | [`dax/Exibir Linha.dax`](../dax/Exibir%20Linha.dax) |

Medidas de teste que devem ser apagadas, se ainda existirem: `CUM Eaton PO`, `CUM Cliente Teste`, `Dif CUM Eaton`.

## 7. Pendências e próximos passos

1. **Sincronizar o `.pbip`** do Desktop para `powerbi/` (seção 3).
2. **Filtrar o tipo de linha do schedule:** incluir `ITEM_DETAIL_TYPE` e `ITEM_DETAIL_SUBTYPE` no Power Query de `RLM_SCHEDULE_LINES_ALL`, verificar as combinações com `QTY_TYPE_CODE = CUMULATIVE` e, se houver mais de uma, filtrar só *Shipped/Received – Customer CUM* na medida `CUM Cliente`.
3. **`HEADER_ID` como texto:** converter para número inteiro em `RLM_SCHEDULE_LINES_ALL` e `RLM_SCHEDULE_HEADERS_ALL`. A ordenação "mais recente" quebra quando os IDs mudarem de quantidade de dígitos.
4. **Validação com o Oracle** por amostra (roteiro na seção 10 da documentação).
5. Avaliar clientes **CUM By Date** com várias CUM keys por Ship To/item (o `MAX` pode pegar uma CUM key antiga).
6. Opcional: desligar a linha de **Total** do visual (`MAX` sem significado).

## 8. Técnicas úteis

### Ler os dados do `cache.abf` sem abrir o Power BI
O `powerbi/RLM.SemanticModel/.pbi/cache.abf` (≈120 MB, ignorado pelo git) contém os dados importados. Para inspecionar valores distintos de uma coluna:

```bash
pip install pbixray
mkdir -p /tmp/pbx && cp powerbi/RLM.SemanticModel/.pbi/cache.abf /tmp/pbx/DataModel
cd /tmp/pbx && zip -q -0 m.pbix DataModel
```
```python
from pbixray import PBIXRay
from pbixray.utils import get_data_slice
m = PBIXRay('/tmp/pbx/m.pbix'); dm = m._data_model; dec = m._vertipaq_decoder
for x in dm.file_log:
    if x['FileName'].endswith('ECE TP LOCATION CODE EXT (23112).dictionary'):
        valores = dec._read_dictionary(get_data_slice(dm, x['FileName']), 0).values
```
`m.get_table(...)` falha neste arquivo (faltam os `.idfmeta`), mas os **dicionários** (valores distintos por coluna) podem ser lidos. Os nomes dos arquivos internos estão em `dm.file_log`.

### Testes no Power BI sem alterar a medida oficial
1. Criar a nova versão como medida separada (ex.: `X Teste`) e colocar ao lado da oficial.
2. Usar uma medida de diferença **só como filtro do visual**. Como coluna, um valor 0 trava o visual.
3. Não colocar colunas que "quebram" o contexto (`CUST_PO_NUMBER`, `SHIP_TO_ADDRESS_ID` das linhas), porque elas igualam o resultado das duas medidas.
4. Exportar o visual (⋯ → Exportar dados) para `exports/` e analisar o CSV.
