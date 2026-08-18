local presetsFolder = ac.getFolder(ac.FolderID.ACApps) .. '/lua/RennsportHUD/presets/'
local appWindowPrefix = 'IMGUI_LUA_Rennsport HUD_'

local windowNames = { 'essentials', 'inputs', 'session', 'delta', 'sectors', 'fuel', 'tires', 'timing', 'leaderboard' }

--- Settings keys a preset can bundle, everything except update-checker and preset-tracking state.
local relevantSettingsKeys = {
  'applySettingsOnLoad',
  'includeSettingsOnSave',
  'changeScale',
  'scale',
  'decor',
  'ignorefocus',
  'essentialsCompactMode',
  'essentialsRpmBar',
  'essentialsRpmBarColor',
  'essentialsRpmBarShiftYellow',
  'essentialsRpmBarShiftRed',
  'essentialsGears',
  'essentialsRpmNum',
  'essentialsSpeedNum',
  'essentialsSpeedNumMPH',
  'essentialsInputBars',
  'essentialsShowTurnLights',
  'inputsShowWheel',
  'inputsShowSteering',
  'inputsShowPedals',
  'inputsShowFFB',
  'inputsShowClutch',
  'inputsShowBrake',
  'inputsShowGas',
  'inputsShowElectronics',
  'inputsPedalColors',
  'sessionShowPosition',
  'sessionHideDisconnected',
  'sessionHideAI',
  'sessionShowLaps',
  'sessionShowTimer',
  'sessionTimerType',
  'sessionAlwaysShowDuration',
  'deltaHidden',
  'deltaShowTimer',
  'deltaShowPrediction',
  'deltaShowBar',
  'deltaBarTime',
  'sectorsShowSectors',
  'sectorsDisplayDuration',
  'sectorsShowPitInfo',
  'sectorsShowSpeedLimit',
  'sectorsShowRaceFlags',
  'fuelShowRemaining',
  'fuelGallons',
  'fuelLaps',
  'fuelChangeBarColor',
  'fuelYellowBar',
  'fuelRedBar',
  'tiresShowPressure',
  'tiresPressureUseBar',
  'tiresShowTempVis',
  'tiresShowBrakeTemp',
  'tiresShowTempBar',
  'tiresTempUseFahrenheit',
  'tiresShowWear',
  'tiresPressureColor',
  'timingShowCurrentLap',
  'timingShowLapStats',
  'timingLapStatsBest',
  'timingLapStatsLast',
  'timingLapStatsIdeal',
  'timingShowTable',
  'lbShowPos',
  'lbShowNum',
  'lbShowName',
  'lbShowCar',
  'lbShowBrand',
  'lbShowLap',
  'lbShowLast',
  'lbShowBest',
  'lbShowInt',
  'lbMaxCars',
  'lbManNameLength',
  'lbManNameLengthNum',
  'lbManCarLength',
  'lbManCarLengthNum',
}

--- Fallback default preset in case default.ini gets deleted
local defaultPreset = {
  essentials = { xEdge = 'L', xPct = 0.440, yEdge = 'B', yPct = 0.200 },
  inputs = { xEdge = 'R', xPct = 0.195, yEdge = 'B', yPct = 0.05 },
  session = { xEdge = 'R', xPct = 0.0195, yEdge = 'T', yPct = 0.020 },
  delta = { xEdge = 'L', xPct = 0.450, yEdge = 'T', yPct = 0.200 },
  sectors = { xEdge = 'R', xPct = 0.400, yEdge = 'T', yPct = 0.020 },
  fuel = { xEdge = 'R', xPct = 0.110, yEdge = 'B', yPct = 0.05 },
  tires = { xEdge = 'R', xPct = 0.020, yEdge = 'B', yPct = 0.05 },
  timing = { xEdge = 'L', xPct = 0.020, yEdge = 'B', yPct = 0.120 },
  leaderboard = { xEdge = 'L', xPct = 0.0195, yEdge = 'T', yPct = 0.0200 },
}

