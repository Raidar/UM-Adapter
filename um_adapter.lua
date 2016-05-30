--[[ UM Adapter ]]--

----------------------------------------
--[[ description:
  -- _usermenu Adapter for packs to LuaFAR for Editor.
  -- Адаптер _usermenu для пакетов к LuaFAR for Editor.
--]]
----------------------------------------
--[[ uses:
  far2.
  -- group: Macros/Plugins.
--]]
----------------------------------------
--[[ based on:
  luafar4editor plugin
  (LuaFAR for Editor.)
  (c) 2007+, Shmuel Zeigerman.
--]]
--------------------------------------------------------------------------------

----------------------------------------
local package = package

local far2Utils
--local far2History

----------------------------------------
local far = far
local F = far.Flags

--local export

----------------------------------------
--[[
local debugs = require "context.utils.useDebugs"
local logShow = debugs.Show
--]]

--------------------------------------------------------------------------------
local unit = {}

unit.Guid = win.Uuid("ffbbf294-a780-4452-8ef0-82df38507b42")

unit.global = {} -- Глобальные переменные пакетов

---------------------------------------- Pathes
do
  local slen = string.len

function unit.ExtendPackagePath (Path)

  local Path, PackPath = Path, package.path
  if not (slen(Path) > 0) then return end

  if Path:sub(-1, 1) ~= ";" then Path = Path..";" end
  --far.Show(Path:gsub(";", "\n"))
  if PackPath:find(Path, 1, true) then return end

  package.path = Path..PackPath

  --far.Show(package.path:gsub(";", "\n"))

end ---- ExtendPackagePath

end
---------------------------------------- LuaFAR Plugin API
-- based on lf4ed.lua

function unit:ReloadUserFile ()
  if not self.FirstRun then
    self:RunExitScriptHandlers()
    --self:ResetPackageLoaded()
  end
  --package.path = self.PackagePath -- restore to original value

  self.UserItems, self.CommandTable, self.HotKeyTable, self.Handlers =
    far2Utils.LoadUserMenu(self.Plugin, "_usermenu.lua")
end ---- ReloadUserFile

function unit:RunExitScriptHandlers ()
  for _, f in ipairs(self.Handlers.ExitScript) do f() end
end

---------------------------------------- ---- Menu
do
  local traceback = debug.traceback

local function traceback3 (msg)
  return traceback(msg, 3)
end

function unit:RunMenuItem (aItem, aArg)
  local argCopy = {} -- prevent parasite connection between utilities
  for k,v in pairs(aArg) do argCopy[k]=v end
  --local restoreConfig = aRestoreConfig and lf4ed.config()
  local function wrapfunc()
    if aItem.action then return aItem.action(argCopy) end
    return far2Utils.RunUserItem(aItem, argCopy)
  end
  local ok, result = xpcall(wrapfunc, traceback3)
  local result2 = false --CurrentConfig.ReturnToMainMenu
  --if restoreConfig then lf4ed.config(restoreConfig) end
  if not ok then export.OnError(result) end
  return ok, result, result2
end ---- RunMenuItem

end

local farMenuFlags = { FMENU_WRAPMODE = 1, FMENU_AUTOHIGHLIGHT = 1, }

function unit:MakeMainMenu (aFrom)
  local properties = {
    Flags = farMenuFlags,
    Title = "UM Adapter", --M.MPluginName,
    --HelpTopic = "Contents",
    Bottom = "alt+sh+f9",
  }
  --------
  local items = {}
  --if aFrom == "editor" then far2Utils.AddMenuItems(items, EditorMenuItems, M) end
  --far.Show("aFrom", aFrom)
  local mItems = self.UserItems[aFrom]
  if mItems then
    far2Utils.AddMenuItems(items, self.UserItems[aFrom])
    --far2Utils.AddMenuItems(items, self.UserItems[aFrom], M)
  end
  --------
  --local keys = {}

  local function mConfigure ()
    return unit:Configure({ From = aFrom })
  end --

  local keys = {
    { BreakKey = "AS+F9", action = mConfigure, },
  } ---
  return properties, items, keys
end ---- MakeMainMenu

---------------------------------------- ---- Run
do
  local dNumFromToArea = {
    [F.OPEN_PLUGINSMENU]  = "panels",
    [F.OPEN_EDITOR]       = "editor",
    [F.OPEN_VIEWER]       = "viewer",
    [F.OPEN_DIALOG]       = "dialog",
  } --- dNumFromToArea

  local dStrFromToArea = {
    Shell   = "panels",
    Editor  = "editor",
    Viewer  = "viewer",
    Dialog  = "dialog",
  } --- dStrFromToArea

