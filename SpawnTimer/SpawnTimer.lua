-- Archivo: SpawnTimer.lua
local addonName, U = ...

-- Creamos la ventana
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

-- Cabecera
local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOPLEFT", 10, -10)
header:SetText("SpawnTimer")

-- Tabla de datos
local timers = {}      -- timers[mobName] = { lastSpawn, lastDeath, respawnTime }
local fontStrings = {}

local function UpdateUI()
  local line = 1
  for mob, data in pairs(timers) do
    if not fontStrings[mob] then
      fontStrings[mob] = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    end
    local fs = fontStrings[mob]
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30 - (line-1)*18)

    local text
    if data.respawnTime then
      text = string.format("%s: reapareció en %s", mob, SecondsToTime(data.respawnTime))
    elseif data.lastDeath then
      text = string.format("%s: muerto hace %s", mob, SecondsToTime(time() - data.lastDeath))
    elseif data.lastSpawn then
      text = string.format("%s: spawn hace %s", mob, SecondsToTime(time() - data.lastSpawn))
    else
      text = mob..": rastreando..."
    end

    fs:SetText(text)
    line = line + 1
  end
end

-- Slash /stimer
SLASH_SPAWNTIMER1 = "/stimer"
SlashCmdList["SPAWNTIMER"] = function(msg)
  local cmd, arg = msg:match("^(%S*)%s*(.-)$")
  if cmd == "add" and arg ~= "" then
    timers[arg] = {}
    U:RegisterMob(arg)
    print("|cff00ff00[SpawnTimer]|r Rastreando: "..arg)
  elseif cmd == "list" then
    for m in pairs(timers) do print(m) end
  elseif cmd == "clear" and arg ~= "" then
    timers[arg] = nil
    U:UnregisterMob(arg)
    if fontStrings[arg] then fontStrings[arg]:Hide() end
    print("|cff00ff00[SpawnTimer]|r Eliminado: "..arg)
  else
    print("|cff00ff00[SpawnTimer]|r Uso: /stimer add <mob> | list | clear <mob>")
  end
  UpdateUI()
end

-- Callback de UnitScan
do
  local original = U.OnFoundTarget
  U.OnFoundTarget = function(guid, name, unit)
    if timers[name] then
      local now = time()
      local d = timers[name]
      if d.lastDeath and now > d.lastDeath then
        d.respawnTime = now - d.lastDeath
        print(string.format("|cff00ff00[SpawnTimer]|r %s reapareció en %s", name, SecondsToTime(d.respawnTime)))
      end
      d.lastSpawn = now
      UpdateUI()
    end
    if original then original(guid, name, unit) end
  end
end

-- Comprobación de muertes (si no reaparece en X s)
local check = CreateFrame("Frame")
check:SetScript("OnUpdate", function(self, elapsed)
  self.elapsed = (self.elapsed or 0) + elapsed
  if self.elapsed < 1 then return end
  self.elapsed = 0
  for name, d in pairs(timers) do
    if d.lastSpawn and not d.lastDeath and time() - d.lastSpawn > 30 then
      d.lastDeath = time()
      print(string.format("|cff00ff00[SpawnTimer]|r %s muerto aprox. a las %s", name, date("%H:%M:%S", d.lastDeath)))
      UpdateUI()
    end
  end
end)

-- Primera dibujada
UpdateUI()
