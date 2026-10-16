# Report RLM – Acumulados (CUM): documentação

Documento de referência do report **RLM** (página **Acumulados**): o que ele mostra, de onde vêm os dados, como cada medida funciona e como interpretar os resultados.

> **Nomenclatura usada neste documento (após a correção de nomes de 16/10/2026):**
> - **CUM Eaton** = acumulado **embarcado pela Eaton** (Oracle, CUM keys).
> - **CUM Cliente** = acumulado **recebido pelo cliente**, informado por ele no schedule EDI.

---

## 1. Objetivo do report

Comparar, por **cliente / Ship To / item / PO**, o acumulado que a **Eaton embarcou** com o acumulado que o **cliente diz ter recebido**.

As duas quantidades **não precisam ser iguais**. O report existe justamente para mostrar a diferença (discrepância de CUM), que precisa ser entendida e, se for o caso, tratada.

---

## 2. Conceitos de negócio

### 2.1 CUM (acumulado)
Quantidade **acumulada** de um item desde um ponto de início: uma data de corte, o início de um PO, o início do ano etc.
- **Lado Eaton:** soma de tudo o que foi **embarcado** (ship confirm) para aquele Ship To, item e PO.
- **Lado cliente:** soma de tudo o que o cliente **recebeu**, informada no schedule EDI.

### 2.2 Diferença entre CUM Eaton e CUM Cliente
| Situação | Causa mais comum |
|---|---|
| CUM Eaton **maior** que CUM Cliente | Material **em trânsito** (embarcado e ainda não recebido), recebimento ainda não lançado no cliente, schedule do cliente com data anterior ao último embarque |
| CUM Eaton **menor** que CUM Cliente | Embarque não registrado ou estornado na Eaton, ajuste manual de CUM, cliente contando recebimento de outro fornecedor, PO ou Ship To |
| Diferença grande e "antiga" | CUM reset de um dos lados (novo PO, virada de ano), CUM key antiga ou inativa, erro de cadastro |

### 2.3 CUM Key (Oracle)
Registro que guarda o acumulado da Eaton (`RLM_CUST_ITEM_CUM_KEYS_ALL`). Uma CUM key é identificada pela combinação definida nas **Processing Rules** do cliente:

| Configuração (CUM Workbench / Processing Rules) | O que define |
|---|---|
| **CUM Org Level** (ex.: *Ship To/Ship From*) | Qual nível de endereço separa os acumulados: Ship To, Bill To, Intermediate Ship To etc. |
| **CUM Type** (ex.: *CUM By Purchase Order*) | O que "zera" ou separa o acumulado: por PO, por data, por data e ano, até reset manual etc. |

Exemplo (John Deere): *CUM By Purchase Order* + *Ship To/Ship From*. Isso significa **uma CUM key por Ship From + Ship To + Item + PO**.

No Oracle: **CUM Workbench → Ship To → Item → CUM Key Details** (coluna *Active Qty* = `CUM_QTY`).

### 2.4 Schedule EDI (Release Management)
Arquivo que o cliente envia, por exemplo 830 (Planning) ou 862 (Shipping), com a demanda e as informações de recebimento. Nas **linhas** do schedule há:

| Detail Type | Sub Type | Qty Type | Significado |
|---|---|---|---|
| Firm Demand / Forecast | Day/Week… | Actual | Demanda (quanto e quando o cliente quer) |
| **Shipped/Received** | **Customer CUM** | **Cumulative** | **Acumulado recebido pelo cliente** → é o **CUM Cliente** |

No Oracle: **Release Management Workbench → Schedule → Lines → item → linha "Shipped/Received – Customer CUM"**.

### 2.5 Ship To × Account Number × TP Location
| Campo | O que é | Exemplo (John Deere Reman) |
|---|---|---|
| **ACCOUNT_NUMBER** | Número da **conta** do cliente | 010678766 |
| **Ship To** (Location) | **Local de entrega**, um site dentro da conta | `4444062` e `010678766` |
| **SHIP_TO_ADDRESS_ID** | ID interno do Ship To (`CUST_ACCT_SITE_ID`) | 1571961 (= 4444062) e 698838 (= 010678766) |
| **TP Location Code** | Código EDI do Ship To, cadastrado no site do cliente | 07076 (= 4444062) e 78766 (= 010678766) |

Uma conta pode ter **vários Ship Tos**, e cada um tem seu TP Location e suas CUM keys.