--- Fallback default settings in case default.ini gets deleted, matches the ac.storage defaults in RennsportHUD.lua.
local defaultSettings = {
  applySettingsOnLoad = true,
  includeSettingsOnSave = true,

  changeScale = false,
  scale = 1,

  decor = true,
  ignorefocus = true,

  essentialsCompactMode = false,
  essentialsRpmBar = true,
  essentialsRpmBarColor = true,
  essentialsRpmBarShiftYellow = 95,
  essentialsRpmBarShiftRed = 98,
  essentialsGears = true,
  essentialsRpmNum = true,
  essentialsSpeedNum = true,
  essentialsSpeedNumMPH = false,
  essentialsInputBars = false,
  essentialsShowTurnLights = true,

  inputsShowWheel = true,
  inputsShowSteering = true,
  inputsShowPedals = true,
  inputsShowFFB = true,
  inputsShowClutch = true,
  inputsShowBrake = true,
  inputsShowGas = true,
  inputsShowElectronics = true,
  inputsPedalColors = false,

  sessionShowPosition = true,
  sessionHideDisconnected = false,
  sessionHideAI = true,
  sessionShowLaps = true,
  sessionShowTimer = true,
  sessionTimerType = true,
  sessionAlwaysShowDuration = false,

  deltaHidden = false,
  deltaShowTimer = true,
  deltaShowPrediction = true,
  deltaShowBar = true,
  deltaBarTime = 10,

  sectorsShowSectors = true,
  sectorsDisplayDuration = 5,
  sectorsShowPitInfo = true,
  sectorsShowSpeedLimit = true,
  sectorsShowRaceFlags = true,

  fuelShowRemaining = true,
  fuelGallons = false,
  fuelLaps = false,
  fuelChangeBarColor = true,
  fuelYellowBar = 5,
  fuelRedBar = 1,

  tiresShowPressure = true,
  tiresPressureUseBar = false,
  tiresShowTempVis = true,
  tiresShowBrakeTemp = true,
  tiresShowTempBar = true,
  tiresTempUseFahrenheit = false,
  tiresShowWear = false,
  tiresPressureColor = false,

  timingShowCurrentLap = true,
  timingShowLapStats = true,
  timingLapStatsBest = true,
  timingLapStatsLast = true,
  timingLapStatsIdeal = true,
  timingShowTable = true,

  lbShowPos = true,
  lbShowNum = true,
  lbShowName = true,
  lbShowCar = true,
  lbShowBrand = false,
  lbShowLap = true,
  lbShowLast = true,
  lbShowBest = true,
  lbShowInt = true,
  lbMaxCars = 10,
  lbManNameLength = false,
  lbManNameLengthNum = 125,
  lbManCarLength = false,
  lbManCarLengthNum = 125,
}

--- Converts a window's absolute position/size into a percentage from its nearest screen edge.
---@param pos vec2 @Window's top-left position in px.
---@param size vec2 @Window's current size in px.
---@param screenSize vec2 @Current UI size, from ac.getUI().windowSize.
---@return table @{xEdge, xPct, yEdge, yPct}.
local function toScreenEdge(pos, size, screenSize)
  local xRight = pos.x + size.x / 2 >= screenSize.x / 2
  local yBottom = pos.y + size.y / 2 >= screenSize.y / 2
  return {
    xEdge = xRight and 'R' or 'L',
    xPct = xRight and (screenSize.x - pos.x - size.x) / screenSize.x or pos.x / screenSize.x,
    yEdge = yBottom and 'B' or 'T',
    yPct = yBottom and (screenSize.y - pos.y - size.y) / screenSize.y or pos.y / screenSize.y,
  }
end

