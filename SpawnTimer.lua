-- Archivo: SpawnTimer.lua
local addonName, U = ...

-- Creamos la ventana arrastrable
local frame = CreateFrame("Frame", addonName.."Frame", UIParent)
frame:SetSize(260, 150)
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -50)
frame:SetMovable(true); frame:EnableMouse(true)
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

-- Datos
local timers, fontStrings = {}, {}

local function UpdateUI()
  local y = -30
  for mob, d in pairs(timers) do
    if not fontStrings[mob] then
      fontStrings[mob] = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    end
    local fs = fontStrings[mob]
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, y)
    local txt
    if d.respawnTime then
      txt = mob..": respawn "..SecondsToTime(d.respawnTime)
    elseif d.lastDeath then
      txt = mob..": muerto hace "..SecondsToTime(time() - d.lastDeath)
    elseif d.lastSpawn then
      txt = mob..": spawn hace "..SecondsToTime(time() - d.lastSpawn)
    else
      txt = mob..": rastreando..."
    end
    fs:SetText(txt)
    y = y - 18
  end
end

-- Comando /stimer
SLASH_SPAWNTIMER1 = "/stimer"
SlashCmdList["SPAWNTIMER"] = function(msg)
  local cmd, arg = msg:match("^(%S*)%s*(.-)$")
  if cmd=="add" and arg~="" then
    timers[arg] = {}
    U:RegisterMob(arg)
    print("|cff00ff00[SpawnTimer]|r Rastreando: "..arg)
  elseif cmd=="clear" and arg~="" then
    timers[arg] = nil
    U:UnregisterMob(arg)
    if fontStrings[arg] then fontStrings[arg]:Hide() end
    print("|cff00ff00[SpawnTimer]|r Eliminado: "..arg)
  elseif cmd=="list" then
    for m in pairs(timers) do print(m) end
  else
    print("|cff00ff00[SpawnTimer]|r Uso: /stimer add <mob> | clear <mob> | list")
  end
  UpdateUI()
end

-- Hook a UnitScan
do
  local orig = U.OnFoundTarget
  U.OnFoundTarget = function(guid,name,unit)
    if timers[name] then
      local now = time()
      local d = timers[name]
      if d.lastDeath and now>d.lastDeath then
        d.respawnTime = now - d.lastDeath
        print("|cff00ff00[SpawnTimer]|r "..name.." reapareció en "..SecondsToTime(d.respawnTime))
      end
      d.lastSpawn = now
      UpdateUI()
    end
    if orig then orig(guid,name,unit) end
  end
end

-- Detectar muertes (>30s sin ver spawn)
local chk = CreateFrame("Frame")
chk.elapsed = 0
chk:SetScript("OnUpdate", function(self,el)
  self.elapsed = self.elapsed + el
  if self.elapsed<1 then return end
  self.elapsed = 0
  for name,d in pairs(timers) do
    if d.lastSpawn and not d.lastDeath and time()-d.lastSpawn>30 then
      d.lastDeath = time()
      print("|cff00ff00[SpawnTimer]|r "..name.." muerto aprox. "..date("%H:%M:%S",d.lastDeath))
      UpdateUI()
    end
  end
end)

-- Primer dibujado
UpdateUI()