> **Atenção:** o header do schedule também tem um "TP Location" (`ECE_TP_LOCATION_CODE_EXT`), mas esse é o código do **envelope EDI**, não necessariamente o do Ship To de cada linha. A John Deere, por exemplo, manda schedules com header `07076` mesmo tendo dois Ship Tos. Por isso o report **não usa** o TP do header. No modelo, essa coluna se chama `RLM_SCHEDULE_HEADERS_ALL[TP LocationOLD]`.

---

## 3. Fontes de dados (tabelas do modelo)

Todas as tabelas vêm de **Dataflows** do Power BI, que são cópias de tabelas do Oracle EBS.

| Tabela | Uso no report | Colunas principais |
|---|---|---|
| `RLM_SCHEDULE_LINES_ALL` | Linhas dos schedules EDI → **CUM Cliente** e PN Cliente | `CUSTOMER_ITEM_ID`, `CUSTOMER_ITEM_EXT` (PN Cliente), `SHIP_TO_ADDRESS_ID`, `CUST_PO_NUMBER`, `QTY_TYPE_CODE`, `PRIMARY_QUANTITY`, `HEADER_ID`, `START_DATE_TIME`, `LINE_ID` |
| `RLM_SCHEDULE_HEADERS_ALL` | Cabeçalho do schedule (cliente do schedule) | `HEADER_ID`, `CUSTOMER_ID`, `TP Location` (do envelope, **não usado no visual**) |
| `RLM_CUST_ITEM_CUM_KEYS_ALL` | CUM keys → **CUM Eaton** | `CUSTOMER_ITEM_ID`, `SHIP_TO_ADDRESS_ID`, `PURCHASE_ORDER_NUMBER`, `CUM_QTY`, `LAST_UPDATE_DATE`, `INACTIVE_FLAG`, `SHIP_FROM_ORG_ID` |
| `HZ_CUST_ACCT_SITES_ALL` | Sites (endereços) do cliente → **TP Location** | `CUST_ACCT_SITE_ID`, `TP Location` (= `ECE_TP_LOCATION_CODE` do Oracle, renomeada) |
| `HZ_CUST_SITE_USES_ALL` | Uso SHIP_TO do site → **Ship To** (nome igual ao do Oracle) | `CUST_ACCT_SITE_ID`, `Ship To` (`LOCATION`) |
| `HZ_CUST_ACCOUNTS` | Conta do cliente | `CUST_ACCOUNT_ID`, `ACCOUNT_NUMBER` |
| `HZ_PARTIES` | Nome do cliente | `PARTY_ID`, `Cliente` |
| `MTL_CUSTOMER_ITEM_XREFS` / `MTL_SYSTEM_ITEMS_B` | Relação PN Cliente → PN Eaton | `CUSTOMER_ITEM_ID`, `INVENTORY_ITEM_ID`, `PN Eaton` |

### 3.1 Tratamento da `HZ_CUST_SITE_USES_ALL` (Power Query)
- Mantém só `SITE_USE_CODE = "SHIP_TO"`.
- Fica **uma linha por site** (`CUST_ACCT_SITE_ID`). Se houver mais de uma, prioriza a ativa (`STATUS = A`).
- `LOCATION` é renomeada para **Ship To**.

---

## 4. Relacionamentos que importam

```
HZ_PARTIES ─< HZ_CUST_ACCOUNTS ─< RLM_SCHEDULE_HEADERS_ALL ─< RLM_SCHEDULE_LINES_ALL
                                                                   │  (CUSTOMER_ITEM_ID, muitos-para-muitos, filtro nos dois sentidos)
HZ_CUST_SITE_USES_ALL ─1:1─ HZ_CUST_ACCT_SITES_ALL ─< RLM_CUST_ITEM_CUM_KEYS_ALL ┘
                                                          │
                                       MTL_CUSTOMER_ITEM_XREFS ─> MTL_SYSTEM_ITEMS_B
```

O que isso significa na prática:
- **TP Location** e **Ship To** (vindos dos sites) filtram as **CUM keys** diretamente.
- As **linhas do schedule** e as **CUM keys** só se ligam pelo **item** (`CUSTOMER_ITEM_ID`). O relacionamento **não** liga Ship To nem PO. Por isso a medida **CUM Cliente** aplica esses filtros dentro do próprio DAX (seção 5.2).

---

## 5. Medidas

### 5.1 CUM Eaton (acumulado embarcado pela Eaton)

