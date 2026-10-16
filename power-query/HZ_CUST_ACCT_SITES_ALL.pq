// Sites do cliente.
// 16/10/2026: ECE_TP_LOCATION_CODE (TP do Ship To) renomeada para "TP Location", usada no slicer e na tabela.
let
    Fonte = PowerPlatform.Dataflows(null),
    Workspaces = Fonte{[Id="Workspaces"]}[Data],
    #"5f0e4cee-9281-4b9e-88fb-7af2b207ce9f" = Workspaces{[workspaceId="5f0e4cee-9281-4b9e-88fb-7af2b207ce9f"]}[Data],
    #"8592e41f-8d88-4721-8374-660ec5f9776f" = #"5f0e4cee-9281-4b9e-88fb-7af2b207ce9f"{[dataflowId="8592e41f-8d88-4721-8374-660ec5f9776f"]}[Data],
    HZ_CUST_ACCT_SITES_ALL_ = #"8592e41f-8d88-4721-8374-660ec5f9776f"{[entity="HZ_CUST_ACCT_SITES_ALL",version=""]}[Data],
  #"Renamed Columns" = Table.RenameColumns(HZ_CUST_ACCT_SITES_ALL_, {{"ECE_TP_LOCATION_CODE", "TP "}}),
  #"Renamed Columns 1" = Table.RenameColumns(#"Renamed Columns", {{"TP ", "TP Location"}})
in
    #"Renamed Columns 1"
