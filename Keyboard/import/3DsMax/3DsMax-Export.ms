/*
Keyboard Setup - 3ds Max action table exporter.
Runs inside 3ds Max (Listener fileIn or one-time user startup script).
Exports read-only Action Table metadata; no scene or hotkeys are modified.
*/
(
    local temp_dir = (getEnvVariable "TEMP") + "\\KeyboardSetupMaxImport"
    local request_path = temp_dir + "\\request.ini"
    local status_path = temp_dir + "\\status.ini"
    local output_path = temp_dir + "\\ActionTables.tsv"
    local token = ""
    local output = undefined
    local exported_count = 0

    fn cleanImporterColumn text_value =
    (
        local result = try (text_value as string) catch ("")
        result = substituteString result "\t" " "
        result = substituteString result "\r" " "
        result = substituteString result "\n" " "
        result
    )

    try
    (
        if not doesFileExist request_path do throw "Import request was not found."
        token = getINISetting request_path "Request" "Token"
        setINISetting status_path "Export" "Token" token
        setINISetting status_path "Export" "State" "running"

        output = createFile output_path encoding:#utf8 writeBOM:true
        format "Id\tCategory\tDescription\tActionTable\tContext\n" to:output

        for table_index = 1 to actionMan.numActionTables do
        (
            local action_table = actionMan.getActionTable table_index
            local table_name = cleanImporterColumn action_table.name
            local context_name = cleanImporterColumn action_table.contextName

            for item_index = 1 to action_table.numActionItems do
            (
                local action_item = action_table.getActionItem item_index
                local category_name = ""
                local description_text = ""
                try (action_item.getCategory &category_name) catch()
                try (action_item.getDescription &description_text) catch()
                local action_key = (action_table.id as string) + "-" + (action_item.id as string)
                format "%\t%\t%\t%\t%\n" (cleanImporterColumn action_key) (cleanImporterColumn category_name) (cleanImporterColumn description_text) table_name context_name to:output
                exported_count += 1
            )
        )

        close output
        output = undefined
        setINISetting status_path "Export" "Count" (exported_count as string)
        setINISetting status_path "Export" "State" "done"
        format "Keyboard Setup | Exported % Action Table entries.\n" exported_count
    )
    catch
    (
        try (if output != undefined do close output) catch()
        try (setINISetting status_path "Export" "Token" token) catch()
        try (setINISetting status_path "Export" "State" "error") catch()
        try (setINISetting status_path "Export" "Message" (getCurrentException() as string)) catch()
        format "Keyboard Setup | Export failed: %\n" (getCurrentException())
    )
)
