--[[
  TorilLib - Main Entry Point
  Version: 2.1.0
  
  Usage:
    dofile(getMudletHomeDir() .. "/TorilLib/init.lua")
    TorilLib:init()
]]--

TorilLib = TorilLib or {}
TorilLib.version = "2.1.0"
TorilLib.modules = {}
TorilLib.initialized = false

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function TorilLib:init()
  if self.initialized then
    cecho("<yellow>TorilLib already initialized\n")
    return true
  end
  
  cecho(string.format("<cyan>====================================\n"))
  cecho(string.format("<cyan>  TorilLib v%s\n", self.version))
  cecho(string.format("<cyan>  Initializing...\n"))
  cecho(string.format("<cyan>====================================\n"))
  
  -- Load configuration
  self:loadConfig()
  
  -- Load core modules
  self:loadCoreModules()
  
  -- Load character system
  self:loadCharacterSystem()
  
  -- Load GUI
  self:loadGUI()
  
  -- Load database
  self:loadDatabase()
  
  -- Load parsers
  self:loadParsers()
  
  -- Setup triggers
  self:setupTriggers()
  
  -- Connect components
  self:connectComponents()
  
  self.initialized = true
  
  cecho("<green>✓ TorilLib initialized successfully!\n")
  cecho("<cyan>Type 'TorilLib:show()' to display GUI\n")
  cecho("<cyan>Type 'TorilLib:help()' for commands\n")
  
  return true
end

-- =============================================================================
-- MODULE LOADING
-- =============================================================================

function TorilLib:loadConfig()
  cecho("<cyan>Loading configuration...\n")
  
  self.config = {
    -- Debug settings
    debug = false,
    logLevel = "info",
    
    -- GUI settings
    showGUIOnStartup = false,
    autoDetectCharacter = true,
    
    -- Update intervals (seconds)
    updateInterval = {
      gui = 0.1,
      stats = 1.0,
      equipment = 5.0
    },
    
    -- Paths
    dataPath = getMudletHomeDir() .. "/TorilLib/data/",
    logPath = getMudletHomeDir() .. "/TorilLib/logs/",
    
    -- Features
    features = {
      characterDetection = true,
      equipmentTracking = true,
      combatTracking = true,
      groupTracking = true,
      mapIntegration = true
    }
  }
  
  cecho("<green>✓ Configuration loaded\n")
end

function TorilLib:loadCoreModules()
  cecho("<cyan>Loading core modules...\n")
  
  -- Load StateManager
  local StateManager = dofile(getMudletHomeDir() .. "/TorilLib/src/core/StateManager.lua")
  self.StateManager = StateManager
  self.StateManager:init()
  cecho("<green>  ✓ StateManager\n")
  
  -- Load EventBus
  local EventBus = dofile(getMudletHomeDir() .. "/TorilLib/src/core/EventBus.lua")
  self.EventBus = EventBus
  self.EventBus:init()
  cecho("<green>  ✓ EventBus\n")
  
  cecho("<green>✓ Core modules loaded\n")
end

function TorilLib:loadCharacterSystem()
  cecho("<cyan>Loading character system...\n")
  
  -- These will be created in Phase 3
  self.Character = {
    profile = nil,
    equipment = nil,
    stats = nil
  }
  
  cecho("<yellow>  ⚠ Character modules pending (Phase 3)\n")
end

function TorilLib:loadGUI()
  cecho("<cyan>Loading GUI...\n")
  
  -- Load GUIFlex
  local GUIFlex = dofile(getMudletHomeDir() .. "/TorilLib/src/gui/GUIFlex.lua")
  self.GUIFlex = GUIFlex
  self.GUIFlex:init()
  cecho("<green>  ✓ GUIFlex\n")
  
  cecho("<green>✓ GUI loaded\n")
end

function TorilLib:loadDatabase()
  cecho("<cyan>Loading database...\n")
  
  self.Database = {
    Classes = {},
    Races = {},
    Skills = {},
    Spells = {},
    Powers = {}
  }
  
  cecho("<yellow>  ⚠ Database modules pending (Phase 3)\n")
end

function TorilLib:loadParsers()
  cecho("<cyan>Loading parsers...\n")
  
  self.parsers = {
    prompt = {
      parse = function(line)
        return self:parsePrompt(line)
      end
    },
    equipment = {
      parse = function(line)
        return self:parseEquipment(line)
      end
    },
    combat = {
      parse = function(line)
        return self:parseCombat(line)
      end
    },
    group = {
      parse = function(line)
        return self:parseGroup(line)
      end
    }
  }
  
  cecho("<green>✓ Parsers loaded\n")
end

