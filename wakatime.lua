VERSION = "1.0.6"

-- micro
local micro = import("micro")
local config = import("micro/config")
local util = import("micro/util")
local shell = import("micro/shell")
-- golang
local filepath = import("filepath")
local http = import("http")
local ioutil = import("io/ioutil")
local os2 = import("os")
local runtime = import("runtime")
-- wakatime
local userAgent = "micro/" .. util.SemVersion:String() .. " micro-wakatime/" .. VERSION
local lastFile = ""
local lastHeartbeat = 0

function init()
        config.MakeCommand("wakatime.apikey", promptForApiKey, config.NoComplete)

        micro.InfoBar():Message("WakaTime initializing...")
        micro.Log("Initializing WakaTime v" .. VERSION)

        checkApiKey()
end

function postinit()
        micro.InfoBar():Message("WakaTime initialized")
        micro.Log("WakaTime initialized")
end

function checkApiKey()
        if not hasApiKey() then
                promptForApiKey()
        end
end

function hasApiKey()
        return getApiKey() ~= nil
end

function getApiKey()
        return getSetting("settings", "api_key")
end

function getConfigFile()
        return filepath.Join(os2.UserHomeDir(), ".wakatime.cfg")
end

function getSetting(section, key)
        local config, err = ioutil.ReadFile(getConfigFile())
        if err ~= nil then
                micro.InfoBar():Message("failed reading ~/.wakatime.cfg")
                micro.Log("failed reading ~/.wakatime.cfg")
                micro.Log(err)
        end

        local lines = util.String(config)
        local currentSection = ""

        for line in lines:gmatch("[^\r\n]+") do
                line = string.rtrim(line)
                if string.starts(line, "[") and string.ends(line, "]") then
                        currentSection = string.lower(string.sub(line, 2, string.len(line) - 1))
                elseif currentSection == section then
                        local parts = string.split(line, "=")
                        local currentKey = string.trim(parts[1])
                        if currentKey == key then
                                return string.trim(parts[2])
                        end
                end
        end

        return ""
end

function setSetting(section, key, value)
        local config, err = ioutil.ReadFile(getConfigFile())
        if err ~= nil then
                micro.InfoBar():Message("failed reading ~/.wakatime.cfg")
                micro.Log("failed reading ~/.wakatime.cfg")
                micro.Log(err)
                return
        end

        local contents = {}
        local currentSection = ""
        local lines = util.String(config)
        local found = false

        for line in lines:gmatch("[^\r\n]+") do
                line = string.rtrim(line)
                if string.starts(line, "[") and string.ends(line, "]") then
                        if currentSection == section and not found then
                                table.insert(contents, key .. " = " .. value)
                                found = true
                        end

                        currentSection = string.lower(string.sub(line, 2, string.len(line) - 1))
                        table.insert(contents, string.rtrim(line))
                elseif currentSection == section then
                        local parts = string.split(line, "=")
                        local currentKey = string.trim(parts[1])
                        if currentKey == key then
                                if not found then
                                        table.insert(contents, key .. " = " .. value)
                                        found = true
                                end
                        else
                                table.insert(contents, string.rtrim(line))
                        end
                else
                        table.insert(contents, string.rtrim(line))
                end
        end

        if not found then
                if currentSection ~= section then
                        table.insert(contents, "[" .. section .. "]")
                end

                table.insert(contents, key .. " = " .. value)
        end

        _, err = ioutil.WriteFile(getConfigFile(), table.concat(contents, "\n"), 0700)
        if err ~= nil then
                micro.InfoBar():Message("failed saving ~/.wakatime.cfg")
                micro.Log("failed saving ~/.wakatime.cfg")
                micro.Log(err)
                return
        end
end

function resourcesFolder()
        return filepath.Join(os2.UserHomeDir(), ".wakatime")
end

function cliPath()
        local ext = ""

        if isWindows() then
                ext = ".exe"
        end

        return "wakatime-cli"
end

function cliExists()
        local _, err = os2.Stat(cliPath())

        if os2.IsNotExist(err) then
                return false
        end

        return true
end

