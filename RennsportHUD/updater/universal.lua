---Universal updater shared across C1XTZ apps.
local Updater = {}

--#region UPDATER VARIABLES

local scriptFolder = ac.getFolder(ac.FolderID.ScriptOrigin)
local appName = scriptFolder:match('([^\\/]+)$')
local appFolder = scriptFolder .. '\\'
local appKey = appName:lower()
local repo = 'C1XTZ/ac-' .. appKey

local manifestPath = appFolder .. 'manifest.ini'
local manifest = ac.INIConfig.load(manifestPath, ac.INIFormat.Extended)
local appVersion = manifest:get('ABOUT', 'VERSION', 0.01)

local releaseURL = 'https://api.github.com/repos/' .. repo .. '/releases/latest'
local mainFile, assetFile = appName .. '.lua', appName .. '.zip'
local checkInterval = 28800

local selfRepoBase = 'https://raw.githubusercontent.com/C1XTZ/ac-xtzupdater/main/'
local selfVersionsURL = selfRepoBase .. 'versions.json'

local modernButtonOffset = -8 * ac.getUI().uiScale

local onUpdateAvailable, onCheckComplete

local timeUnits = { 'seconds', 'minutes', 'hours', 'days' }
local timeUnitSeconds = { 1, 60, 3600, 86400 }
local versionText = appName:gsub('^%l', string.upper) .. ' Version ' .. string.format('%.2f', appVersion)

local statusText = {
  [0] = "C1XTZ: You shouldn't be reading this",
  [1] = 'Updated: The app was successfully updated',
  [2] = 'No Change: The latest version is already installed',
  [3] = 'No Change: A newer version is already installed',
  [4] = 'Error: Something went wrong, aborted update',
  [5] = 'Update Available to Download and Install',
}

local statusColor = {
  [0] = rgbm.colors.white,
  [1] = rgbm.colors.lime,
  [2] = rgbm.colors.white,
  [3] = rgbm.colors.white,
  [4] = rgbm.colors.red,
  [5] = rgbm.colors.lime,
}

--#endregion

--#region UPDATER PERSISTENT SETTINGS

Updater.state = ac.storage {
  updateLastCheck = 0,
  updateStatus = 0,
  updateAvailable = false,
  updateURL = '',
}

--#endregion

--#region UTILITY FUNCTIONS

---@param config {onUpdateAvailable: fun()?, onCheckComplete: fun()?}?
---Optionally register callbacks.
---`onUpdateAvailable` fires the moment a newer release is found.
---`onCheckComplete` fires after a check resolves to "already up to date" (status ~= 5).
function Updater.init(config)
  config = config or {}
  onUpdateAvailable = config.onUpdateAvailable
  onCheckComplete = config.onCheckComplete
end

---@param latestRelease table @Parsed GitHub releases/latest JSON.
---@return string, table, fun(asset: table): string
---Handles the differently-shaped JSON CSP returned when using CSP 0.2.0 or older.
local function handle2651(latestRelease)
  if ac.getPatchVersionCode() <= 2651 then
    return latestRelease.author.tag_name, latestRelease.author.assets, function(asset) return asset.uploader.browser_download_url end
  else
    return latestRelease.tag_name, latestRelease.assets, function(asset) return asset.browser_download_url end
  end
end

---@param directory string @The directory to scan.
---@return table @A list of files in the given directory.
---@return table @A list of directories in the given directory.
---Scans the given directory recursively and returns a list of files and directories.
local function scanDirRecursive(directory)
  local function scan(dir, fileList, dirList)
    for _, file in ipairs(io.scanDir(dir)) do
      local fullPath = dir .. '\\' .. file
      if io.dirExists(fullPath) then
        table.insert(dirList, fullPath)
        scan(fullPath, fileList, dirList)
      else
        table.insert(fileList, fullPath)
      end
    end
  end

  local fileList, dirList = {}, {}
  scan(directory, fileList, dirList)
  return fileList, dirList
end

--#endregion

--#region APP UPDATING

