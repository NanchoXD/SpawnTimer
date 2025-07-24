-- Archivo: SpawnTimer.lua
local addonName, addonTable = ...
local frame = CreateFrame("Frame", addonName.."Frame", UIParent)
frame:SetSize(200, 100)
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -50)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

frame.bg = frame:CreateTexture(nil, "BACKGROUND")
frame.bg:SetAllPoints(true)
frame.bg:SetColorTexture(0, 0, 0, 0.5)

-- Tabla de mobs a rastrear
local timers = {}

-- Fuente para mostrar texto
local fontStrings = {}
local function UpdateUI()
    local line = 1
    for mobName, data in pairs(timers) do
        if not fontStrings[mobName] then
            fontStrings[mobName] = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        end
        local fs = fontStrings[mobName]
        fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -20 * line)
        local text
        if data.respawnTime then
            text = string.format("%s: último respawn %s", mobName, SecondsToTime(data.respawnTime))
        elseif data.lastDeath then
            text = string.format("%s: desde muerte %s", mobName, SecondsToTime(time() - data.lastDeath))
        else
            text = mobName..": esperando muerte"
        end
        fs:SetText(text)
        line = line + 1
    end
end

local function printMsg(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[SpawnTimer]|r "..msg)
end

SLASH_SPAWNTIMER1 = "/stimer"
SlashCmdList["SPAWNTIMER"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    if cmd == "add" and arg ~= "" then
        timers[arg] = timers[arg] or {}
        printMsg("Rastreando: "..arg)
    elseif cmd == "list" then
        for name in pairs(timers) do printMsg(name) end
    elseif cmd == "clear" and arg ~= "" then
        timers[arg] = nil
        if fontStrings[arg] then fontStrings[arg]:Hide() end
        printMsg("Eliminado: "..arg)
    else
        printMsg("Uso: /stimer add NombreDelMob | list | clear NombreDelMob")
    end
    UpdateUI()
end

frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
        if subEvent == "UNIT_DIED" and timers[destName] then
            timers[destName].lastDeath = time()
            timers[destName].respawnTime = nil
            printMsg(destName.." ha muerto a las "..date("%H:%M:%S", timers[destName].lastDeath))
            UpdateUI()
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...

        local name = UnitName(unit)
        if timers[name] and timers[name].lastDeath then
            local now = time()
            if not timers[name].lastSpawn or now > timers[name].lastDeath then
                timers[name].lastSpawn = now
                timers[name].respawnTime = now - timers[name].lastDeath
                printMsg(name.." reapareció. Tiempo de respawn: "..SecondsToTime(timers[name].respawnTime))
                UpdateUI()
            end
        end
    end
end)

local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalMedium")
header:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
header:SetText("SpawnTimer")

UpdateUI()