--- Converts a screen-edge percentage back into an absolute position.
---@param edge table @{xEdge, xPct, yEdge, yPct}.
---@param size vec2 @Window's current size in px.
---@param screenSize vec2 @Current UI size, from ac.getUI().windowSize.
---@return vec2 @Position to move the window to.
local function fromScreenEdge(edge, size, screenSize)
  local x = edge.xEdge == 'R' and (screenSize.x - edge.xPct * screenSize.x - size.x) or (edge.xPct * screenSize.x)
  local y = edge.yEdge == 'B' and (screenSize.y - edge.yPct * screenSize.y - size.y) or (edge.yPct * screenSize.y)
  return vec2(math.clamp(x, 0, math.max(0, screenSize.x - size.x)), math.clamp(y, 0, math.max(0, screenSize.y - size.y)))
end

--- Returns a valid accessor for a HUD window.
---@param name string @Window Name
---@return ac.AppWindowAccessor?
local function getAccessor(name)
  local accessor = ac.accessAppWindow(appWindowPrefix .. name)
  if accessor and accessor:valid() then return accessor end
  return nil
end

--- Writes settings into a preset's SETTINGS section.
---@param cfg ac.INIConfig
---@param source table @Table to read values from, keyed the same as settings.
local function writeSettingsSection(cfg, source)
  for _, key in ipairs(relevantSettingsKeys) do
    cfg:set('SETTINGS', key, source[key])
  end
end

--- Applies a preset file's SETTINGS section onto the live settings, does nothing if the file has none.
---@param path string @Full path to the preset file.
local function applySettingsSection(path)
  local cfg = ac.INIConfig.load(path, ac.INIFormat.Extended)
  for _, key in ipairs(relevantSettingsKeys) do
    settings[key] = cfg:get('SETTINGS', key, settings[key])
  end
  ---@diagnostic disable-next-line: lowercase-global
  app = getAppTable()
end

--- Moves every HUD element to match a preset.
---@param preset table @{[windowName] = screenEdge}.
local function applyPreset(preset)
  local screenSize = ac.getUI().windowSize
  for _, name in ipairs(windowNames) do
    local edge = preset[name]
    local accessor = edge and getAccessor(name)
    if accessor then accessor:move(fromScreenEdge(edge, accessor:size(), screenSize)) end
  end
end

--- Reads a preset from its .ini file.
---@param path string @Full path to the preset file.
---@return table @{[windowName] = screenEdge}.
local function readPresetFile(path)
  local cfg = ac.INIConfig.load(path, ac.INIFormat.Extended)
  local preset = {}
  for _, name in ipairs(windowNames) do
    local xEdge = cfg:get(name, 'X_EDGE', ac.INIConfig.OptionalString)
    local xPct = cfg:get(name, 'X_PCT', ac.INIConfig.OptionalNumber)
    local yEdge = cfg:get(name, 'Y_EDGE', ac.INIConfig.OptionalString)
    local yPct = cfg:get(name, 'Y_PCT', ac.INIConfig.OptionalNumber)
    if xEdge and xPct and yEdge and yPct then preset[name] = { xEdge = xEdge, xPct = xPct, yEdge = yEdge, yPct = yPct } end
  end
  return preset
end

--- Writes a preset to its .ini file, creating the presets folder if needed.
---@param path string @Full path to the preset file.
---@param preset table @{[windowName] = screenEdge}.
---@param displayName? string @Name shown in the preset list.
---@param settingsSource? table @Settings to bundle, keyed the same as settings. Omit to save positions only.
local function writePresetFile(path, preset, displayName, settingsSource)
  local cfg = ac.INIConfig(ac.INIFormat.Extended, {})
  for _, id in ipairs(windowNames) do
    local edge = preset[id]
    if edge then
      cfg:set(id, 'X_EDGE', edge.xEdge)
      cfg:set(id, 'X_PCT', edge.xPct)
      cfg:set(id, 'Y_EDGE', edge.yEdge)
      cfg:set(id, 'Y_PCT', edge.yPct)
    end
  end
  if displayName then cfg:set('PRESET', 'NAME', displayName) end
  if settingsSource then writeSettingsSection(cfg, settingsSource) end
  io.createFileDir(path)
  cfg:save(path)
