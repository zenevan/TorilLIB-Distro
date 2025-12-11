# TorilLib Feature Implementation Plan
## Priority-Based Improvement Roadmap

---

## 🎯 PHASE 1: Critical Fixes (Week 1)

### 1.1 Initialize Project Structure
**Priority: CRITICAL**

**Tasks:**
- Create proper directory structure
- Move existing files to correct locations
- Create init.lua main entry point
- Add config.lua for settings

**Files to Create:**
```lua
-- src/init.lua
TorilLib = TorilLib or {}
TorilLib.version = "2.1.0"
TorilLib.modules = {}

function TorilLib:init()
  -- Load configuration
  self.config = require("src.config")
  
  -- Load core modules
  self.StateManager = require("src.core.StateManager")
  self.EventBus = require("src.core.EventBus")
  self.DataParser = require("src.core.DataParser")
  
  -- Load GUI
  self.GUIFlex = require("src.gui.GUIFlex")
  
  -- Initialize modules
  self.StateManager:init()
  self.EventBus:init()
  self.GUIFlex:init()
  
  -- Load triggers
  self:loadTriggers()
  
  -- Load parsers
  self:loadParsers()
  
  cecho("<green>TorilLib v" .. self.version .. " initialized!\n")
end

function TorilLib:loadTriggers()
  require("src.triggers.PromptTriggers")
  require("src.triggers.CombatTriggers")
  require("src.triggers.EquipmentTriggers")
  require("src.triggers.GroupTriggers")
end

function TorilLib:loadParsers()
  self.parsers = {
    prompt = require("src.parsers.PromptParser"),
    equipment = require("src.parsers.EquipmentParser"),
    combat = require("src.parsers.CombatParser"),
    group = require("src.parsers.GroupParser")
  }
end

return TorilLib
```

### 1.2 Create DataParser Module
**Priority: CRITICAL**

**Purpose:** Centralize all parsing logic

**Implementation:**
```lua
-- src/core/DataParser.lua
local DataParser = {}
DataParser.patterns = {}
DataParser.handlers = {}

function DataParser:init(stateManager, eventBus)
  self.state = stateManager
  self.events = eventBus
  self:registerPatterns()
end

function DataParser:registerPattern(name, pattern, handler)
  self.patterns[name] = {
    pattern = pattern,
    handler = handler,
    enabled = true
  }
end

function DataParser:parse(line)
  for name, data in pairs(self.patterns) do
    if data.enabled then
      local matches = {string.match(line, data.pattern)}
      if #matches > 0 then
        data.handler(matches, line)
      end
    end
  end
end

function DataParser:registerPatterns()
  -- HP/PSP/MV Prompt
  self:registerPattern("prompt", 
    "HP:%s*(%d+)/(%d+)%s+PSP:%s*(%d+)/(%d+)%s+MV:%s*(%d+)/(%d+)",
    function(matches, line)
      self.state:set("character.hp.current", tonumber(matches[1]))
      self.state:set("character.hp.max", tonumber(matches[2]))
      self.state:set("character.psp.current", tonumber(matches[3]))
      self.state:set("character.psp.max", tonumber(matches[4]))
      self.state:set("character.mv.current", tonumber(matches[5]))
      self.state:set("character.mv.max", tonumber(matches[6]))
      
      self.events:emit("prompt_updated", {
        hp = {current = tonumber(matches[1]), max = tonumber(matches[2])},
        psp = {current = tonumber(matches[3]), max = tonumber(matches[4])},
        mv = {current = tonumber(matches[5]), max = tonumber(matches[6])}
      })
    end
  )
  
  -- Add more patterns...
end

return DataParser
```

### 1.3 Create Proper Trigger System
**Priority: CRITICAL**

**Implementation:**
```lua
-- src/triggers/PromptTriggers.lua

-- Create tempTrigger for game prompt
tempTrigger(
  "TorilLib_Prompt",
  "^HP:%s*%d+/%d+%s+PSP:%s*%d+/%d+%s+MV:%s*%d+/%d+",
  [[
    if TorilLib and TorilLib.parsers then
      TorilLib.parsers.prompt:parse(line)
    end
  ]]
)

cecho("<cyan>Prompt triggers loaded\n")
```

---

## 🎯 PHASE 2: Character System (Week 2-3)

### 2.1 Character Auto-Detection
**Priority: HIGH**