-- = ProcessOpen
function unit:Run (aFrom, aItem)

  if aFrom == nil then
    if aItem == nil then
      return self:Configure({ From = "config" })
    end

    return
  end

  local sFrom = aFrom
  --[[
  if     sFrom == "frommacro" then
    return far2Utils.OpenMacro(aItem, self.CommandTable)
    --return far2Utils.OpenMacro(aItem, self.CommandTable, lf4ed.config)
  elseif sFrom == "commandline" then
    return far2Utils.OpenCommandLine(aItem, self.CommandTable)
    --return far2Utils.OpenCommandLine(aItem, self.CommandTable, lf4ed.config)
  end
  --]]

  if type(sFrom) == 'number' then
    sFrom = dNumFromToArea[aFrom]
  else
    sFrom = dStrFromToArea[aFrom]
  end

  if sFrom == nil then return end
  local mItem = aItem or {}

  --local history = _History:field("menu." .. sFrom)
  local properties, items, keys = self:MakeMainMenu(sFrom)
  --properties.SelectIndex = history.position
  while true do
    local item, pos = far.Menu(properties, items, keys)
    if not item then break end
    --far.Show(item, pos)
    --history.position = pos
    local arg = { From = sFrom }
    if sFrom == "dialog" then arg.hDlg = mItem.hDlg end
    --local ok, result, bRetToMainMenu = self:RunMenuItem(item, arg)
    local ok, result, bRetToMainMenu =
      self:RunMenuItem(item, arg, item.action ~= unit.Configure)
    if not ok then break end
    --_History:save()
    --if not bRetToMainMenu then break end
    if not (bRetToMainMenu or item.action == unit.Configure) then break end
    --if result=="reloaded" then
    if item.action == unit.Configure and result == "reloaded" then
      properties, items, keys = self:MakeMainMenu(sFrom)
    else
      properties.SelectIndex = pos
    end
  end

  return true
end ---- Run

end