function TorilLib:setupTriggers()
  cecho("<cyan>Setting up triggers...\n")
  
  -- Prompt trigger
  if tempTriggers then
    tempTriggers["TorilLib_Prompt"] = nil -- Clear old
  end
  
  tempTrigger("TorilLib_Prompt", 
    "^HP:%s*%d+/%d+%s+PSP:%s*%d+/%d+%s+MV:%s*%d+/%d+",
    [[TorilLib.parsers.prompt:parse(line)]]
  )
  
  cecho("<green>  ✓ Prompt trigger\n")
  
  -- Character detection trigger
  tempTrigger("TorilLib_CharDetect",
    "^You are %w+ the level %d+",
    [[TorilLib:detectCharacter(line)]]
  )
  
  cecho("<green>  ✓ Character detection trigger\n")
  
  cecho("<green>✓ Triggers setup complete\n")
end

function TorilLib:connectComponents()
  cecho("<cyan>Connecting components...\n")
  
  -- Connect StateManager to EventBus
  self.StateManager.events = self.EventBus
  
  -- Subscribe GUI to events
  self.EventBus:subscribe("character.hp_changed", function(data)
    self.GUIFlex:updateGauge("Health", data.current, data.max)
    local percent = math.floor((data.current / data.max) * 100)
    self.GUIFlex.gauges.Health.front:echo(
      string.format("HP: %d/%d (%d%%)", data.current, data.max, percent)
    )
  end, { name = "GUI_HP_Update" })
  
  self.EventBus:subscribe("character.psp_changed", function(data)
    self.GUIFlex:updateGauge("PSP", data.current, data.max)
    local percent = math.floor((data.current / data.max) * 100)
    self.GUIFlex.gauges.PSP.front:echo(
      string.format("PSP: %d/%d (%d%%)", data.current, data.max, percent)
    )
  end, { name = "GUI_PSP_Update" })
  
  self.EventBus:subscribe("character.mv_changed", function(data)
    self.GUIFlex:updateGauge("Endurance", data.current, data.max)
    local percent = math.floor((data.current / data.max) * 100)
    self.GUIFlex.gauges.Endurance.front:echo(
      string.format([[<span style="color: black">MV: %d/%d (%d%%)</span>]], 
        data.current, data.max, percent)
    )
  end, { name = "GUI_MV_Update" })
  
  cecho("<green>✓ Components connected\n")
end

-- =============================================================================
-- PARSER FUNCTIONS
-- =============================================================================

function TorilLib:parsePrompt(line)
  -- Parse: "HP: 1234/5678  PSP: 890/1200  MV: 567/890"
  local hp_curr, hp_max = line:match("HP:%s*(%d+)/(%d+)")
  local psp_curr, psp_max = line:match("PSP:%s*(%d+)/(%d+)")
  local mv_curr, mv_max = line:match("MV:%s*(%d+)/(%d+)")
  
  if hp_curr then
    local current = tonumber(hp_curr)
    local max = tonumber(hp_max)
    
    self.StateManager:set("character.hp.current", current)
    self.StateManager:set("character.hp.max", max)
    self.StateManager:computeHPPercent()
    
    self.EventBus:emit("character.hp_changed", {
      current = current,
      max = max,
      percent = math.floor((current / max) * 100)
    })
  end
  
  if psp_curr then
    local current = tonumber(psp_curr)
    local max = tonumber(psp_max)
    
    self.StateManager:set("character.psp.current", current)
    self.StateManager:set("character.psp.max", max)
    self.StateManager:computePSPPercent()
    
    self.EventBus:emit("character.psp_changed", {
      current = current,
      max = max,
      percent = math.floor((current / max) * 100)
    })
  end
  
  if mv_curr then
    local current = tonumber(mv_curr)
    local max = tonumber(mv_max)
    
    self.StateManager:set("character.mv.current", current)
    self.StateManager:set("character.mv.max", max)
    self.StateManager:computeMVPercent()
    
    self.EventBus:emit("character.mv_changed", {
      current = current,
      max = max,
      percent = math.floor((current / max) * 100)
    })
  end
end

function TorilLib:parseEquipment(line)
  -- Parse equipment lines
  local slot, item = line:match("<worn on ([^>]+)>%s+(.+)")
  if slot and item then
    cecho(string.format("<cyan>Equipment: %s -> %s\n", slot, item))
  end
end

function TorilLib:parseCombat(line)
  -- Parse combat messages
  local target, damage = line:match("You hit (.+) for (%d+) damage")
  if target and damage then
    cecho(string.format("<red>Hit %s for %d damage!\n", target, damage))
  end
end

