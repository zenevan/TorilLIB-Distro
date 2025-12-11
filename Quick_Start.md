# TorilLib Quick Start Guide

## 🚀 Installation & Setup

### Step 1: Install Files

1. **Download all TorilLib files** to your Mudlet profile folder:
   ```
   Windows: %APPDATA%/Mudlet/profiles/[YourProfile]/TorilLib/
   Mac: ~/Library/Application Support/Mudlet/profiles/[YourProfile]/TorilLib/
   Linux: ~/.config/mudlet/profiles/[YourProfile]/TorilLib/
   ```

2. **Required file structure:**
   ```
   TorilLib/
   ├── init.lua                    # Main entry point
   └── src/
       ├── core/
       │   ├── StateManager.lua
       │   └── EventBus.lua
       └── gui/
           └── GUIFlex.lua
   ```

### Step 2: Load in Mudlet

1. **Open Mudlet** and connect to TorilMUD

2. **In Mudlet's input line, type:**
   ```lua
   dofile(getMudletHomeDir() .. "/TorilLib/init.lua")
   ```

3. **Initialize TorilLib:**
   ```lua
   TorilLib:init()
   ```

4. **Show the GUI:**
   ```lua
   TorilLib:show()
   ```

### Step 3: Verify Installation

You should see:
- ✅ Green initialization messages
- ✅ GUI containers displayed
- ✅ Gauges ready (HP, PSP, MV, XP)
- ✅ 9 containers visible

---

## 📱 First Time Use

### Display GUI
```lua
TorilLib:show()
```

### Hide GUI
```lua
TorilLib:hide()
```

### Test the System
```lua
TorilLib:test()
```

### Get Help
```lua
TorilLib:help()
```

---

## 🎮 Using TorilLib

### Automatic Features

Once initialized, TorilLib automatically:

1. **Tracks your stats** from game prompts
   - HP, PSP, MV updated in real-time
   - Gauges update automatically
   
2. **Detects your character** on login
   - Recognizes name, level, race, class
   - Loads appropriate data

3. **Monitors equipment changes**
   - Tracks equipped items
   - Calculates bonuses (Phase 3)

4. **Records combat data**
   - Damage dealt/taken
   - Kill count
   - Combat log (Phase 3)

### Manual Commands

**View Current State:**
```lua
-- See character info
display(TorilLib.StateManager:get("character"))

-- See specific values
local hp = TorilLib.StateManager:get("character.hp.current")
local level = TorilLib.StateManager:get("character.level")
```

**Update GUI Manually:**
```lua
-- Update HP gauge
TorilLib.GUIFlex:updateGauge("Health", 1234, 5678)

-- Update container content
TorilLib.GUIFlex:updateContainer("Combat", "Test content")
```

**Subscribe to Events:**
```lua
-- Get notified of HP changes
TorilLib.EventBus:subscribe("character.hp_changed", function(data)
  cecho(string.format("HP changed: %d/%d\n", data.current, data.max))
end)
```

---

## 🔧 Configuration

### Enable Debug Mode
```lua
TorilLib:enableDebug()
```

This shows:
- All state changes
- Event emissions
- Parser activity

### Disable Debug Mode
```lua
TorilLib:disableDebug()
```

### Reload System
```lua
TorilLib:reload()
```

---

## 📊 GUI Layout

```
┌────────────────────────────────────────────────────────┐
│                     BUTTONS (12)                       │
├───────────┬────────────────────────────┬───────────────┤
│   GROUP   │                            │     MAP       │
│  (25x25%) │                            │   (25x50%)    │
├───────────┤      GAME WINDOW          ├───────────────┤
│ EQUIPMENT │                            │     ROOM      │
│(12.5x50%) │                            │  (12.5x50%)   │
├───────────┤                            ├───────────────┤
│  COMBAT   │                            │    ATLAS      │
│(12.5x50%) │                            │  (12.5x50%)   │
├───────────┼────────────────────────────┴───────────────┤
│  POWERS   │                                            │
│ (25x25%)  │                                            │
├───────────┴────────────────────────────────────────────┤
│           GAUGES (HP, PSP, MV, XP)                     │
└────────────────────────────────────────────────────────┘
```

### Container Purposes

| Container | Purpose | Status |
|-----------|---------|--------|
| **Buttons** | Quick actions (12 configurable) | ✅ Ready |
| **Gauges** | HP/PSP/MV/XP bars | ✅ Working |
| **Group** | Group member status | ✅ Ready |
| **Equipment** | Equipped items & bonuses | 🔄 Phase 3 |
| **Combat** | Combat tracker & stats | 🔄 Phase 3 |
| **Powers** | Available spells/powers | 🔄 Phase 3 |
| **Map** | Current area map | ✅ Ready |
| **Room** | Room details | ✅ Ready |
| **Atlas** | World navigation | ✅ Ready |

---

## 🧪 Testing

### Basic Functionality Test
```lua
TorilLib:test()
```

This will:
1. Show GUI
2. Simulate prompt parsing
3. Test character detection
4. Display current state

### Manual Testing

**Test Prompt Parsing:**
```lua
TorilLib:testPrompt()
```

**Test Character Detection:**
```lua
TorilLib:detectCharacter("You are YourName the level 50 Human Warrior")
```

**Check State:**
```lua
display(TorilLib.StateManager:get())
```

---

## 🐛 Troubleshooting

