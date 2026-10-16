// Cabeçalho dos schedules EDI.
// 16/10/2026: TP do envelope EDI renomeado para "TP LocationOLD" (não usado no visual).
let
    Fonte = PowerPlatform.Dataflows(null),
    Workspaces = Fonte{[Id="Workspaces"]}[Data],
    #"5f0e4cee-9281-4b9e-88fb-7af2b207ce9f" = Workspaces{[workspaceId="5f0e4cee-9281-4b9e-88fb-7af2b207ce9f"]}[Data],
    #"8f3b264a-f27d-44a1-8c80-7adc99436f32" = #"5f0e4cee-9281-4b9e-88fb-7af2b207ce9f"{[dataflowId="2b1ed9ee-fcdf-4bc5-aac7-e931b35b994b"]}[Data],
    RLM_SCHEDULE_HEADERS_ALL_ = #"8f3b264a-f27d-44a1-8c80-7adc99436f32"{[entity="RLM_SCHEDULE_HEADERS_ALL",version=""]}[Data],
    #"Outras Colunas Removidas" = Table.SelectColumns(RLM_SCHEDULE_HEADERS_ALL_,{"HEADER_ID", "CUSTOMER_ID", "SCHEDULE_TYPE", "ECE_TP_LOCATION_CODE_EXT", "ORG_ID"}),
    #"Colunas Renomeadas" = Table.RenameColumns(#"Outras Colunas Removidas",{{"ECE_TP_LOCATION_CODE_EXT", "TP Location"}}),
  #"Renamed Columns" = Table.RenameColumns(#"Colunas Renomeadas", {{"TP Location", "TP LocationOLD"}})
in
    #"Renamed Columns"
