-- Archivo: SpawnTimer.lua
local addonName, U = ...
local frame = CreateFrame("Frame", addonName.."Frame", UIParent)
frame:SetSize(260, 150)
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -50)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

frame.bg = frame:CreateTexture(nil, "BACKGROUND")
frame.bg:SetAllPoints(true)
frame.bg:SetColorTexture(0,0,0,0.6)

-- Header
local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOPLEFT", 10, -10)
header:SetText("SpawnTimer")

-- Data tables
local timers = {}  -- [mobName] = { lastSpawn, lastDeath, respawnTime }
local fontStrings = {}

local function SecondsToTimeText(sec)
  return SecondsToTime(sec)
end

local function UpdateUI()
  local line = 1
  for mob, data in pairs(timers) do
    if not fontStrings[mob] then
      local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fontStrings[mob] = fs
    end
    local fs = fontStrings[mob]
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30 - (line-1)*18)
    local text
    if data.respawnTime then
      text = string.format("%s: respawn %s", mob, SecondsToTimeText(data.respawnTime))
    elseif data.lastDeath then
      text = string.format("%s: muerto hace %s", mob, SecondsToTimeText(time() - data.lastDeath))
    elseif data.lastSpawn then
      text = string.format("%s: spawn hace %s", mob, SecondsToTimeText(time() - data.lastSpawn))
    else
      text = mob..": rastreando..."
    end
    fs:SetText(text)
    line = line + 1
  end
end

-- Slash commands
SLASH_SPAWNTIMER1 = "/stimer"
SlashCmdList["SPAWNTIMER"] = function(msg)
  local cmd, arg = msg:match("^(%S*)%s*(.-)$")
  if cmd == "add" and arg ~= "" then
    timers[arg] = { lastSpawn=nil, lastDeath=nil, respawnTime=nil }
    U:RegisterMob(arg)
    print("|cff00ff00[SpawnTimer]|r Rastreando mob: "..arg)
  elseif cmd == "list" then
    for m in pairs(timers) do print(m) end
  elseif cmd == "clear" and arg ~= "" then
    timers[arg] = nil
    if fontStrings[arg] then fontStrings[arg]:Hide() end
    U:UnregisterMob(arg)
    print("|cff00ff00[SpawnTimer]|r Eliminado mob: "..arg)
  else
    print("|cff00ff00[SpawnTimer]|r Uso: /stimer add <mobName> | list | clear <mobName>")
  end
  UpdateUI()
end

-- When UnitScan finds a unit
U.OnFoundTarget = function(original, guid, name, unit)
  if timers[name] then
    local now = time()
    local data = timers[name]
    if data.lastDeath and now > data.lastDeath then
      data.respawnTime = now - data.lastDeath
      print(string.format("|cff00ff00[SpawnTimer]|r %s reapareció en %s", name, SecondsToTimeText(data.respawnTime)))
    end
    data.lastSpawn = now
    UpdateUI()
  end
  if original then original(guid, name, unit) end
end

-- Periodic check for deaths (no spawn detection for > threshold)
local checkFrame = CreateFrame("Frame")
checkFrame.elapsed = 0
checkFrame:SetScript("OnUpdate", function(self, elapsed)
  self.elapsed = self.elapsed + elapsed
  if self.elapsed < 1 then return end
  self.elapsed = 0
  for name, data in pairs(timers) do
    if data.lastSpawn and not data.lastDeath and time() - data.lastSpawn > 30 then
      data.lastDeath = time()
      print(string.format("|cff00ff00[SpawnTimer]|r %s murió aprox. a las %s", name, date("%H:%M:%S", data.lastDeath)))
      UpdateUI()
    end
  end
end)

-- Initialize UI
UpdateUI()

-- File: README.md
--[[
# SpawnTimer (basado en UnitScan-turtle)

Addon para WoW que detecta mobs con UnitScan y mide su tiempo de respawn.

## Instalación

1. Clona o descarga este repo en:
```
World of Warcraft/_retail_/Interface/AddOns/SpawnTimer
```
2. Actívalo en la pantalla de selección de personaje.

## Comandos

- `/stimer add <mobName>`: empieza a rastrear un mob.
- `/stimer list`: lista los mobs rastreados.
- `/stimer clear <mobName>`: deja de rastrear un mob.

El addon muestra ventana flotante con tiempos de spawn, muerte y respawn.
]]--
