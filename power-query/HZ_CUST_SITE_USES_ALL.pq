// Tabela nova: nome do Ship To igual ao Oracle (HZ_CUST_SITE_USES_ALL.LOCATION).
// Relacionamento: HZ_CUST_SITE_USES_ALL[CUST_ACCT_SITE_ID] 1:1 HZ_CUST_ACCT_SITES_ALL[CUST_ACCT_SITE_ID] (filtro nos dois sentidos).
let
  Origem = PowerPlatform.Dataflows([]),
  #"Navegação 1" = Origem{[Id = "Workspaces"]}[Data],
  #"Navegação 2" = #"Navegação 1"{[workspaceId = "5f0e4cee-9281-4b9e-88fb-7af2b207ce9f"]}[Data],
  #"Navegação 3" = #"Navegação 2"{[dataflowId = "8592e41f-8d88-4721-8374-660ec5f9776f"]}[Data],
  #"Navegação 4" = #"Navegação 3"{[entity = "HZ_CUST_SITE_USES_ALL", version = ""]}[Data],
  #"Somente Ship To" = Table.SelectRows(#"Navegação 4", each [SITE_USE_CODE] = "SHIP_TO"),
  #"Colunas" = Table.SelectColumns(#"Somente Ship To", {"CUST_ACCT_SITE_ID", "LOCATION", "STATUS"}),
  #"Ativos Primeiro" = Table.Buffer(Table.Sort(#"Colunas", {{"STATUS", Order.Ascending}})),
  #"Um por Site" = Table.Distinct(#"Ativos Primeiro", {"CUST_ACCT_SITE_ID"}),
  #"Renomeado" = Table.RenameColumns(#"Um por Site", {{"LOCATION", "Ship To"}}),
  #"Tipo" = Table.TransformColumnTypes(#"Renomeado", {{"CUST_ACCT_SITE_ID", type text}})
in
  #"Tipo"