**Implementation:**
```lua
-- src/character/CharacterProfile.lua
local CharacterProfile = {}

function CharacterProfile:init(stateManager, eventBus)
  self.state = stateManager
  self.events = eventBus
  self.detected = false
end

function CharacterProfile:detectCharacter(line)
  -- Pattern: "You are Playername the level 50 Grey Elf Warrior"
  local name, level, race, class = line:match(
    "You are (%w+) the level (%d+) (.+) (%w+)"
  )
  
  if name and level then
    self:loadCharacter(name, tonumber(level), race, class)
  end
end

function CharacterProfile:loadCharacter(name, level, race, class)
  -- Load from database
  local Classes = require("src.database.Classes")
  local Races = require("src.database.Races")
  
  local classData = Classes:get(class)
  local raceData = Races:get(race)
  
  -- Set character info
  self.state:set("character.name", name)
  self.state:set("character.level", level)
  self.state:set("character.race", race)
  self.state:set("character.class", class)
  
  -- Calculate base stats
  self:calculateBaseStats(classData, raceData, level)
  
  -- Emit event
  self.events:emit("character_detected", {
    name = name,
    level = level,
    race = race,
    class = class
  })
  
  self.detected = true
  cecho(string.format("<green>Character detected: %s (Level %d %s %s)\n",
    name, level, race, class))
end

function CharacterProfile:calculateBaseStats(classData, raceData, level)
  -- Calculate HP based on class and level
  local baseHP = classData.base_hp + (level * classData.hp_per_level)
  
  -- Add racial modifiers
  baseHP = baseHP + raceData.hp_modifier
  
  self.state:set("character.hp.max", baseHP)
  
  -- Similar for PSP, MV, stats...
end

return CharacterProfile
```

### 2.2 Equipment Manager
**Priority: HIGH**

**Implementation:**
```lua
-- src/character/EquipmentManager.lua
local EquipmentManager = {}

function EquipmentManager:init(stateManager, eventBus)
  self.state = stateManager
  self.events = eventBus
  self.scanning = false
end

function EquipmentManager:startScan()
  self.scanning = true
  self:clearEquipment()
  send("equipment") -- Send command to MUD
end

function EquipmentManager:clearEquipment()
  local slots = self.state:get("equipment.slots")
  for slot in pairs(slots) do
    self.state:set("equipment.slots." .. slot, nil)
  end
end

function EquipmentManager:parseEquipmentLine(line)
  if not self.scanning then return end
  
  -- Pattern: "<worn on body>       a cloth vest"
  local slot, item = line:match("<worn on ([^>]+)>%s+(.+)")
  
  if slot and item then
    local normalizedSlot = self:normalizeSlot(slot)
    self:equipItem(normalizedSlot, item)
  elseif line:match("^You are using:") then
    self.scanning = true
  elseif line:match("^$") and self.scanning then
    self.scanning = false
    self:recalculateStats()
  end
end

function EquipmentManager:normalizeSlot(slot)
  local slotMap = {
    ["body"] = "body",
    ["head"] = "head",
    ["legs"] = "legs",
    ["feet"] = "feet",
    ["hands"] = "hands",
    ["arms"] = "arms",
    ["about body"] = "about",
    ["waist"] = "waist",
    ["left finger"] = "finger_1",
    ["right finger"] = "finger_2",
    ["neck"] = "neck_1",
    ["left wrist"] = "wrist_1",
    ["right wrist"] = "wrist_2"
  }
  return slotMap[slot] or slot
end

function EquipmentManager:equipItem(slot, item)
  self.state:set("equipment.slots." .. slot, item)
  
  -- Parse item stats (would need item database)
  local stats = self:parseItemStats(item)
  
  self.events:emit("item_equipped", {
    slot = slot,
    item = item,
    stats = stats
  })
end

function EquipmentManager:parseItemStats(item)
  -- This would query item database
  -- For now, return empty stats
  return {
    hp = 0,
    ac = 0,
    hitroll = 0,
    damroll = 0
  }
end

function EquipmentManager:recalculateStats()
  local totalBonuses = {
    hp = 0,
    psp = 0,
    hitroll = 0,
    damroll = 0,
    ac = 0
  }
  
  local slots = self.state:get("equipment.slots")
  for slot, item in pairs(slots) do
    if item then
      local stats = self:parseItemStats(item)
      for stat, value in pairs(stats) do
        totalBonuses[stat] = totalBonuses[stat] + value
      end
    end
  end
  
  self.state:set("equipment.bonuses", totalBonuses)
  self.events:emit("equipment_stats_recalculated", totalBonuses)
end

return EquipmentManager
```

