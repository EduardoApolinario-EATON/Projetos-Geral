// Linhas dos schedules EDI.
// Alteração de 16/10/2026: inclusão de SHIP_TO_ADDRESS_ID e CUST_PO_NUMBER (usadas pela medida CUM Cliente).
// Versão de referência: conferir com a consulta salva no Power BI Desktop.
let
    Fonte = PowerPlatform.Dataflows(null),
    Workspaces = Fonte{[Id="Workspaces"]}[Data],
    #"5f0e4cee-9281-4b9e-88fb-7af2b207ce9f" = Workspaces{[workspaceId="5f0e4cee-9281-4b9e-88fb-7af2b207ce9f"]}[Data],
    #"2b1ed9ee-fcdf-4bc5-aac7-e931b35b994b" = #"5f0e4cee-9281-4b9e-88fb-7af2b207ce9f"{[dataflowId="2b1ed9ee-fcdf-4bc5-aac7-e931b35b994b"]}[Data],
    RLM_SCHEDULE_LINES_ALL_ = #"2b1ed9ee-fcdf-4bc5-aac7-e931b35b994b"{[entity="RLM_SCHEDULE_LINES_ALL",version=""]}[Data],
    #"Outras Colunas Removidas" = Table.SelectColumns(RLM_SCHEDULE_LINES_ALL_,{"LINE_ID", "CUSTOMER_ITEM_EXT", "CUSTOMER_ITEM_ID", "INVENTORY_ITEM_ID", "QTY_TYPE_CODE", "HEADER_ID", "PRIMARY_QUANTITY", "START_DATE_TIME", "SHIP_TO_ADDRESS_ID", "CUST_PO_NUMBER"}),
    #"Colunas Renomeadas" = Table.RenameColumns(#"Outras Colunas Removidas",{{"CUSTOMER_ITEM_EXT", "PN Cliente"}})
in
    #"Colunas Renomeadas"
