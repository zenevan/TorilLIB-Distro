# Sojourn MUD - Text-Based Item Lookup System

Quick and dirty text-based item search to replace SQL database lookups for item identification.

## Installation

1. Copy the main script code into a Mudlet Script
2. Create the three aliases shown below
3. Place `short_stats.txt` in your Mudlet profile directory
4. Reload scripts or restart Mudlet

---

## Main Script Code

```lua
-------------------------------------------------------
-- Text-Based Item Lookup for Sojourn MUD
-- Quick & dirty replacement for SQL item lookups
-------------------------------------------------------

-- Initialize the item cache
NyyLIB = NyyLIB or {}
NyyLIB.itemcache = NyyLIB.itemcache or {}

function loadItemDatabase(filepath)
  -- Load items from text file into memory
  local file = io.open(filepath, "r")
  if not file then
    cecho("<red>[Error: Could not open " .. filepath .. "]\n")
    return false
  end
  
  NyyLIB.itemcache = {}
  local count = 0
  
  for line in file:lines() do
    if line and line:len() > 0 then
      -- Extract item name (everything before the first parenthesis)
      local itemname = line:match("^([^%(]+)")
      if itemname then
        itemname = itemname:trim()
        -- Store with lowercase key for case-insensitive lookup
        table.insert(NyyLIB.itemcache, {
          name = itemname,
          name_lower = itemname:lower(),
          stats = line
        })
        count = count + 1
      end
    end
  end
  
  file:close()
  cecho("<green>[Loaded " .. count .. " items from database]\n")
  return true
end

function txtiditem(searchterm)
  -- Search for items matching the term
  -- Returns array of full stat lines
  
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    cecho("<red>[Item cache not loaded! Use loadItemDatabase()]\n")
    return {}
  end
  
  -- Clean up search term
  searchterm = searchterm:gsub("%(poisoned%)", "")  -- remove (poisoned)
  searchterm = searchterm:trim():lower()
  
  local results = {}
  
  -- Search through cache
  for i, item in ipairs(NyyLIB.itemcache) do
    if string.find(item.name_lower, searchterm, 1, true) then
      table.insert(results, item.stats)
    end
  end
  
  return results
end

function lookupitem(itemname)
  -- Single item lookup - displays results
  local results = txtiditem(itemname)
  
  if #results == 0 then
    cecho("<red>[" .. itemname .. " : not found in database]\n")
    return nil
  end
  
  if #results == 1 then
    echo(results[1] .. "\n")
    return results[1]
  end
  
  -- Multiple matches - show all
  cecho("<yellow>[Found " .. #results .. " matches for '" .. itemname .. "']\n")
  for i, stat in ipairs(results) do
    echo("  " .. i .. ". " .. stat .. "\n")
  end
  
  return results
end

function lookupitems(itemlist, togsay)
  -- Multiple item lookup
  -- itemlist can be a table or comma-separated string
  -- togsay: if "gsay" will send to group, otherwise echo
  
  local items = {}
  
  -- Parse input
  if type(itemlist) == "string" then
    items = itemlist:split(",")
    for i = 1, #items do
      items[i] = items[i]:trim()
    end
  elseif type(itemlist) == "table" then
    items = itemlist
  else
    cecho("<red>[Invalid item list format]\n")
    return
  end
  
  -- Look up each item
  for _, itemname in ipairs(items) do
    local results = txtiditem(itemname)
    
    if #results == 0 then
      if togsay == "gsay" then
        send("gsay * " .. itemname .. " : not found in database. identify and mmail to katumi")
      else
        cecho("<red>[" .. itemname .. " : not found in database]\n")
      end
    else
      -- Use first match (or exact match if multiple found)
      local statline = results[1]
      
      -- If multiple results, try to find exact match
      if #results > 1 then
        for _, stat in ipairs(results) do
          -- Check if this result starts with the exact item name
          if stat:lower():find("^" .. itemname:lower() .. " ") then
            statline = stat
            break
          end
        end
      end
      
      if togsay == "gsay" then
        send("gsay * " .. statline)
      else
        echo(statline .. "\n")
      end
    end
  end
end

-------------------------------------------------------
-- ALIASES
-------------------------------------------------------

-- Single item lookup alias
-- Usage: @id sultan's ring
-- Regex: ^@id (.+)$
function alias_iditem()
  local itemname = matches[2]
  lookupitem(itemname)
end

-- Multiple item lookup from group items
-- Usage: @statitems
-- Usage: @statitems gsay
-- Regex: ^@statitems ?(gsay)?$
function alias_statitems()
  local togsay = matches[2]
  
  if not NyyLIB.groupitems or #NyyLIB.groupitems == 0 then
    cecho("<red>[groupitems is nil or empty]\n")
    return
  end
  
  lookupitems(NyyLIB.groupitems, togsay)
end

-- Manual multi-item lookup
-- Usage: @lookup ring, turban, staff
-- Regex: ^@lookup (.+)$
function alias_lookup()
  local itemstring = matches[2]
  lookupitems(itemstring)
end

-------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------

-- Load the database on startup
-- Adjust path as needed for your profile
local itemfile = getMudletHomeDir() .. "/short_stats.txt"
loadItemDatabase(itemfile)

cecho("<cyan>[Item Lookup System Ready]\n")
cecho("<cyan>[Commands: @id <item>, @statitems [gsay], @lookup <item1, item2, ...>]\n")
```