### 2.3 Stats Calculator
**Priority: MEDIUM**

**Implementation:**
```lua
-- src/character/StatsCalculator.lua
local StatsCalculator = {}

function StatsCalculator:init(stateManager, eventBus)
  self.state = stateManager
  self.events = eventBus
  
  -- Subscribe to changes
  self.events:subscribe("equipment_stats_recalculated", function()
    self:recalculateAll()
  end)
end

function StatsCalculator:recalculateAll()
  self:calculateTotalHP()
  self:calculateTotalPSP()
  self:calculateCombatStats()
end

function StatsCalculator:calculateTotalHP()
  local baseHP = self.state:get("character.hp.max") or 0
  local equipBonus = self.state:get("equipment.bonuses.hp") or 0
  local conBonus = self:getConstitutionBonus()
  
  local totalHP = baseHP + equipBonus + conBonus
  
  self.state:set("character.hp.max", totalHP)
  self.state:computeHPPercent()
end

function StatsCalculator:calculateTotalPSP()
  local basePSP = self.state:get("character.psp.max") or 0
  local equipBonus = self.state:get("equipment.bonuses.psp") or 0
  local intBonus = self:getIntelligenceBonus()
  local wisBonus = self:getWisdomBonus()
  
  local totalPSP = basePSP + equipBonus + intBonus + wisBonus
  
  self.state:set("character.psp.max", totalPSP)
  self.state:computePSPPercent()
end

function StatsCalculator:calculateCombatStats()
  local baseHitroll = 0
  local baseDamroll = 0
  local baseAC = 100 -- AC starts at 100 in TorilMUD
  
  local equipHitroll = self.state:get("equipment.bonuses.hitroll") or 0
  local equipDamroll = self.state:get("equipment.bonuses.damroll") or 0
  local equipAC = self.state:get("equipment.bonuses.ac") or 0
  
  self.state:set("character.combat.hitroll", baseHitroll + equipHitroll)
  self.state:set("character.combat.damroll", baseDamroll + equipDamroll)
  self.state:set("character.combat.ac", baseAC - equipAC) -- Lower is better
end

function StatsCalculator:getConstitutionBonus()
  local con = self.state:get("character.stats.con") or 0
  -- Constitution bonus table for TorilMUD
  if con >= 18 then return con - 8
  elseif con >= 15 then return con - 10
  else return 0 end
end

function StatsCalculator:getIntelligenceBonus()
  local int = self.state:get("character.stats.int") or 0
  return math.floor((int - 10) / 2) * 10 -- Rough estimate
end

function StatsCalculator:getWisdomBonus()
  local wis = self.state:get("character.stats.wis") or 0
  return math.floor((wis - 10) / 2) * 10 -- Rough estimate
end

return StatsCalculator
```

---

## 🎯 PHASE 3: Database Conversion (Week 3)

### 3.1 Convert Classes Database
**Priority: MEDIUM**

**Implementation:**
```lua
-- src/database/Classes.lua
local Classes = {}

Classes.data = {
  ["Warrior"] = {
    name = "Warrior",
    prime_stat = "STR",
    base_hp = 100,
    hp_per_level = 10,
    base_psp = 50,
    psp_per_level = 2,
    hit_bonus = 2,
    dam_bonus = 1,
    skills = {
      -- List of available skills
    }
  },
  
  ["Cleric"] = {
    name = "Cleric",
    prime_stat = "WIS",
    base_hp = 80,
    hp_per_level = 8,
    base_psp = 100,
    psp_per_level = 10,
    hit_bonus = 0,
    dam_bonus = 0,
    spells = {
      -- List of available spells
    }
  },
  
  -- Add all classes from SQL...
}

function Classes:get(className)
  return self.data[className]
end

function Classes:getAll()
  return self.data
end

function Classes:getSkillsForClass(className, level)
  local class = self:get(className)
  if not class then return {} end
  
  local availableSkills = {}
  for skill, minLevel in pairs(class.skills or {}) do
    if level >= minLevel then
      table.insert(availableSkills, skill)
    end
  end
  
  return availableSkills
end

return Classes
```

### 3.2 Convert Races Database
**Priority: MEDIUM**

