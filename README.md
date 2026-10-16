# Report RLM: Acumulados (CUM)

Report Power BI que compara, por **cliente / Ship To / item / PO**, o acumulado **embarcado pela Eaton** (CUM keys do Oracle RLM) com o acumulado **recebido informado pelo cliente** (schedules EDI).

## Estrutura

```
├── powerbi/        Projeto Power BI (PBIP): abrir powerbi/RLM.pbip no Power BI Desktop
├── dax/            Versão oficial das medidas (CUM Eaton, CUM Cliente, Exibir Linha)
├── power-query/    Código M das consultas alteradas/criadas
├── docs/
│   ├── CONTEXTO.md                              Histórico, decisões, estado atual e pendências
│   └── Documentacao_Report_RLM_Acumulados.md   Regras de negócio e explicação das medidas
└── exports/        CSVs exportados do report (ignorado pelo git)
```

## Como abrir
1. Clone o repositório.
2. Abra `powerbi/RLM.pbip` no Power BI Desktop. Habilite *Opções → Recursos de visualização → Formato de arquivo do Projeto do Power BI*, se necessário.
3. Clique em **Atualizar**. Os dados vêm dos Dataflows do workspace e o cache local (`cache.abf`) não é versionado.

## Documentação
- [docs/Documentacao_Report_RLM_Acumulados.md](docs/Documentacao_Report_RLM_Acumulados.md): conceitos de CUM, fontes, medidas, interpretação, FAQ e roteiro de validação com o Oracle.
- [docs/CONTEXTO.md](docs/CONTEXTO.md): contexto completo para retomar o trabalho.

## Observações
- Os arquivos em `powerbi/` precisam ficar juntos (`RLM.pbip` aponta para `RLM.Report`, que aponta para `../RLM.SemanticModel`).
- Ao alterar uma medida no Desktop, atualize também o arquivo correspondente em `dax/`.
- Não versionar exportações com dados de clientes (`exports/`, `*.csv`).