```DAX
CUM Eaton =
CALCULATE (
    MAX ( RLM_CUST_ITEM_CUM_KEYS_ALL[CUM_QTY] ),
    TREATAS ( VALUES ( RLM_SCHEDULE_LINES_ALL[CUSTOMER_ITEM_ID] ), RLM_CUST_ITEM_CUM_KEYS_ALL[CUSTOMER_ITEM_ID] )
)
```

**Como funciona**
1. Considera as CUM keys do **item** que está na linha do visual (`TREATAS` pelo `CUSTOMER_ITEM_ID`).
2. O **Ship To** é filtrado pelo TP Location / Ship To da linha do visual, através do relacionamento com os sites.
3. O **PO** é filtrado pela coluna `PURCHASE_ORDER_NUMBER` do visual.
4. Retorna o `CUM_QTY` da CUM key, que é o mesmo valor de *Active Qty* no CUM Key Details do Oracle.

**Regra de negócio:** é o acumulado **embarcado** pela Eaton, atualizado pelo Oracle a cada embarque ou ajuste de CUM.

**Por que não usa mais o TP do header:** a versão antiga filtrava os sites pelo TP do header do schedule. Ship Tos cujo TP nunca aparece no envelope EDI (ex.: 78766) ficavam **sempre em branco**.

---

### 5.2 CUM Cliente (acumulado recebido, informado pelo cliente)

```DAX
CUM Cliente =
VAR _ShipTos =
    FILTER ( VALUES ( RLM_CUST_ITEM_CUM_KEYS_ALL[SHIP_TO_ADDRESS_ID] ), RLM_CUST_ITEM_CUM_KEYS_ALL[SHIP_TO_ADDRESS_ID] <> "" )
VAR _POs =
    FILTER ( VALUES ( RLM_CUST_ITEM_CUM_KEYS_ALL[PURCHASE_ORDER_NUMBER] ), RLM_CUST_ITEM_CUM_KEYS_ALL[PURCHASE_ORDER_NUMBER] <> "" )
VAR _FiltraShipTo = NOT ISEMPTY ( _ShipTos )
VAR _FiltraPO     = NOT ISEMPTY ( _POs )
RETURN
    CALCULATE (
        MAX ( RLM_SCHEDULE_LINES_ALL[PRIMARY_QUANTITY] ),
        TOPN (
            1,
            FILTER (
                RLM_SCHEDULE_LINES_ALL,
                RLM_SCHEDULE_LINES_ALL[QTY_TYPE_CODE] = "CUMULATIVE"
                    && ( NOT _FiltraShipTo || RLM_SCHEDULE_LINES_ALL[SHIP_TO_ADDRESS_ID] IN _ShipTos )
                    && ( NOT _FiltraPO     || RLM_SCHEDULE_LINES_ALL[CUST_PO_NUMBER]     IN _POs )
            ),
            RLM_SCHEDULE_LINES_ALL[HEADER_ID], DESC,
            RLM_SCHEDULE_LINES_ALL[START_DATE_TIME], DESC,
            RLM_SCHEDULE_LINES_ALL[LINE_ID], DESC
        )
    )
```

**Como funciona, passo a passo**
1. **Descobre o Ship To e o PO da CUM key** que está na linha do visual (`_ShipTos` e `_POs`). Valores em branco são ignorados.
2. **Filtra as linhas de schedule** do item que:
   - são **cumulativas** (`QTY_TYPE_CODE = "CUMULATIVE"`), ou seja, a linha *Shipped/Received – Customer CUM*;
   - são do **mesmo Ship To** da CUM key, se a CUM key tiver Ship To;
   - são do **mesmo PO** da CUM key, se a CUM key tiver PO.
3. **Pega a linha mais recente**: maior `HEADER_ID` (schedule mais novo). Em caso de empate, a maior `START_DATE_TIME` e depois o maior `LINE_ID`.
4. Retorna a quantidade (`PRIMARY_QUANTITY`) dessa linha.

**Regras de negócio**

| Situação | Comportamento |
|---|---|
| CUM key com Ship To e PO (ex.: CUM By Purchase Order) | Usa o último schedule **daquele Ship To e daquele PO** |
| CUM key sem PO (ex.: CUM By Date) | Filtro de PO ignorado; usa o último schedule **daquele Ship To** |
| CUM key sem Ship To (ex.: CUM Org Level por Bill To) | Filtro de Ship To ignorado |
| **Não existe schedule** para aquele Ship To/PO | **Em branco** (de propósito; ver seção 7) |

**Por que filtra Ship To e PO:** a versão antiga pegava o schedule mais recente do item em **qualquer** Ship To ou PO da conta. Exemplo real: John Deere Engine Works, R518328, TP 03131, PO 5500123006. O report mostrava **394.752**, que é o CUM do PO 5500123005 do Ship To 88858. O correto é **47.136**.