---

## Alias Configurations

### Alias 1: @id (Single Item Lookup)

**Name:** `@id`  
**Regex:** `^@id (.+)$`  
**Script:**
```lua
alias_iditem()
```

---

### Alias 2: @statitems (Batch Group Items)

**Name:** `@statitems`  
**Regex:** `^@statitems ?(gsay)?$`  
**Script:**
```lua
alias_statitems()
```

---

### Alias 3: @lookup (Manual Multi-Item)

**Name:** `@lookup`  
**Regex:** `^@lookup (.+)$`  
**Script:**
```lua
alias_lookup()
```

---

## Usage Examples

### Single Item Lookup
```
@id sultan's ring
> the Sultan's ring (FINGER) * SvBr:-3 * Wt:0 Val:5p * QUEST-ITEM * Nizari

@id celestial
> [Found 3 matches for 'celestial']
>   1. the tail of a celestial scorpion * POISON...
>   2. the teeth of a celestial badger (NECK)...
>   3. the warmaul of celestial glory (warmaul celestial maul glory)...
```

### Batch Group Items Lookup
```
@statitems
> (looks up all items in NyyLIB.groupitems and echoes results)

@statitems gsay
> gsay * the Sultan's ring (FINGER) * SvBr:-3 * Wt:0 Val:5p * QUEST-ITEM * Nizari
> gsay * the teeth of a celestial badger (NECK) * AC:2 0/1 * Wt:2 Val:0...
```

### Manual Multi-Item Lookup
```
@lookup ring, turban, staff
> the Sultan's ring (FINGER) * SvBr:-3 * Wt:0 Val:5p * QUEST-ITEM * Nizari
> the Sultan's turban (HEAD) * AC:2 Int:9 Wis:9 * Wt:4 Val:1p * QUEST-ITEM * Nizari
> the Thain's staff (HOLD, WIELD) * STAFF (Level 30 chain lightning, 5/5 Charges)...
```

---

## Features

- ✅ **Fast in-memory lookups** - No SQL overhead
- ✅ **Case-insensitive partial matching** - Like SQL `LIKE '%term%'`
- ✅ **Handles multiple matches** - Shows all when ambiguous
- ✅ **Batch processing** - Look up multiple items at once
- ✅ **Group integration** - Works with existing `NyyLIB.groupitems`
- ✅ **Optional gsay output** - Send results to group chat

---

## File Requirements

**File:** `short_stats.txt`  
**Location:** Mudlet profile directory (usually `~/.config/mudlet/profiles/YourProfile/`)  
**Format:** One item per line, item name at the start before first parenthesis

Example line:
```
the Sultan's ring (FINGER) * SvBr:-3 * Wt:0 Val:5p * QUEST-ITEM * Nizari
```

---

## Customization

### Change Database File Location

Edit this line in the initialization section:
```lua
local itemfile = getMudletHomeDir() .. "/short_stats.txt"
```

### Reload Database Manually

If you update `short_stats.txt`:
```lua
loadItemDatabase(getMudletHomeDir() .. "/short_stats.txt")
```

### Use Long Stats Instead

Change the initialization to:
```lua
local itemfile = getMudletHomeDir() .. "/long_stats.txt"
```

---

## Notes

- The system loads all items into memory on startup for fast lookups
- Item names are extracted as everything before the first `(` character
- Search is case-insensitive and matches partial strings
- Handles `(poisoned)` suffix removal like the original SQL version
- When multiple matches are found, it tries to find exact matches first

---

## Troubleshooting

**"Item cache not loaded!"**
- Check that `short_stats.txt` exists in your profile directory
- Verify the file path in the initialization code
- Try manually running: `loadItemDatabase(getMudletHomeDir() .. "/short_stats.txt")`

**"groupitems is nil or empty"**
- Make sure `NyyLIB.groupitems` is populated before using `@statitems`
- This variable should be a table of item names from your group tracking

**No results found**
- Check spelling of item name
- Try searching for just a partial name (e.g., "ring" instead of "sultan's ring")
- Verify the item exists in your `short_stats.txt` file