### GUI Not Showing

**Problem:** GUI doesn't appear after `TorilLib:show()`

**Solutions:**
```lua
-- 1. Check if containers exist
display(TorilLib.GUIFlex.containers)

-- 2. Manually show each container
for name, container in pairs(TorilLib.GUIFlex.containers) do
  container:show()
end

-- 3. Reload system
TorilLib:reload()
```

### Gauges Not Updating

**Problem:** Health/PSP/MV bars don't update

**Solutions:**
```lua
-- 1. Enable debug mode to see events
TorilLib:enableDebug()

-- 2. Manually test prompt parsing
TorilLib:parsePrompt("HP: 1234/5678  PSP: 890/1200  MV: 567/890")

-- 3. Check if triggers are active
display(tempTriggers)

-- 4. Check event subscriptions
display(TorilLib.EventBus:listEvents())
```

### State Not Saving

**Problem:** State resets on reload

**Solution:**
```lua
-- Manual save/load
TorilLib.StateManager:save()
TorilLib.StateManager:load()
```

### Triggers Not Firing

**Problem:** Parsers not catching game output

**Solutions:**
```lua
-- 1. Check trigger patterns
display(tempTriggers)

-- 2. Test manually with game output
local testLine = "HP: 1234/5678  PSP: 890/1200  MV: 567/890"
TorilLib.parsers.prompt:parse(testLine)

-- 3. Recreate triggers
TorilLib:reload()
```

---

## 📚 Common Use Cases

### 1. Monitor Health During Combat

```lua
-- Subscribe to HP changes
TorilLib.EventBus:subscribe("character.hp_changed", function(data)
  if data.percent < 30 then
    cecho("<red>!!! LOW HEALTH !!!\n")
    send("recall") -- Emergency recall
  end
end)
```

### 2. Track Combat Damage

```lua
-- Subscribe to damage events
TorilLib.EventBus:subscribe("combat.damage_dealt", function(data)
  cecho(string.format("<yellow>Hit for %d damage!\n", data.damage))
end)

TorilLib.EventBus:subscribe("combat.damage_taken", function(data)
  cecho(string.format("<red>Took %d damage!\n", data.damage))
end)
```

### 3. Group Health Monitor

```lua
-- Subscribe to group HP changes
TorilLib.EventBus:subscribe("group.member_hp_changed", function(data)
  if data.hp_percent < 40 then
    cecho(string.format("<red>%s low on HP: %d%%\n", 
      data.name, data.hp_percent))
    -- Auto-heal if you're a healer
    send("cast 'heal' " .. data.name)
  end
end)
```

### 4. Auto-Update Equipment Display

```lua
-- Subscribe to equipment changes
TorilLib.EventBus:subscribe("equipment.changed", function(data)
  cecho(string.format("<cyan>Equipment updated: %s -> %s\n",
    data.slot, data.item))
end)
```

---

## 🎯 What's Working Now

### ✅ Core Systems
- State management
- Event system
- GUI framework

### ✅ Real-Time Updates
- HP/PSP/MV gauges
- Prompt parsing
- Event-driven updates

### ✅ GUI
- 9 containers displayed
- 12 configurable buttons
- 4 status gauges
- Resizable/adjustable

### ✅ Basic Tracking
- Character detection
- Prompt monitoring
- Combat logging (basic)

---

## 🔄 Coming in Phase 3

### Character System
- Full equipment tracking
- Stat calculations
- Bonus computations
- Inventory management

### Advanced Combat
- Cooldown tracking
- Queue system
- DPS calculator
- Combat analysis

### Enhanced GUI
- Theme system
- Layout presets
- Container templates
- Custom widgets

---

## 💡 Tips & Best Practices

### 1. Always Initialize on Connect
Create an alias:
```lua
-- Alias: 'tl'
dofile(getMudletHomeDir() .. "/TorilLib/init.lua")
TorilLib:init()
TorilLib:show()
```

### 2. Use Debug Mode When Testing
```lua
TorilLib:enableDebug()
-- Test your features
TorilLib:disableDebug()
```

### 3. Subscribe to Events for Custom Features
```lua
-- Example: Auto-flee at low HP
TorilLib.EventBus:subscribe("character.hp_changed", function(data)
  if data.current < 100 then
    send("flee")
  end
end)
```

### 4. Save State Periodically
```lua
-- Create a timer to auto-save
tempTimer(300, [[TorilLib.StateManager:save()]], true) -- Every 5 min
```

### 5. Check State for Debugging
```lua
-- Quick state check
display(TorilLib.StateManager:get("character"))
```

---

## 📞 Getting Help

### In-Game
- Type: `TorilLib:help()`
- Check: `TorilLib.version`
- Debug: `TorilLib:enableDebug()`

### Documentation
- README.md - Full documentation
- PHASE-2-3-TRANSITION.md - Roadmap
- improvement_plan.md - Feature plan

### Testing
- `TorilLib:test()` - Full test suite
- `TorilLib:testPrompt()` - Test parsing

---

## 🎉 You're Ready!

TorilLib is now installed and ready to use. The system will automatically track your character's stats and update the GUI in real-time.

**Next steps:**
1. Connect to TorilMUD
2. Watch the gauges update
3. Explore the containers
4. Customize to your needs

**Happy adventuring in Toril!** 🗡️🛡️✨

---

*TorilLib v2.1.0 - Built for the TorilMUD community*