---

### 5.3 Exibir Linha (medida auxiliar de filtro)

```DAX
Exibir Linha =
IF ( NOT ISBLANK ( [CUM Eaton] ) || NOT ISBLANK ( [CUM Cliente] ), 1 )
```

- É usada **só como filtro do visual** (`Exibir Linha = 1`). Não deve ser colocada como coluna.
- Mostra a linha se **pelo menos um** dos CUMs existir. Assim aparecem também os Ship Tos/POs que têm CUM key, mas não têm schedule (ex.: 78766).
- Não retorna 0 de propósito. Se retornasse 0, o Power BI tentaria montar todas as combinações possíveis de cliente × PN × TP × PO e o visual travaria.

---

## 6. O visual (página Acumulados)

| Elemento | Campo |
|---|---|
| Slicer Cliente | `HZ_PARTIES[Cliente]` |
| Slicer PN Cliente | `RLM_SCHEDULE_LINES_ALL[PN Cliente]` |
| Slicer TP Location | `HZ_CUST_ACCT_SITES_ALL[TP Location]` (TP do **Ship To**) |
| Slicer ACCOUNT_NUMBER | `HZ_CUST_ACCOUNTS[ACCOUNT_NUMBER]` |
| Slicer Ship To | `HZ_CUST_SITE_USES_ALL[Ship To]` |
| Tabela | Cliente, Ship To, CUM Cliente, PN Cliente, CUM Eaton, TP Location, PN Eaton, PURCHASE_ORDER_NUMBER, LAST_UPDATE_DATE |
| Filtro do visual | **Exibir Linha = 1** |

- **Uma linha = um Ship To + item + PO** (uma CUM key).
- **PURCHASE_ORDER_NUMBER deve ficar no visual.** Sem ele, itens com mais de um PO no mesmo Ship To ficam misturados.
- **LAST_UPDATE_DATE** = última atualização da CUM key no Oracle.
- **Linha de Total:** mostra o `MAX` geral e **não tem significado de negócio**. Pode ser desligada.

---

## 7. Como interpretar

| O que aparece | Significado |
|---|---|
| CUM Cliente ≈ CUM Eaton | Situação normal. Pequena diferença geralmente é trânsito |
| CUM Eaton > CUM Cliente | Provável material em trânsito ou recebimento não lançado no cliente |
| CUM Eaton < CUM Cliente | Verificar embarques, estornos ou ajustes de CUM na Eaton |
| **CUM Cliente em branco** | **Não há schedule** (linha Customer CUM) para aquele Ship To/PO nos dados do BI. Exemplos: Ship To desativado (78766), PO que o cliente não usa mais (84000), schedule sem linha cumulativa, schedule antigo fora do histórico do Dataflow |
| CUM Cliente = 0 | O cliente mandou o acumulado zerado no último schedule daquele Ship To/PO (reset, Ship To novo ou inativo) |
| Valores diferentes do Oracle | Verificar a hora do **último refresh do Dataflow**. Se a CUM key ou o schedule mudou depois, a diferença é esperada |

---

## 8. Perguntas frequentes

**Por que o TP 78766 (John Deere Reman) aparece com CUM Cliente em branco?**
O Ship To 010678766 (TP 78766) tem CUM keys, mas não recebe schedules: a John Deere manda tudo para o Ship To 4444062 (TP 07076). A CUM key do 78766 está parada desde 11/06/2026, e o mesmo PO hoje está no 07076.

**Por que o ACCOUNT_NUMBER é igual para Ship Tos diferentes?**
ACCOUNT_NUMBER é a **conta**. Uma conta tem vários Ship Tos. Na John Deere Reman, um dos Ship Tos tem o **nome igual** ao número da conta (010678766), o que costuma confundir.

**Por que o mesmo PN aparece em mais de uma linha?**
Porque tem mais de uma CUM key: Ship Tos diferentes e/ou POs diferentes. Exemplo: R534237 no TP 07076 com os POs 5500133533 e 84000.

**O CUM Eaton tem que ser igual ao CUM Cliente?**
Não. São visões diferentes (embarcado × recebido). O report serve para mostrar e acompanhar a diferença.

**Por que no começo o 78766 não aparecia no filtro de TP Location?**
O slicer usava o TP do **header** do schedule (envelope EDI), que nunca vem com 78766. Hoje ele usa o TP do **Ship To** (cadastro do site).