function unit:Configure (aArg)
  local properties = {
    Flags = farMenuFlags,
    Title = "UM Adapter Configure", --M.MPluginName,
    --Title = M.MPluginNameCfg,
    --HelpTopic = "Contents",
    }
  local items = {
    --{ text = M.MPluginSettings, action = unit.PluginConfig },
    --{ text = M.MReloadUserFile, action = unit.ReloadUserFile },
  }

  for _,v in ipairs(self.UserItems.config) do items[#items+1]=v end
  if not (#items > 0) then return end

  while true do
    local item, pos = far.Menu(properties, items)
    if not item then return end
    local ok, result = self:RunMenuItem(item, aArg, false)
    if not ok then return end
    --if result then _History:save() end
    if item.action == unit.ReloadUserFile then return "reloaded" end
    properties.SelectIndex = pos
  end
end ---- Configure

---------------------------------------- ---- Events

function unit:ExitScripts ()
  self:RunExitScriptHandlers()
end

function unit:ProcessEditorEvent (EditorId, Event, Param)
  for _,f in ipairs(self.Handlers.EditorEvent) do
    f(EditorId, Event, Param)
  end
end ---- ProcessEditorEvent

function unit:ProcessViewerEvent (ViewerId, Event, Param)
  for _,f in ipairs(self.Handlers.ViewerEvent) do
    f(ViewerId, Event, Param)
  end
end ---- ProcessViewerEvent

do
  local VK = win.GetVirtualKeys()
  local band, bor, bxor, bnot = bit64.band, bit64.bor, bit64.bxor, bit64.bnot

--function unit.KeyComb (Rec)
local function KeyComb (Rec)
  local f = 0
  local state = Rec.ControlKeyState
  local ALT   = bor(F.LEFT_ALT_PRESSED,  F.RIGHT_ALT_PRESSED)
  local CTRL  = bor(F.LEFT_CTRL_PRESSED, F.RIGHT_CTRL_PRESSED)
  local SHIFT = F.SHIFT_PRESSED

  if 0 ~= band(state, ALT)   then f = bor(f, 0x01) end
  if 0 ~= band(state, CTRL)  then f = bor(f, 0x02) end
  if 0 ~= band(state, SHIFT) then f = bor(f, 0x04) end
  f = f .. "+" .. VK[Rec.VirtualKeyCode%256]

  return f
end ---- KeyComb

--end
--do
--  local KeyComb = unit.KeyComb

function unit:ProcessEditorInput (Rec)
  local EventType = Rec.EventType
  if EventType == F.KEY_EVENT then
    local item = self.HotKeyTable[KeyComb(Rec)]
    if item then
      if Rec.KeyDown then
        if type(item)=="number" then item = EditorMenuItems[item] end
        --if item then self:RunMenuItem(item, {From="editor"}) end
        if item then
          self:RunMenuItem(item, {From="editor"}, item.action ~= unit.Configure)
        end
      end
      return true
    end
  end
  for _,f in ipairs(self.Handlers.EditorInput) do
    if f(Rec) then return true end
  end
end ---- ProcessEditorInput

end

---------------------------------------- Register

function unit:RegisterMenuItem (text, description)
  self.Env.MenuItem {
    text        = text or "UM Adapter",
    description = description or "_usermenu Adapter",
    guid        = win.Uuid(unit.Guid),
    menu        = "Plugins Config",
    area        = "Shell Editor Viewer Dialog",
    action      = function (aFrom, aItem)
      return self:Run(aFrom, aItem)
    end,
  } ---
end ---- RegisterMenuItem

function unit:RegisterEvents (Priority)

  local Event = self.Env.Event
  local Priority = Priority --or 1--0--0

  Event {
    group       = "EditorInput",
    description = "um_adapter ProcessEditorInput",
    priority    = Priority,
    action      = function (rec)
      return self:ProcessEditorInput(rec)
    end,
  } ---

  Event {
    group       = "EditorEvent",
    description = "um_adapter ProcessEditorEvent",
    priority    = Priority,
    action      = function (id, event, param)
      return self:ProcessEditorEvent(id, event, param)
    end,
  } ---

  Event {
    group       = "ViewerEvent",
    description = "um_adapter ProcessViewerEvent",
    priority    = Priority,
    action      = function (id, event, param)
      return self:ProcessViewerEvent(id, event, param)
    end,
  } ---

  Event {
    group       = "ExitFAR",
    description = "um_adapter ExitScripts",
    priority    = Priority,
    action      = function ()
      return self:ExitScripts()
    end,
  } ---

end ---- RegisterEvents

function unit:RegisterCmdLine ()

  local CmdLine = self.Env.CommandLine
  local SplitCmdLine = far2Utils.SplitCommandLine
  local RunUserItem  = far2Utils.RunUserItem
  local FromPanels = { From = "panels" }

  for k, v in pairs(self.CommandTable) do
    CmdLine {
      prefixes = k,
      action = function (prefix, text)
        args = SplitCmdLine(text)
        RunUserItem(v, FromPanels, unpack(args))
      end,
    } ---
  end

end ---- RegisterCmdLine

function unit:RegisterUserMenu (Priority)

  self:RegisterMenuItem()
  self:RegisterEvents()
  self:RegisterCmdLine()

end ---- RegisterUserMenu

---------------------------------------- LuaFAR context
--[[
function unit:InitContext ()

  --far.Show"initiating .."
  require "context.initiate"
  --far.Show"initiating OK"

  resident = require "context.resident"
  --if resident then far.Show"resident OK" end
  local MakeLFcResident = require "context.luamacro"
  --if MakeLFcResident then far.Show"MakeResident OK" end
  MakeLFcResident(resident, self.Env.Event)

  self.global.context = context
  self.global.ctxdata = ctxdata

end ---- InitContext
--]]
---------------------------------------- main
do
  local GetSysEnv = win.GetEnv

local function ExpandEnv (s)
  return (s or ""):gsub("%%(.-)%%", GetSysEnv)
end

function unit.Execute (Env) --> (table)

  unit.Env = Env

  --export = unit.Env.export
  --far.Show(export)

  unit.FirstRun = true

  far2Utils   = require "far2.utils"
  --far2History = require "far2.history"

  local ProfilePath = GetSysEnv("FARPROFILE")
  if not ProfilePath then
    ProfilePath = GetSysEnv("FARHOME").."\\Profile"
  end
  unit.ProfilePath = ProfilePath

  local Plugin = far2Utils.InitPlugin()
  Plugin.ModuleDir = ProfilePath.."\\Macros\\modules\\"
  unit.Plugin = Plugin
  --Plugin.OriginalRequire = require
  --Plugin.History = far2History.newsettings(nil, "alldata")

  do -- Путь к LuaFAR пакетам
    Path = Plugin.ModuleDir.."scripts\\?.lua;"
    unit.ScriptsPath = Path
    unit.ExtendPackagePath(Path)
  end
  --[[
  local Path = ExpandEnv(GetSysEnv("LUAFAR_PATH"))
  if Path then -- Путь к LuaFAR context
    unit.LuaFAR_Path = Path
    unit.ExtendPackagePath(Path)
  end
  --]]

  unit.PackagePath = package.path
  --far.Show(package.path:gsub(";", "\n"))

  unit:ReloadUserFile()
  unit:RegisterUserMenu()

  --unit:InitContext()

  --local logShow = context.ShowInfo
  --logShow({ unit.PackagePath:gsub(";", "\n") }, "PackagePath", "w d2")
  --logShow(unit, "lf_plugin", "w d3")

  unit.FirstRun = false

  return unit
end ---- Execute

end
--------------------------------------------------------------------------------
return { Execute = unit.Execute }
--------------------------------------------------------------------------------