**Implementation:**
```lua
-- src/database/Races.lua
local Races = {}

Races.data = {
  ["Human"] = {
    name = "Human",
    size = "medium",
    hp_modifier = 0,
    psp_modifier = 0,
    stat_modifiers = {
      str = 0, int = 0, wis = 0,
      dex = 0, con = 0, cha = 0
    },
    languages = {"common"}
  },
  
  ["Grey Elf"] = {
    name = "Grey Elf",
    size = "medium",
    hp_modifier = -5,
    psp_modifier = 10,
    stat_modifiers = {
      str = -1, int = 2, wis = 1,
      dex = 1, con = -1, cha = 1
    },
    languages = {"common", "elven"}
  },
  
  -- Add all races...
}

function Races:get(raceName)
  return self.data[raceName]
end

function Races:getAll()
  return self.data
end

function Races:getStatModifier(raceName, stat)
  local race = self:get(raceName)
  if not race then return 0 end
  return race.stat_modifiers[stat] or 0
end

return Races
```

---

## 🎯 PHASE 4: GUI Improvements (Week 4)

### 4.1 Container Content Management
**Priority: MEDIUM**

**Implementation:**
```lua
-- src/gui/ContainerManager.lua
local ContainerManager = {}

function ContainerManager:init(guiFlex, stateManager, eventBus)
  self.gui = guiFlex
  self.state = stateManager
  self.events = eventBus
  
  self:subscribeToEvents()
end

function ContainerManager:subscribeToEvents()
  -- Update Equipment container
  self.events:subscribe("equipment_stats_recalculated", function(bonuses)
    self:updateEquipmentContainer()
  end)
  
  -- Update Combat container
  self.events:subscribe("combat.damage_dealt", function(data)
    self:updateCombatContainer()
  end)
  
  -- Update Group container
  self.events:subscribe("group.member_hp_changed", function(data)
    self:updateGroupContainer()
  end)
end

function ContainerManager:updateEquipmentContainer()
  local slots = self.state:get("equipment.slots")
  local bonuses = self.state:get("equipment.bonuses")
  
  local content = "<b>Equipment:</b>\n\n"
  
  for slot, item in pairs(slots) do
    if item then
      content = content .. string.format("%s: %s\n", slot, item)
    end
  end
  
  content = content .. "\n<b>Bonuses:</b>\n"
  content = content .. string.format("HP: +%d\n", bonuses.hp or 0)
  content = content .. string.format("Hit: +%d\n", bonuses.hitroll or 0)
  content = content .. string.format("Dam: +%d\n", bonuses.damroll or 0)
  content = content .. string.format("AC: -%d\n", bonuses.ac or 0)
  
  self.gui:updateContainer("Equipment", content)
end

function ContainerManager:updateCombatContainer()
  local combat = self.state:get("combat")
  local log = self.state:get("combat.log")
  
  local content = "<b>Combat Status:</b>\n\n"
  
  if combat.inCombat then
    content = content .. string.format("Target: %s\n", combat.target or "None")
    content = content .. string.format("Round: %d\n", combat.round or 0)
  else
    content = content .. "Not in combat\n"
  end
  
  content = content .. "\n<b>Statistics:</b>\n"
  content = content .. string.format("Damage Dealt: %d\n", log.damage_dealt or 0)
  content = content .. string.format("Damage Taken: %d\n", log.damage_taken or 0)
  content = content .. string.format("Kills: %d\n", log.kills or 0)
  
  self.gui:updateContainer("Combat", content)
end

function ContainerManager:updateGroupContainer()
  local group = self.state:get("group")
  
  local content = "<b>Group:</b>\n\n"
  
  if not group.isGrouped then
    content = content .. "Not in a group\n"
  else
    content = content .. string.format("Leader: %s\n\n", group.leader)
    
    for _, member in ipairs(group.members) do
      local color = "white"
      if member.hp_percent < 30 then color = "red"
      elseif member.hp_percent < 60 then color = "yellow"
      else color = "green" end
      
      content = content .. string.format(
        "<%s>%s [%d %s] %d%%</%s>\n",
        color, member.name, member.level, member.class, member.hp_percent, color
      )
    end
  end
  
  self.gui:updateContainer("Group", content)
end

return ContainerManager
```

### 4.2 Theme Manager
**Priority: LOW**