**Por que antes havia linhas duplicadas com CUM vazio?**
As CUM keys de **todos** os Ship Tos da conta apareciam embaixo do TP do header, porque o vínculo com o schedule era só pelo item. Isso foi resolvido ao usar o TP do Ship To.

---

## 9. Histórico de correções (16/10/2026)

| # | Problema | Causa | Correção |
|---|---|---|---|
| 1 | TP 78766 não aparecia no slicer | Slicer usava o TP do header do schedule (envelope EDI) | TP Location passou a vir de `HZ_CUST_ACCT_SITES_ALL[TP Location]` (= `ECE_TP_LOCATION_CODE`) |
| 2 | PNs duplicados com CUM vazio | CUM keys de outros Ship Tos agrupadas no TP do header | Mesma correção do item 1 |
| 3 | CUM do schedule vinha de outro PO/Ship To (ex.: 394.752 em vez de 47.136) | Medida pegava o schedule mais recente do item, sem olhar Ship To/PO | Medida do schedule filtra pelo Ship To e PO da CUM key |
| 4 | CUM das CUM keys sempre vazio no 78766 | Medida exigia que o TP do Ship To aparecesse no header | Removido o filtro pelo TP do header |
| 5 | Linhas sem schedule sumiam ou mostravam valor de outro Ship To | Filtro "CUM … não está em branco" e fallback | Fallback removido; filtro trocado por **Exibir Linha = 1** |
| 6 | Nomes das medidas invertidos | A medida do schedule se chamava "CUM Eaton" | Renomeadas: schedule = **CUM Cliente**, CUM keys = **CUM Eaton** |
| 7 | Ship To não aparecia igual ao Oracle | Faltava a tabela de uso do site | Incluída `HZ_CUST_SITE_USES_ALL` (coluna Ship To) |

---

## 10. Roteiro de validação com o Oracle

| Coluna do BI | Onde conferir no Oracle |
|---|---|
| CUM Eaton | **CUM Workbench** → Customer + Ship To → item → **CUM Key Details** → *Active Qty* do mesmo *Cust Purchase Order* |
| CUM Cliente | **Release Management Workbench** → schedule mais recente do Ship To → Lines → item → linha *Shipped/Received – Customer CUM* → *Qty* |
| TP Location / Ship To | CUM Workbench → *Ship To Locations* |
| PURCHASE_ORDER_NUMBER | CUM Key Details → *Cust Purchase Order* |

Antes de comparar, confira a hora do **último refresh do Dataflow**. Mudanças no Oracle depois desse horário ainda não estão no BI.

Sugestão de amostra: vários Ship Tos na mesma conta (John Deere), vários POs no mesmo item (R534237), um caso com CUM Cliente em branco, um cliente sem PO na CUM key (Cummins/GM) e 1 ou 2 PNs de outros clientes (CAT, Lear, Ford).

---

## 11. Limitações e pontos de atenção

1. **Linhas cumulativas que não são "Customer CUM":** a medida CUM Cliente filtra só `QTY_TYPE_CODE = "CUMULATIVE"`. Se algum cliente mandar outras linhas cumulativas (ex.: autorizações FAB/RAW), elas podem ser escolhidas. A melhoria pendente é filtrar também por `ITEM_DETAIL_TYPE` / `ITEM_DETAIL_SUBTYPE` (Shipped/Received – Customer CUM).
2. **Tipos de schedule:** se o cliente envia Planning (830) e Shipping (862) com Customer CUM, vale o **mais recente** (maior `HEADER_ID`).
3. **`HEADER_ID` é texto:** a ordenação "mais recente" funciona enquanto todos os IDs tiverem o mesmo número de dígitos. Recomendação: converter `HEADER_ID` para número inteiro nas tabelas de linhas e de headers.
4. **Histórico do Dataflow:** o BI pode não ter os schedules mais antigos. CUM Cliente em branco pode ser "sem schedule recente".
5. **Várias CUM keys para o mesmo Ship To/item/PO** (ex.: CUM By Date com várias datas de início, ou mais de uma Ship From Org): a CUM Eaton usa o `MAX`, ou seja, o **maior** valor, que pode não ser o da CUM key vigente. Nesses clientes, inclua `CUM_START_DATE` / `SHIP_FROM_ORG_ID` no visual ou ajuste a medida.
6. **CUM keys inativas:** a medida não filtra `INACTIVE_FLAG`. Hoje não foram encontradas inativas nos casos testados.
7. **Atualização:** o BI reflete o último refresh do Dataflow, não o Oracle em tempo real.