end

local defaultPresetPath = presetsFolder .. 'default.ini'
if not io.fileExists(defaultPresetPath) then writePresetFile(defaultPresetPath, defaultPreset, 'Default', defaultSettings) end

local customPresetsCache

--- Scans the presets folder for custom presets.
---@return table[] @{key, name} per preset, oldest-saved first.
---@diagnostic disable-next-line: lowercase-global
function listCustomPresets()
  if customPresetsCache then return customPresetsCache end

  local list = {}
  for _, file in ipairs(io.scanDir(presetsFolder, '*.ini') or {}) do
    if file ~= 'default.ini' then
      local path = presetsFolder .. file
      local key = file:gsub('%.ini$', '')
      local cfg = ac.INIConfig.load(path, ac.INIFormat.Extended)
      table.insert(list, { key = key, name = cfg:get('PRESET', 'NAME', key), time = io.creationTime(path) })
    end
  end
  table.sort(list, function(a, b) return a.time < b.time end)

  customPresetsCache = list
  return list
end

--- Clears the custom preset list cache so the next listCustomPresets() call rescans the folder.
---@diagnostic disable-next-line: lowercase-global
function rescanPresets() customPresetsCache = nil end

--- Strips characters that aren't safe in a Windows/Linux filename.
---@param raw string @Preset name as typed by the user.
---@return string @Sanitized name.
local function sanitizeName(raw) return ((raw or ''):gsub('[<>:"/\\|?*%c]', ''):gsub('^%s+', ''):gsub('%s+$', '')) end

--- Saves the current HUD window positions as a preset, overwriting if the name already exists.
---@param rawName string @Preset name as typed by the user.
---@param includeSettings? boolean @Also bundle the current relevant settings into the preset.
---@return boolean @False if the name was empty or reserved after sanitizing.
---@diagnostic disable-next-line: lowercase-global
function savePreset(rawName, includeSettings)
  local name = sanitizeName(rawName)
  if name == '' then return false end

  local key = name:lower():gsub('%s+', '_')
  if key == 'default' then return false end

  local preset = {}
  local screenSize = ac.getUI().windowSize
  for _, id in ipairs(windowNames) do
    local accessor = getAccessor(id)
    if accessor then preset[id] = toScreenEdge(accessor:position(), accessor:size(), screenSize) end
  end

  writePresetFile(presetsFolder .. key .. '.ini', preset, name, includeSettings and settings or nil)
  customPresetsCache = nil
  settings.lastUsedPreset = key
  settings.lastUsedRes = screenSize
  return true
end

--- Deletes a custom preset by its file key, clears lastUsedPreset if it was the active one.
---@param key string @Preset file key.
---@return boolean @False if key is 'default' or deletion failed.
---@diagnostic disable-next-line: lowercase-global
function deletePreset(key)
  if key == 'default' then return false end
  local ok = io.deleteFile(presetsFolder .. key .. '.ini')
  customPresetsCache = nil
  if ok and settings.lastUsedPreset == key then settings.lastUsedPreset = '' end
  return ok
end

--- Loads a preset by file key and moves the HUD windows to match.
---@param key string @Preset file key, 'default' included.
---@param applySettings? boolean @Also apply the preset's bundled settings, if it has any.
---@return boolean @False if the preset file doesn't exist.
---@diagnostic disable-next-line: lowercase-global
function loadPreset(key, applySettings)
  local path = presetsFolder .. key .. '.ini'
  if not io.fileExists(path) then return false end

  if applySettings then
    applySettingsSection(path)
    setTimeout(function() applyPreset(readPresetFile(path)) end, 0.1, 'ApplyPresetPosition')
  else
    applyPreset(readPresetFile(path))
  end

  settings.lastUsedPreset = key
  settings.lastUsedRes = ac.getUI().windowSize
  return true
end
