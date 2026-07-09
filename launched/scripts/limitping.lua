return {
    id = "limitping",
    description = "Run the limitping command in the background to automatically refresh the 5-hour time window of Codex",
    command = [[
output="$(limitping bg start 2>&1)" || {
    exit_code=$?
    case "$output" in
        *"background watch already running"*)
            exit 0
            ;;
        *)
            printf '%s\n' "$output"
            exit "$exit_code"
            ;;
    esac
}
]]
}