function cliUpToDate()
        if not cliExists() then
                return false
        end

        -- get current version from installed cli
        local currentVersion, err = shell.ExecCommand(cliPath(), "--version")
        if err ~= nil then
                micro.InfoBar():Message("failed to determine current cli version")
                micro.Log("failed to determine current cli version")
                micro.Log(err)
                return true
        end

        micro.Log("Current wakatime-cli version is " .. string.rtrim(currentVersion))
        micro.Log("Checking for updates to wakatime-cli...")

        return false
end

function getArch()
        local arch

        if (os.getenv "os" or ""):match "^Windows" then
                arch = os.getenv "PROCESSOR_ARCHITECTURE"
        else
                arch = io.popen "uname -m":read "*a"
        end

        if (arch or ""):match "64" then
                return "amd64"
        else
                return "386"
        end
end

function getOs()
        return runtime.GOOS
end

function isWindows()
        return getOs() == "windows"
end

function onSave(bp)
        onEvent(bp.buf.AbsPath, true)

        return true
end

function onSaveAll(bp)
        onEvent(bp.buf.AbsPath, true)

        return true
end

function onSaveAs(bp)
        onEvent(bp.buf.AbsPath, true)

        return true
end

function onOpenFile(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onPaste(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectAll(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onDeleteLine(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onCursorUp(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onCursorDown(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onCursorPageUp(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onCursorPageDown(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onCursorLeft(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onCursorRight(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onCursorStart(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onCursorEnd(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectToStart(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectToEnd(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectUp(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectDown(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectLeft(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectRight(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectToStartOfText(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectToStartOfTextToggle(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onWordRight(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onWordLeft(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectWordRight(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onSelectWordLeft(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onMoveLinesUp(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onMoveLinesDown(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onScrollUp(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function onScrollDown(bp)
        onEvent(bp.buf.AbsPath, false)

        return true
end

function enoughTimePassed(time)
        return lastHeartbeat + 120000 < time
end

function onEvent(file, isWrite)
        local time = os.time()
        if isWrite or enoughTimePassed(time) or lastFile ~= file then
                sendHeartbeat(file, isWrite)
                lastFile = file
                lastHeartbeat = time
        end
end

function sendHeartbeat(file, isWrite)
        micro.Log("Sending heartbeat")

        local isDebugEnabled = getSetting("settings", "debug"):lower()
        local args = { "--entity", file, "--plugin", userAgent }

        if isWrite then
                table.insert(args, "--write")
        end

        if isDebugEnabled then
                table.insert(args, "--verbose")
        end

        -- run it in a thread
        shell.JobSpawn(cliPath(), args, nil, sendHeartbeatStdErr, sendHeartbeatExit)
end

function sendHeartbeatStdErr(err)
        micro.Log(err)
        micro.Log("Check your ~/.wakatime/wakatime.log file for more details.")
end

function sendHeartbeatExit(out, args)
        micro.Log("Last heartbeat sent " .. os.date("%c"))
end

function promptForApiKey()
        micro.InfoBar():Prompt("API Key: ", getApiKey(), "api_key", function(input)
        end, function(input, canceled)
                if not canceled then
                        if isValidApiKey(input) then
                                setSetting("settings", "api_key", input)
                        else
                                micro.Log("Api Key not valid!")
                        end
                end
        end)
end

function isValidApiKey(key)
        if key == "" then
                return false
        end

        local regexp = import("regexp")
        local matched, _ = regexp.MatchString(
        "(?i)^(waka_)?[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$", key)

        return matched
end

function ternary(cond, T, F)
        if cond then return T else return F end
end

function string.starts(str, start)
        return str:sub(1, string.len(start)) == start
end

function string.ends(str, ending)
        return ending == "" or str:sub(-string.len(ending)) == ending
end

function string.trim(str)
        return (str:gsub("^%s*(.-)%s*$", "%1"))
end

function string.rtrim(str)
        local n = #str
        while n > 0 and str:find("^%s", n) do n = n - 1 end
        return str:sub(1, n)
end

function string.split(str, delimiter)
        t = {}
        for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
                table.insert(t, match);
        end
        return t
end