**Implementation:**
```lua
-- src/gui/ThemeManager.lua
local ThemeManager = {}

ThemeManager.themes = {
  default = {
    name = "Default",
    backgroundColor = "rgba(0,0,0,100)",
    borderColor = "white",
    textColor = "white",
    gauges = {
      health = "red",
      psp = "blue",
      mv = "yellow",
      xp = "purple"
    }
  },
  
  dark = {
    name = "Dark",
    backgroundColor = "rgba(10,10,10,200)",
    borderColor = "grey",
    textColor = "lightgrey",
    gauges = {
      health = "darkred",
      psp = "darkblue",
      mv = "orange",
      xp = "darkviolet"
    }
  }
}

function ThemeManager:init(guiFlex)
  self.gui = guiFlex
  self.currentTheme = "default"
end

function ThemeManager:applyTheme(themeName)
  local theme = self.themes[themeName]
  if not theme then
    cecho("<red>Theme not found: " .. themeName .. "\n")
    return false
  end
  
  -- Update container styles
  for _, container in pairs(self.gui.containers) do
    container:setStyleSheet(string.format([[
      background-color: %s;
      border-color: %s;
      color: %s;
    ]], theme.backgroundColor, theme.borderColor, theme.textColor))
  end
  
  -- Update gauge colors
  self.gui.gauges.Health.front:setStyleSheet(
    "background-color: " .. theme.gauges.health
  )
  self.gui.gauges.PSP.front:setStyleSheet(
    "background-color: " .. theme.gauges.psp
  )
  self.gui.gauges.Endurance.front:setStyleSheet(
    "background-color: " .. theme.gauges.mv
  )
  self.gui.gauges.Experience.front:setStyleSheet(
    "background-color: " .. theme.gauges.xp
  )
  
  self.currentTheme = themeName
  cecho("<green>Theme applied: " .. theme.name .. "\n")
end

return ThemeManager
```

---

## 🎯 PHASE 5: Testing & Polish (Week 5)

### 5.1 Unit Tests
**Priority: MEDIUM**

**Implementation:**
```lua
-- tests/core/StateManager_test.lua
local StateManager = require("src.core.StateManager")

local function test_get_set()
  StateManager:init()
  
  StateManager:set("character.hp.current", 1234)
  local hp = StateManager:get("character.hp.current")
  
  assert(hp == 1234, "Failed: get/set basic value")
  cecho("<green>PASS: get/set basic value\n")
end

local function test_nested_paths()
  StateManager:init()
  
  StateManager:set("character.hp.current", 1234)
  StateManager:set("character.hp.max", 5678)
  
  local hp = StateManager:get("character.hp")
  
  assert(hp.current == 1234, "Failed: nested path current")
  assert(hp.max == 5678, "Failed: nested path max")
  cecho("<green>PASS: nested paths\n")
end

local function test_subscriptions()
  StateManager:init()
  
  local callbackFired = false
  StateManager:subscribe("character.hp", function(newValue)
    callbackFired = true
  end)
  
  StateManager:set("character.hp.current", 999)
  
  assert(callbackFired, "Failed: subscription callback")
  cecho("<green>PASS: subscription callback\n")
end

local function runTests()
  cecho("<cyan>Running StateManager tests...\n")
  test_get_set()
  test_nested_paths()
  test_subscriptions()
  cecho("<green>All tests passed!\n")
end

return {
  runTests = runTests
}
```

---

## 📋 Summary of Improvements

### Critical (Week 1)
1. ✅ Proper directory structure
2. ✅ init.lua entry point
3. ✅ DataParser module
4. ✅ Trigger system setup
5. ✅ Configuration system

### High Priority (Weeks 2-3)
6. ✅ Character auto-detection
7. ✅ Equipment manager
8. ✅ Stats calculator
9. ✅ Database conversion (Classes, Races)

### Medium Priority (Week 4)
10. ✅ Container content management
11. ✅ Theme manager
12. ✅ Better error handling
13. ✅ Logging system

### Lower Priority (Week 5+)
14. ✅ Unit tests
15. ✅ Integration tests
16. ✅ API documentation
17. ✅ User guide
18. ✅ Example scripts

---

## 🚀 Getting Started

### Immediate Actions

1. **Reorganize files** according to new structure
2. **Create init.lua** as main entry point
3. **Extract parsers** from Integration.lua
4. **Create trigger files** with actual Mudlet triggers
5. **Convert databases** from SQL to Lua tables

### Next Steps

1. Test basic functionality
2. Add character detection
3. Implement equipment tracking
4. Create container managers
5. Write tests
6. Polish and document

---

**This plan will take TorilLib from 60% → 90% complete!**