function TorilLib:parseGroup(line)
  -- Parse group information
  local name, level, class, hp = line:match("(%w+)%s+%[(%d+)%s+(%w+)%]%s+%[%s*(%d+)%%%]")
  if name then
    cecho(string.format("<green>Group: %s [%d %s] %d%%\n", name, level, class, hp))
  end
end

function TorilLib:detectCharacter(line)
  -- Parse: "You are Playername the level 50 Grey Elf Warrior"
  local name, level, race, class = line:match("You are (%w+) the level (%d+) (.+) (%w+)")
  
  if name and level then
    self.StateManager:set("character.name", name)
    self.StateManager:set("character.level", tonumber(level))
    self.StateManager:set("character.race", race)
    self.StateManager:set("character.class", class)
    
    cecho(string.format("<green>✓ Character detected: %s (Level %d %s %s)\n",
      name, level, race, class))
    
    self.EventBus:emit("character.detected", {
      name = name,
      level = tonumber(level),
      race = race,
      class = class
    })
  end
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

function TorilLib:show()
  if not self.initialized then
    cecho("<red>TorilLib not initialized. Call TorilLib:init() first.\n")
    return
  end
  
  self.GUIFlex:show()
  cecho("<green>✓ GUI displayed\n")
end

function TorilLib:hide()
  self.GUIFlex:hide()
  cecho("<yellow>GUI hidden\n")
end

function TorilLib:reload()
  cecho("<cyan>Reloading TorilLib...\n")
  self.initialized = false
  self:init()
end

function TorilLib:help()
  cecho([[
<cyan>====================================
  TorilLib Commands
====================================</cyan>

<white>Setup:</white>
  <yellow>TorilLib:init()</yellow>        - Initialize system
  <yellow>TorilLib:reload()</yellow>      - Reload all modules

<white>GUI:</white>
  <yellow>TorilLib:show()</yellow>        - Show GUI
  <yellow>TorilLib:hide()</yellow>        - Hide GUI

<white>State:</white>
  <yellow>TorilLib.StateManager:get(path)</yellow>  - Get state value
  <yellow>TorilLib.StateManager:set(path, value)</yellow> - Set state value
  <yellow>TorilLib.StateManager:dump()</yellow>     - Display all state

<white>Events:</white>
  <yellow>TorilLib.EventBus:listEvents()</yellow>  - List all events
  <yellow>TorilLib.EventBus:subscribe(event, callback)</yellow> - Subscribe to event

<white>Testing:</white>
  <yellow>TorilLib:test()</yellow>        - Run test suite
  <yellow>TorilLib:testPrompt()</yellow>  - Test prompt parsing

<white>Debug:</white>
  <yellow>TorilLib:enableDebug()</yellow> - Enable debug mode
  <yellow>TorilLib:disableDebug()</yellow> - Disable debug mode

]])
end

function TorilLib:enableDebug()
  self.config.debug = true
  self.StateManager:debug(true)
  self.EventBus:debug(true)
  cecho("<green>Debug mode enabled\n")
end

function TorilLib:disableDebug()
  self.config.debug = false
  self.StateManager:debug(false)
  self.EventBus:debug(false)
  cecho("<yellow>Debug mode disabled\n")
end

-- =============================================================================
-- TESTING
-- =============================================================================

function TorilLib:test()
  cecho("<cyan>Running TorilLib tests...\n")
  
  -- Test GUI
  self:show()
  
  -- Test prompt parsing
  tempTimer(1, function()
    cecho("<yellow>Testing prompt parsing...\n")
    self:parsePrompt("HP: 1234/5678  PSP: 890/1200  MV: 567/890")
  end)
  
  -- Test character detection
  tempTimer(2, function()
    cecho("<yellow>Testing character detection...\n")
    self:detectCharacter("You are TestChar the level 50 Grey Elf Warrior")
  end)
  
  -- Display state
  tempTimer(3, function()
    cecho("<green>=== Current State ===\n")
    display(self.StateManager:get("character"))
  end)
  
  cecho("<green>✓ Tests complete\n")
end

function TorilLib:testPrompt()
  cecho("<cyan>Testing prompt parser...\n")
  self:parsePrompt("HP: 1234/5678  PSP: 890/1200  MV: 567/890")
  cecho("<green>✓ Prompt parsed\n")
end

-- =============================================================================
-- AUTO-INITIALIZE
-- =============================================================================

cecho([[
<cyan>====================================
  TorilLib Loaded
====================================</cyan>

<white>To start:</white>  <yellow>TorilLib:init()</yellow>
<white>For help:</white>  <yellow>TorilLib:help()</yellow>

]])

return TorilLib