---Downloads and installs the update.
function Updater.applyUpdate()
  local downloadUrl = Updater.state.updateURL
  web.get(downloadUrl, function(downloadErr, downloadResponse)
    if downloadErr then
      Updater.state.updateStatus = 4
      error(downloadErr)
      return
    end

    local zipData = downloadResponse.body

    ac.pauseFilesWatching(true)

    local updatedFiles, updatedDirs = {}, {}
    for _, file in ipairs(io.scanZip(zipData)) do
      local content = io.loadFromZip(zipData, file)
      if content then
        local filePath = file:gsub('^' .. appName .. '/', '')
        local dirPath = filePath:match('(.+)/')
        if dirPath then
          updatedDirs[dirPath] = true
          local parts = {}
          for part in dirPath:gmatch('[^/]+') do
            table.insert(parts, part)
            updatedDirs[table.concat(parts, '/')] = true
          end
        end

        if filePath ~= mainFile then
          local fullPath = appFolder .. filePath
          io.createFileDir(fullPath)
          if io.save(fullPath, content) then
            ac.log('Updating: ' .. file)
            updatedFiles[filePath] = true
          end
        end
      end
    end

    local mainFileContent
    for _, file in ipairs(io.scanZip(zipData)) do
      local content = io.loadFromZip(zipData, file)
      if content then
        local filePath = file:gsub('^' .. appName .. '/', '')
        if filePath == mainFile then
          mainFileContent = content
          break
        end
      end
    end

    local currentFiles, currentDirs = scanDirRecursive(appFolder)
    for _, file in ipairs(currentFiles) do
      local relativePath = file:sub(#appFolder + 1):gsub('\\', '/')
      if relativePath:sub(1, 1) == '/' then relativePath = relativePath:sub(2) end
      if not updatedFiles[relativePath] and not file:match('%.carkey$') and relativePath ~= mainFile then
        io.deleteFile(file)
        ac.log('Removing file: ' .. relativePath)
      end
    end

    for i = #currentDirs, 1, -1 do
      local dir = currentDirs[i]
      local relativePath = dir:sub(#appFolder + 1):gsub('\\', '/')
      if relativePath:sub(1, 1) == '/' then relativePath = relativePath:sub(2) end
      if not updatedDirs[relativePath] then
        io.deleteDir(dir)
        ac.log('Removing directory: ' .. relativePath)
      end
    end

    ac.pauseFilesWatching(false)

    if mainFileContent and io.save(appFolder .. mainFile, mainFileContent) then ac.log('Updating: ' .. mainFile) end

    Updater.state.updateStatus = 1
    Updater.state.updateAvailable = false
    Updater.state.updateURL = ''
  end)
end

--#endregion

--#region APP MANIFEST EDITING

---@return string? @Full `manifest.ini` contents
---Reads manifest.ini as plain text
local function readManifestText()
  local file = io.open(manifestPath, 'r')
  if not file then return nil end
  local text = file:read('*a')
  file:close()
  return text
end

---@param text string @`manifest.ini` contents to be written.
---@return boolean @False if the file couldn't be opened for writing.
---Writes plain text back to manifest.ini, overwriting it.
local function writeManifestText(text)
  local file = io.open(manifestPath, 'w+')
  if not file then return false end
  file:write(text)
  file:close()
  return true
end

---@param text string @Full `manifest.ini` contents.
---@param sectionName string @Name of the section to be replaced.
---@param values table @Key/value pairs for this section.
---@return string @The full text with just this one section replaced (or appended if it didn't exist).
---Replaces a section inside the full `manifest.ini` contents.
local function replaceSection(text, sectionName, values)
  local newline = text:find('\r\n', 1, true) and '\r\n' or '\n'
  local lines = { '[' .. sectionName .. ']' }
  for key, value in pairs(values) do
    table.insert(lines, key .. ' = ' .. tostring(value))
  end

  local newBlock = table.concat(lines, newline) .. newline
  local headerStart, headerEnd = text:find('%[' .. sectionName .. '%]')
  if not headerStart then
    local sep = (text:sub(-#newline) == newline) and '' or newline
    return text .. sep .. newline .. newBlock
  end

  local nextSectionStart = text:find(newline .. '%[', headerEnd)
  local sectionEnd = nextSectionStart or (#text + 1)
  return text:sub(1, headerStart - 1) .. newBlock .. text:sub(sectionEnd)
end

--#endregion

--#region SELF UPDATING & APP VERSION CHECKING

---Updater for the Updater, allows updates to be pushed to the updater itself without requiring a new version release for every app seperately.
local function checkSelfUpdate()
  web.get(selfVersionsURL, function(err, response)
    if err or response.status ~= 200 then
      error('Failed to check updater version.')
      return
    end

    local remote = JSON.parse(response.body)
    if not remote or not remote.versions or not remote[appKey] then
      error('Broken updater version data.')
      return
    end

    local wantedFiles = remote[appKey].files or {}
    local installed = manifest.sections['XTZ_UPDATER'] or {}
    local finalValues = {}
    for key in pairs(installed) do
      finalValues[key] = manifest:get('XTZ_UPDATER', key, 0.0)
    end

    local toDownload = {}
    for _, filename in ipairs(wantedFiles) do
      local manifestKey = filename:upper() .. '_VERSION'
      local remoteVersion = remote.versions[filename]
      if remoteVersion then
        local alreadyTracked = installed[manifestKey] ~= nil
        local localVersion = alreadyTracked and manifest:get('XTZ_UPDATER', manifestKey, 0.0) or -1
        if not alreadyTracked or remoteVersion > localVersion then table.insert(toDownload, { filename = filename, manifestKey = manifestKey, version = remoteVersion }) end
      end
    end

    local wantedSet = {}
    for _, filename in ipairs(wantedFiles) do
      wantedSet[filename:upper() .. '_VERSION'] = true
    end

    local toRemove = {}
    for manifestKey in pairs(installed) do
      if not wantedSet[manifestKey] then
        local filename = manifestKey:match('^(.+)_VERSION$')
        if filename then table.insert(toRemove, { filename = filename:lower(), manifestKey = manifestKey }) end
      end
    end

    if #toDownload == 0 and #toRemove == 0 then
      ac.log('Already using latest updater version.')
      return
    end

    ac.pauseFilesWatching(true)

    local dirty = false
    for _, entry in ipairs(toRemove) do
      io.deleteFile(appFolder .. 'updater\\' .. entry.filename .. '.lua')
      ac.log('Removed updater file: ' .. entry.filename)
      finalValues[entry.manifestKey] = nil
      dirty = true
    end

    local pending = #toDownload

    local function finishIfDone()
      if pending > 0 then return end

      ac.pauseFilesWatching(false)

      if dirty then
        local text = readManifestText()
        if text then writeManifestText(replaceSection(text, 'XTZ_UPDATER', finalValues)) end
      end
    end

    if pending == 0 then
      finishIfDone()
      return
    end

    for _, entry in ipairs(toDownload) do
      web.get(selfRepoBase .. entry.filename .. '.lua', function(fileErr, fileResponse)
        if fileErr or fileResponse.status ~= 200 then
          error('Failed to download updater file: ' .. entry.filename)
        else
          io.save(appFolder .. 'updater\\' .. entry.filename .. '.lua', fileResponse.body)
          ac.log('Updated updater file: ' .. entry.filename)
          finalValues[entry.manifestKey] = entry.version
          dirty = true
        end

        pending = pending - 1
        finishIfDone()
      end)
    end
  end)
end

---@param manual? boolean @Bypasses the 8h check interval.
---Checks GitHub for a newer release and updates state accordingly.
function Updater.checkVersion(manual)
  local now = os.time()
  if not manual and now - Updater.state.updateLastCheck <= checkInterval then return end
  Updater.state.updateLastCheck = now

  web.get(releaseURL, function(err, response)
    if err then
      Updater.state.updateStatus = 4
      error(err)
      return
    end

    local latestRelease = JSON.parse(response.body)
    local tagName, releaseAssets, getDownloadUrl = handle2651(latestRelease)

    if not (tagName and tagName:match('^v%d%d?%.%d%d?$')) then
      Updater.state.updateStatus = 4
      error('URL unavailable or no Version recognized, aborted update')
      return
    end

    local version = tonumber(tagName:sub(2))

    if appVersion > version then
      Updater.state.updateStatus = 3
      Updater.state.updateAvailable = false
    elseif appVersion == version then
      Updater.state.updateStatus = 2
      Updater.state.updateAvailable = false
    else
      local downloadUrl
      for _, asset in ipairs(releaseAssets) do
        if asset.name == assetFile then
          downloadUrl = getDownloadUrl(asset)
          break
        end
      end

      if not downloadUrl then
        Updater.state.updateStatus = 4
        error('No matching asset found, aborted update')
        return
      end

      Updater.state.updateAvailable = true
      Updater.state.updateURL = downloadUrl
      Updater.state.updateStatus = 5
      if onUpdateAvailable then onUpdateAvailable() end
    end

    if Updater.state.updateStatus ~= 5 then
      checkSelfUpdate()
      if onCheckComplete then onCheckComplete() end
    end
  end)
end

--#endregion

--#region SETTINGS UI

---Draws the full 'Update' tab body.
function Updater.drawUI()
  if ac.getPatchVersionCode() < 2651 then return end

  ui.text(versionText)

  local buttonText = Updater.state.updateAvailable and 'Install Update' or 'Check for Update'
  if ui.modernButton(buttonText, 0, ui.ButtonFlags.None, nil, modernButtonOffset, nil) then
    if Updater.state.updateAvailable then
      Updater.applyUpdate()
    else
      Updater.checkVersion(true)
    end
  end

  local diff = os.time() - Updater.state.updateLastCheck
  if diff > 600 then Updater.state.updateStatus = 0 end

  local i = #timeUnitSeconds
  while i > 1 and diff < timeUnitSeconds[i] do
    i = i - 1
  end

  local timeAgo = math.floor(diff / timeUnitSeconds[i])
  ui.text('Last checked ' .. timeAgo .. ' ' .. timeUnits[i] .. ' ago')

  if Updater.state.updateStatus > 0 then ui.textColored(statusText[Updater.state.updateStatus], statusColor[Updater.state.updateStatus]) end
end

--#endregion

return Updater
