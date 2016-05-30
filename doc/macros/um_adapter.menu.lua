--[[ Macros using UM Adapter ]]--

----------------------------------------
--[[ description:
  -- Macros using UM Adapter pack.
  -- Макросы, использующие пакет UM Adapter.
--]]
----------------------------------------
--[[ uses:
  nil.
  -- group: Macros/Plugins.
--]]
--------------------------------------------------------------------------------

----------------------------------------
local far = far
local F = far.Flags

local BlockNoneType = F.BTYPE_NONE

local editor = editor

--------------------------------------------------------------------------------

----------------------------------------
local guids = {}

local Macro = Macro or function () end

local Async = function () return mmode(3, 1) end

local Plugin = Plugin or {}
local PluginExist = Plugin.Exist
local PluginMenu, CallPlugin = Plugin.Menu, Plugin.Call

---------------------------------------- 'L' -- LuaFAR
guids.LF4Ed = "6F332978-08B8-4919-847A-EFBB6154C99A"

local function Exist ()
  return UMAdapterMenu or PluginExist(guids.LF4Ed)
end

local function IsDlgEdit ()
  return not Area.Dialog or Area.Dialog and Dlg.ItemType == F.DI_EDIT
end -- IsDlgEdit

local function ExistSpec ()
  if Area.Menu then return end

  return IsDlgEdit() and Exist()
end -- ExistSpec

local function UM_MainMenu ()
  if UMAdapterMenu then
    return UMAdapterMenu()
  else
    return PluginMenu(guids.LF4Ed)
  end
end -- UM_MainMenu

-- [[
Macro {
  area = "Shell Editor Viewer Dialog",
  key = "LCtrlL",
  flags = "",
  description = "LuaFAR: Menu",
  condition = ExistSpec,
  action = function ()
    return UM_MainMenu()
  end, ---
} ---
--]]
---------------------------------------- 'M' -- -- Lua User Menu
guids.LUM = "00B06FBA-0BB7-4333-8025-BA48B6077435"

local function ShowLUM (key, guid) --> (bool)
  if not UM_MainMenu() then return end
  Keys(key or "M")
  return (Menu.Id or Dlg.Id) == (guid or guids.LUM)
end -- ShowLUM

-- [[
Macro {
  area = "Shell Editor Viewer Dialog",
  key = "LAltShiftF2",
  flags = "",
  description = "LUM: Lua User Menu",
  condition = ExistSpec,
  action = ShowLUM,
} ---

Macro {
  area = "Shell Editor Viewer",
  key = "LCtrlLAltShiftF2",
  flags = "",
  description = "LUM: Tortoise SVN",
  condition = Exist,
  action = function ()
    return ShowLUM("S")
    --if ShowLUM("S") then return Keys"T" end
  end, ---
} ---

--[=[
Macro {
  area = "Editor",
  key = "LCtrlJ",
  flags = "",
  description = "LUM: Template Insert",
  condition = Exist,
  action = function ()
    if ShowLUM"M" then return Keys"J" end
  end, ---
} ---
--]=]
--]]
----------------------------------------     -- -- LUM Items
-- [[
Macro {
  --area = "Common",
  --area = "Shell Editor Viewer",
  area = "Shell Editor Viewer Dialog",
  key = "LCtrlK",
  flags = "",
  description = "LUM: Calendar",
  condition = ExistSpec,
  action = function ()
    if ShowLUM() then return Keys"A C" end
  end, ---
} ---
Macro {
  --area = "Common",
  area = "Shell Editor Dialog",
  --area = "Shell Editor Viewer Dialog",
  key = "LCtrlH",
  flags = "",
  description = "LUM: CharsMap",
  condition = ExistSpec,
  action = function ()
    if ShowLUM() then return Keys"A H" end
  end, ---
} ---
Macro {
  area = "Editor Dialog",
  key = "LCtrlShiftH",
  flags = "",
  description = "LUM: Characters",
  condition = ExistSpec,
  action = function ()
    if ShowLUM() then return Keys"H" end
  end, ---
} ---
--]]
--------------------------------------------------------------------------------
