# TorilMUD Item Lookup & Bag Inspection System

## Overview

This system provides item database lookups, bag contents inspection, and mob gear inspection using two text-based databases (`short_stats.txt` and `long_stats.txt`) loaded into memory at startup. No SQL required for item lookups.

---

## File Structure

| Script Name | Purpose |
|---|---|
| `item_short` | Loads `short_stats.txt`, provides `sqliditem()` and related functions |
| `item_long` | Loads `long_stats.txt`, provides `longSearch()` and related functions |

Both scripts live in Mudlet's Script editor. Triggers and Aliases are separate.

---

## Script: `item_short`

Paste this into a Mudlet script named `item_short`.

```lua
NyyLIB = NyyLIB or {}
NyyLIB.itemcache = NyyLIB.itemcache or {}
NyyLIB.itemdb = NyyLIB.itemdb or {}

function loadItemDatabase()
  local filepath = getMudletHomeDir() .. "/short_stats.txt"
  local file = io.open(filepath, "r")
  if not file then
    cecho("<red>[Error: Could not open " .. filepath .. "]\n")
    cecho("<red>[Item lookups will not work!]\n")
    return false
  end
  NyyLIB.itemcache = {}
  local count = 0
  for line in file:lines() do
    if line and line:len() > 0 then
      local itemname = line:match("^([^%(]+)")
      if itemname then
        itemname = itemname:trim()
        table.insert(NyyLIB.itemcache, {
          name       = itemname,
          name_lower = itemname:lower(),
          stats      = line,
          stats_lower= line:lower()
        })
        count = count + 1
      end
    end
  end
  file:close()
  cecho("<green>[Loaded " .. count .. " items from text database]\n")
  return true
end

function sqliditem(xitemname)
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    cecho("<red>[Item cache not loaded! Run loadItemDatabase()]\n")
    return {}
  end
  xitemname = string.gsub(xitemname, "%(poisoned%)", "")
  xitemname = xitemname:trim()
  local searchterm = xitemname:lower()
  local retval = {}
  for i, item in ipairs(NyyLIB.itemcache) do
    if string.find(item.name_lower, searchterm, 1, true) then
      table.insert(retval, item.stats)
    end
  end
  return retval
end

function sqlshortstats(xsqlstring)
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    cecho("<red>[Item cache not loaded!]\n")
    return {}
  end
  local sqlitems = xsqlstring:split(",")
  for nx = 1, #sqlitems do sqlitems[nx] = sqlitems[nx]:trim() end
  local retval = {}
  local positive_terms = {}
  local negative_terms = {}
  for nx = 1, #sqlitems do
    if sqlitems[nx]:sub(1,1) == "-" then
      table.insert(negative_terms, sqlitems[nx]:sub(2):lower())
    else
      table.insert(positive_terms, sqlitems[nx]:lower())
    end
  end
  for i, item in ipairs(NyyLIB.itemcache) do
    local match = true
    for _, term in ipairs(positive_terms) do
      if not string.find(item.stats_lower, term, 1, true) then match = false; break end
    end
    if match then
      for _, term in ipairs(negative_terms) do
        if string.find(item.stats_lower, term, 1, true) then match = false; break end
      end
    end
    if match then table.insert(retval, item.stats) end
  end
  return retval
end

function sqlIsWeapon(xitemname)
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then return {} end
  local searchterm = xitemname:lower()
  local retval = {}
  for i, item in ipairs(NyyLIB.itemcache) do
    if string.find(item.name_lower, searchterm, 1, true) then
      if string.find(item.stats_lower, "wield") and string.find(item.stats_lower, "%d+d%d+") then
        table.insert(retval, item.stats)
      end
    end
  end
  return retval
end

function sqlIsBow(xitemname)
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then return {} end
  local searchterm = xitemname:lower()
  local retval = {}
  for i, item in ipairs(NyyLIB.itemcache) do
    if string.find(item.name_lower, searchterm, 1, true) then
      if string.find(item.stats_lower, "type:bow") or
         string.find(item.stats_lower, "type:crossbow") or
         string.find(item.stats_lower, "type:longbow") or
         string.find(item.stats_lower, "type:shortbow") then
        table.insert(retval, item.stats)
      end
    end
  end
  return retval
end

function sqlIs2H(xitemname)
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then return {} end
  local searchterm = xitemname:lower()
  local retval = {}
  for i, item in ipairs(NyyLIB.itemcache) do
    if string.find(item.name_lower, searchterm, 1, true) then
      if string.find(item.stats_lower, "wield 2h") or
         string.find(item.stats_lower, "two_hand") or
         string.find(item.stats_lower, "two%-hand") then
        table.insert(retval, item.stats)
      end
    end
  end
  return retval
end

function sqlindexitem(xitemname)
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then return {} end
  local searchterm = xitemname:lower()
  local retval = {}
  for i, item in ipairs(NyyLIB.itemcache) do
    if string.find(item.name_lower, searchterm, 1, true) then
      display(i)
      display(item.name)
      table.insert(retval, item.name)
    end
  end
  return retval
end

function createconsumabledb()
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    cecho("<red>[Item cache not loaded! Cannot create consumable DB]\n")
    return
  end
  NyyLIB.itemdb = {}
  for i, item in ipairs(NyyLIB.itemcache) do
    local stats = item.stats
    if string.find(stats, "%(Potion%) ") then
      local st, en, retval = string.find(stats, "%(Potion%)([A-Za-z0-9: -]+)%*")
      if retval then NyyLIB.itemdb[item.name] = {"potion", retval:trim()} end
    end
    if string.find(stats, "%(Scroll%) ") then
      local st, en, retval = string.find(stats, "%(Scroll%)([A-Za-z0-9: -]+)%*")
      if retval then NyyLIB.itemdb[item.name] = {"scroll", retval:trim()} end
    end
    if string.find(stats, "%(Poison%) ") then
      local st, en, retval = string.find(stats, "%(Poison%)([A-Za-z0-9: -]+)%*")
      if retval then NyyLIB.itemdb[item.name] = {"poison", retval:trim()} end
    end
  end
  cecho("<red>[Consumable database cached: Potions, Scrolls, Poisons]\n")
end

-- Search aliases for friendly shorthand
SEARCH_ALIASES = {
  ["cleric"]    = "CLERIC-ONLY",
  ["mage"]      = "MAGE-ONLY",
  ["ranger"]    = "RANGER-ONLY",
  ["rogue"]     = "ROGUE-ONLY",
  ["warrior"]   = "WARRIOR-ONLY",
  ["druid"]     = "DRUID-ONLY",
  ["paladin"]   = "PALADIN-ONLY",
  ["bard"]      = "BARD-ONLY",
  ["illithid"]  = "ILLITHID-ONLY",
  ["healbonus"] = "HealBon:",
  ["healing"]   = "HealBon:",
  ["sfheal"]    = "SF-Heal:",
  ["hpbonus"]   = "Hp:",
  ["manabonus"] = "Mana:",
  ["container"] = "CONTAINER",
  ["potion"]    = "POTION",
  ["scroll"]    = "SCROLL",
  ["wand"]      = "WAND",
  ["staff"]     = "STAFF",
  ["quest"]     = "QUEST-ITEM",
  ["noquest"]   = "-QUEST-ITEM",
  ["weapon"]    = "wield",
  ["bow"]       = "type:bow",
  ["2h"]        = "wield 2h",
}

function searchItems(...)
  local args = {...}
  if #args == 0 then
    cecho("<yellow>[Usage: searchItems('term1', 'term2', '-excluded')]\n")
    return
  end
  local resolved = {}
  for _, arg in ipairs(args) do
    local prefix = ""
    local term = arg
    if arg:sub(1,1) == "-" then prefix = "-"; term = arg:sub(2) end
    local aliased = SEARCH_ALIASES[term:lower()]
    if aliased then
      if aliased:sub(1,1) == "-" then prefix = "-"; aliased = aliased:sub(2) end
      table.insert(resolved, prefix .. aliased)
    else
      table.insert(resolved, prefix .. term)
    end
  end
  local searchstring = table.concat(resolved, ",")
  local results = sqlshortstats(searchstring)
  if #results == 0 then
    cecho("<yellow>[No items found matching: " .. searchstring .. "]\n")
    return
  end
  cecho("<cyan>--- Search: <white>" .. searchstring .. " <cyan>(" .. #results .. " results) ---\n")
  for _, line in ipairs(results) do
    local colored = line
    colored = colored:gsub("^([^%*]+)%*", function(name)
      return "<white>" .. name .. "<yellow>*"
    end)
    colored = colored:gsub("(%a+:%-?%d+)", "<green>%1<reset>")
    colored = colored:gsub("(%u+%-ONLY)", "<red>%1<reset>")
    colored = colored:gsub("(POTION%b())", "<magenta>%1<reset>")
    colored = colored:gsub("(SCROLL%b())", "<magenta>%1<reset>")
    colored = colored:gsub("(WAND%b())",   "<magenta>%1<reset>")
    colored = colored:gsub("(STAFF%b())",  "<magenta>%1<reset>")
    colored = colored:gsub("QUEST%-ITEM",  "<red>QUEST-ITEM<reset>")
    colored = colored:gsub("%s%(R%)%s*$",  " <yellow>(R)<reset>")
    colored = colored:gsub("%s%(Q%)%s*$",  " <cyan>(Q)<reset>")
    cecho(colored .. "\n")
  end
  cecho("<cyan>--- End of results ---\n")
end

function bagFormatLine(line)
  local out = line
  out = out:gsub("^([^%*]+)%*", function(n) return "<white>" .. n .. "<yellow>*" end)
  out = out:gsub("(%a+:%-?%d+)", "<green>%1<reset>")
  out = out:gsub("(%u+%-ONLY)", "<red>%1<reset>")
  out = out:gsub("(POTION%b())",  "<magenta>%1<reset>")
  out = out:gsub("(SCROLL%b())",  "<magenta>%1<reset>")
  out = out:gsub("(WAND%b())",    "<magenta>%1<reset>")
  out = out:gsub("(STAFF%b())",   "<magenta>%1<reset>")
  out = out:gsub("QUEST%-ITEM",   "<red>QUEST-ITEM<reset>")
  out = out:gsub("%s%(R%)%s*$",   " <yellow>(R)<reset>")
  out = out:gsub("%s%(Q%)%s*$",   " <cyan>(Q)<reset>")
  return out
end

-- Character database (SQL - unchanged)
function sqlOpen()
  NyyLIB.env  = assert(luasql.sqlite3())
  NyyLIB.conn = assert(NyyLIB.env:connect(mainpath("toril.db")))
  local recs = assert(NyyLIB.conn:execute([[SELECT * FROM chars]]))
  local row = recs:fetch({})
  while row do row = recs:fetch({}) end
  recs:close()
  loadItemDatabase()
end

function sqlinwho(xname)
  local recs = assert(NyyLIB.conn:execute([[SELECT class_name, char_race, account_name FROM chars WHERE char_name = ']] .. xname .. [[']]))
  local row = recs:fetch({})
  recs:close()
  if row == nil then return false end
  local profilename
  for k, v in pairs(NyyLIB.fullclasslist) do
    if v[1] == row[1]:trim() then
      whoadd(xname, v[2], row[2], row[3])
      profilename = row[3]
    end
  end
  return profilename
end

function sqlprofilename(xname)
  local recs = assert(NyyLIB.conn:execute([[SELECT class_name, char_race, account_name FROM chars WHERE char_name = ']] .. xname .. [[']]))
  local row = recs:fetch({})
  recs:close()
  if row == nil then return false end
  return row[3]
end

function sqlclist(xname)
  local retval = {}
  local recs = assert(NyyLIB.conn:execute([[
    SELECT char_name, class_name, char_race, char_level, account_name FROM
    chars WHERE vis = 't' AND (account_name = (SELECT account_name
    FROM chars WHERE LOWER(char_name) = LOWER(']] .. xname .. [[') AND vis = 't') OR
    LOWER(account_name) = LOWER(']] .. xname .. [[')) ORDER BY char_level DESC, char_name ASC]]))
  local row = recs:fetch({})
  while row do
    retval[#retval+1] = {row[4], row[2], row[1], row[3], row[5]}
    row = recs:fetch({})
  end
  recs:close()
  return retval
end

if not NyyLIB.conn then
  loadItemDatabase()
end
```

---

## Script: `item_long`

Paste this into a Mudlet script named `item_long`.

```lua
NyyLIB = NyyLIB or {}
NyyLIB.longcache = NyyLIB.longcache or {}

function loadLongDatabase()
  local filepath = getMudletHomeDir() .. "/long_stats.txt"
  local file = io.open(filepath, "r")
  if not file then
    cecho("<red>[Error: Could not open " .. filepath .. "]\n")
    return false
  end
  NyyLIB.longcache = {}
  local count = 0
  for line in file:lines() do
    if line and line:len() > 0 then
      local entry = parseLongStatLine(line)
      if entry then
        table.insert(NyyLIB.longcache, entry)
        count = count + 1
      end
    end
  end
  file:close()
  cecho("<green>[Loaded " .. count .. " items from long stats database]\n")
  return true
end

function parseLongStatLine(line)
  local parts = {}
  for part in line:gmatch("([^*]+)%*?") do
    parts[#parts + 1] = part:trim()
  end
  if #parts < 2 then return nil end

  local fullname, keywords = parts[1]:match("^(.-)%s*%((.-)%)%s*$")
  if not fullname then fullname = parts[1]:trim(); keywords = "" end

  local itype, slots = "", ""
  if parts[2] then
    itype, slots = parts[2]:match("^(%S+)%s*%((.-)%)%s*$")
    if not itype then itype = parts[2]:trim(); slots = "" end
  end

  local wt, val = 0, 0
  local statparts = {}
  local flags = {}
  local location, rarity, date = "", "", ""

  for i = 3, #parts do
    local p = parts[i]:trim()
    if p == "" then
    elseif p:match("^%d%d%d%d%-%d%d%-%d%d$") then
      date = p
    elseif p:match("^Wt:") then
      wt  = tonumber(p:match("Wt:(%d+)")) or 0
      val = tonumber(p:match("Val:(%d+)")) or 0
    elseif p:match("%(([RNQSICX!])%)%s*$") then
      rarity   = p:match("%(([RNQSICX!])%)%s*$") or ""
      location = p:gsub("%s*%([RNQSICX!]%)%s*$", ""):trim()
    elseif p:match("^[A-Z][A-Z%-]+") and not p:match(":") then
      for flag in p:gmatch("%S+") do flags[#flags + 1] = flag end
    elseif p:match("Holds:") or p:match("Wtless:") or p:match("Level %d")
        or p:match("Type:") or p:match("Dice:") or p:match("Powers:")
        or p:match("Proc:") or p:match("Called Proc:") or p:match("Combat Bonus:")
        or p:match("Enchants:") or p:match("[A-Za-z]+:%d") or p:match("[A-Za-z]+:%-?%d") then
      statparts[#statparts + 1] = p
    else
      statparts[#statparts + 1] = p
    end
  end

  local statsstr = table.concat(statparts, " ")
  local flagsstr = table.concat(flags, " ")

  return {
    line       = line,
    line_lower = line:lower(),
    fullname   = fullname:trim(),
    name_lower = fullname:lower():trim(),
    keywords   = keywords,
    keys_lower = keywords:lower(),
    itype      = itype:upper(),
    slots      = slots:upper(),
    stats      = statsstr,
    stats_lower= statsstr:lower(),
    flags      = flagsstr,
    flags_lower= flagsstr:lower(),
    location   = location,
    rarity     = rarity,
    date       = date,
    wt         = wt,
    val        = val,
  }
end

function longIdItem(xname)
  if not NyyLIB.longcache or #NyyLIB.longcache == 0 then
    cecho("<red>[Long stat cache not loaded!]\n")
    return {}
  end
  xname = xname:gsub("%(poisoned%)", ""):trim()
  local term = xname:lower()
  local retval = {}
  for _, item in ipairs(NyyLIB.longcache) do
    if item.name_lower:find(term, 1, true) or item.keys_lower:find(term, 1, true) then
      table.insert(retval, item)
    end
  end
  return retval
end

function longSearch(xsearch, displayresults)
  if not NyyLIB.longcache or #NyyLIB.longcache == 0 then
    cecho("<red>[Long stat cache not loaded!]\n")
    return {}
  end
  local terms = {}
  for t in xsearch:gmatch("[^,]+") do
    local term = t:trim()
    if term ~= "" then terms[#terms + 1] = term end
  end
  local retval = {}
  for _, item in ipairs(NyyLIB.longcache) do
    local match = true
    for _, term in ipairs(terms) do
      local neg = false
      if term:sub(1,1) == "-" then neg = true; term = term:sub(2) end
      local found = false
      local termlow = term:lower()
      local prefix, value = termlow:match("^(%a+):(.+)$")
      if prefix == "slot" then
        found = item.slots:lower():find(value, 1, true) ~= nil
      elseif prefix == "type" then
        found = item.itype:lower():find(value, 1, true) ~= nil
      elseif prefix == "flag" then
        found = item.flags_lower:find(value, 1, true) ~= nil
      elseif prefix == "loc" then
        found = item.location:lower():find(value, 1, true) ~= nil
      elseif prefix == "rare" then
        found = item.rarity:lower() == value
      elseif prefix == "key" then
        found = item.keys_lower:find(value, 1, true) ~= nil
      elseif prefix == "date" then
        found = item.date:find(value, 1, true) ~= nil
      else
        found = item.line_lower:find(termlow, 1, true) ~= nil
      end
      if neg and found      then match = false; break end
      if not neg and not found then match = false; break end
    end
    if match then retval[#retval + 1] = item end
  end
  if displayresults then longDisplayResults(retval, xsearch) end
  return retval
end

function longDisplayResults(results, searchterm)
  if #results == 0 then
    cecho("<yellow>[No items found: " .. searchterm .. "]\n")
    return
  end
  cecho("<cyan>--- Long Search: <white>" .. searchterm ..
        " <cyan>(" .. #results .. " results) ---\n")
  for _, item in ipairs(results) do
    local raritycolor = "<white>"
    if     item.rarity == "R" then raritycolor = "<yellow>"
    elseif item.rarity == "Q" then raritycolor = "<cyan>"
    elseif item.rarity == "N" then raritycolor = "<green>"
    elseif item.rarity == "I" then raritycolor = "<magenta>"
    end
    cecho("<white>" .. item.fullname)
    if item.slots ~= "" then cecho(" <dark_slate_grey>(" .. item.slots .. ")") end
    if item.stats ~= "" then cecho(" <green>" .. item.stats) end
    if item.flags ~= "" then
      local flagstr = item.flags
      flagstr = flagstr:gsub("(NO%-%a+)",   "<red>%1<reset>")
      flagstr = flagstr:gsub("(ANTI%-%a+)", "<orange>%1<reset>")
      cecho(" " .. flagstr)
    end
    cecho(" " .. raritycolor .. item.location)
    if item.rarity ~= "" then cecho(" (" .. item.rarity .. ")") end
    cecho("<reset>\n")
  end
  cecho("<cyan>--- End of results ---\n")
end

loadLongDatabase()
```

---

## Triggers

### Trigger Group: `DisplayContainer`

Create a trigger **group** named `DisplayContainer`. Set the group to **disabled** by default. Add the following three child triggers inside it.

---

#### Child Trigger: `container start`

| Setting | Value |
|---|---|
| Type | Substring (row 1), Perl Regex (row 2) |
| Pattern 1 | `When you look inside, you see:` |
| Pattern 2 | `([A-Za-z ]+) \(carried\) : ` |

**Script:**
```lua
enableTrigger("container contents")
noIdItems = {}
```

---

#### Child Trigger: `container contents`

| Setting | Value |
|---|---|
| Type | Perl Regex |
| Pattern | `(.+)` |
| Starts disabled | No |

**Script:**
```lua
local itemname = matches[2]

if string.find(itemname, "%(carried%)") then
  deleteLine()
  return
end

itemname = string.gsub(itemname, " %(.+%)", "")

if string.find(itemname, "] ") ~= nil then
  itemname = string.sub(itemname, string.find(itemname, "] ") + 2)
end

itemname = itemname:trim()

local search  = (NyyLIB.bagcheck and NyyLIB.bagcheck.search)  or ""
local uselong = (NyyLIB.bagcheck and NyyLIB.bagcheck.uselong) or false

if uselong then
  local results = longIdItem(itemname)
  if #results == 0 then
    if search == "" then
      noIdItems[table.size(noIdItems) + 1] = itemname
    else
      deleteLine()
    end
    return
  end

  local item = results[1]

  if search ~= "" then
    local show = true
    for term in search:lower():gmatch("[^,]+") do
      term = term:trim()
      local neg = false
      if term:sub(1,1) == "-" then neg = true; term = term:sub(2) end
      local found = item.line_lower:find(term, 1, true) ~= nil
      if neg and found      then show = false; break end
      if not neg and not found then show = false; break end
    end
    if not show then deleteLine(); return end
  end

  local raritycolor = "<white>"
  if     item.rarity == "R" then raritycolor = "<yellow>"
  elseif item.rarity == "Q" then raritycolor = "<cyan>"
  elseif item.rarity == "N" then raritycolor = "<green>"
  elseif item.rarity == "I" then raritycolor = "<magenta>"
  end

  cecho("<white>" .. item.fullname)
  if item.slots ~= "" then cecho(" <dark_slate_grey>(" .. item.slots .. ")") end
  if item.stats ~= "" then cecho(" <green>" .. item.stats .. " ") end
  if item.flags ~= "" then
    local flagstr = item.flags
    flagstr = flagstr:gsub("(NO%-%a+)",   "<red>%1<reset>")
    flagstr = flagstr:gsub("(ANTI%-%a+)", "<orange>%1<reset>")
    cecho(flagstr .. " ")
  end
  cecho(raritycolor .. item.location)
  if item.rarity ~= "" then cecho(" (" .. item.rarity .. ")") end
  cecho("<reset>\n")

else
  local itemid = sqliditem(itemname)
  if itemid[1] then
    local statline = itemid[1]
    if search ~= "" then
      local show = true
      for term in search:lower():gmatch("[^,]+") do
        term = term:trim()
        local neg = false
        if term:sub(1,1) == "-" then neg = true; term = term:sub(2) end
        if SEARCH_ALIASES and SEARCH_ALIASES[term] then
          local alias = SEARCH_ALIASES[term]
          if alias:sub(1,1) == "-" then neg = not neg; alias = alias:sub(2) end
          term = alias:lower()
        end
        local found = statline:lower():find(term, 1, true) ~= nil
        if neg and found      then show = false; break end
        if not neg and not found then show = false; break end
      end
      if not show then deleteLine(); return end
    end
    local display_line = string.gsub(statline, itemname, "")
    cecho("<cyan> " .. display_line .. "\n")
  else
    if search == "" then
      noIdItems[table.size(noIdItems) + 1] = itemname
    else
      deleteLine()
    end
  end
end
```

---

#### Child Trigger: `DisableDisplayContainer`

| Setting | Value |
|---|---|
| Type | Perl Regex |
| Pattern | `^<.*>` |

**Script:**
```lua
disableTrigger("DisplayContainer")
disableTrigger("container contents")
enableTrigger("DisplayPotions")
```

---

### Trigger Group: `MobGear`

Create two standalone triggers (not in a group). Both start **disabled**.

---

#### Trigger: `MobGearCapture`

| Setting | Value |
|---|---|
| Type | **Perl Regex** |
| Pattern | `^<([^>]+)>\s+(.+)$` |
| Starts disabled | Yes |

**Script:**
```lua
if not NyyLIB.mobcheck or not NyyLIB.mobcheck.active then return end

-- Arm the end trigger on first gear line
if not NyyLIB.mobcheck.started then
  NyyLIB.mobcheck.started = true
  enableTrigger("MobGearEnd")
end

local slot     = matches[2]:trim()
local itemname = matches[3]:trim()

itemname = itemname:gsub("%s*%(illuminating%)%s*$", "")
itemname = itemname:gsub("%s*%(glowing%)%s*$",      "")
itemname = itemname:gsub("%s*%(x%d+%)%s*$",         "")
itemname = itemname:trim()

local slotcolors = {
  ["worn as a badge"]    = "<dark_slate_grey>",
  ["worn on head"]       = "<yellow>",
  ["worn on eyes"]       = "<cyan>",
  ["worn in ear"]        = "<magenta>",
  ["worn on face"]       = "<green>",
  ["worn around neck"]   = "<orange>",
  ["worn on body"]       = "<white>",
  ["worn about body"]    = "<white>",
  ["worn about waist"]   = "<cyan>",
  ["worn on arms"]       = "<green>",
  ["held as shield"]     = "<yellow>",
  ["worn around wrist"]  = "<magenta>",
  ["worn on hands"]      = "<orange>",
  ["worn on finger"]     = "<cyan>",
  ["primary weapon"]     = "<red>",
  ["secondary weapon"]   = "<red>",
  ["worn on legs"]       = "<green>",
  ["worn on feet"]       = "<yellow>",
  ["component bag"]      = "<dark_slate_grey>",
  ["light source"]       = "<yellow>",
  ["worn on tail"]       = "<magenta>",
  ["worn as insignia"]   = "<dark_slate_grey>",
}

local slotcolor = slotcolors[slot:lower()] or "<white>"
local slotlabel = string.format("%-22s", "<" .. slot .. ">")

local results = longIdItem(itemname)

if #results > 0 then
  local item = results[1]
  local raritycolor = "<white>"
  if     item.rarity == "R" then raritycolor = "<yellow>"
  elseif item.rarity == "Q" then raritycolor = "<cyan>"
  elseif item.rarity == "N" then raritycolor = "<green>"
  elseif item.rarity == "I" then raritycolor = "<magenta>"
  end

  cecho(slotcolor .. slotlabel .. "<reset> ")
  cecho("<white>" .. item.fullname .. " ")
  if item.stats ~= "" then cecho("<green>" .. item.stats .. " ") end
  if item.flags ~= "" then
    local flagstr = item.flags
    flagstr = flagstr:gsub("(NO%-%a+)",   "<red>%1<reset>")
    flagstr = flagstr:gsub("(ANTI%-%a+)", "<orange>%1<reset>")
    cecho(flagstr .. " ")
  end
  cecho(raritycolor .. item.location)
  if item.rarity ~= "" then cecho(" (" .. item.rarity .. ")") end
  cecho("<reset>\n")
else
  cecho(slotcolor .. slotlabel .. "<reset> <dark_slate_grey>" .. itemname .. " <red>(?)\n")
end

deleteLine()
```

---

#### Trigger: `MobGearEnd`

| Setting | Value |
|---|---|
| Type | **Perl Regex** |
| Pattern | `^\<\s*\d+h/\d+H` |
| Starts disabled | Yes |

**Script:**
```lua
if NyyLIB.mobcheck and NyyLIB.mobcheck.active then
  NyyLIB.mobcheck.active  = false
  NyyLIB.mobcheck.started = false
  disableTrigger("MobGearCapture")
  disableTrigger("MobGearEnd")
end
```

---

## Aliases

### Alias: `idb` — Short stat search

| Setting | Value |
|---|---|
| Pattern | `^idb (.+)$` |

**Script:**
```lua
local parts = string.split(matches[2], " ")
searchItems(table.unpack(parts))
```

---

### Alias: `lss` — Long stat search

| Setting | Value |
|---|---|
| Pattern | `^lss (.+)$` |

**Script:**
```lua
longSearch(matches[2], true)
```

---

### Alias: `cid` — Bag inspect (short db)

| Setting | Value |
|---|---|
| Pattern | `^cid (\S+)\s*(.*)$` |

**Script:**
```lua
NyyLIB.bagcheck = NyyLIB.bagcheck or {}
NyyLIB.bagcheck.search  = matches[3] and matches[3]:trim() or ""
NyyLIB.bagcheck.uselong = false

if matches[2] == nil then
  for k,v in pairs(noIdItems) do display(v) end
  return
end

disableTrigger("DisplayPotions")
enableTrigger("DisplayContainer")
mud:send("examine " .. matches[2])
```

---

### Alias: `lbag` — Bag inspect (long db)

| Setting | Value |
|---|---|
| Pattern | `^lbag (\S+)\s*(.*)$` |

**Script:**
```lua
NyyLIB.bagcheck = NyyLIB.bagcheck or {}
NyyLIB.bagcheck.search  = matches[3] and matches[3]:trim() or ""
NyyLIB.bagcheck.uselong = true

disableTrigger("DisplayPotions")
enableTrigger("DisplayContainer")
mud:send("examine " .. matches[2])
```

---

### Alias: `lmob` — Mob/player gear inspect

| Setting | Value |
|---|---|
| Pattern | `^lmob (.+)$` |

**Script:**
```lua
NyyLIB.mobcheck = NyyLIB.mobcheck or {}
NyyLIB.mobcheck.active  = true
NyyLIB.mobcheck.started = false
NyyLIB.mobcheck.target  = matches[2]

disableTrigger("MobGearEnd")
enableTrigger("MobGearCapture")
mud:send("look " .. matches[2])
```

---

## Usage Reference

### `idb` — Short stat keyword search

| Command | Result |
|---|---|
| `idb cleric` | CLERIC-ONLY items |
| `idb cleric healing` | Cleric-only items with HealBon: |
| `idb Hp: -quest` | Hp bonus items, no quest items |
| `idb scroll cleric` | Cleric-only scrolls |

---

### `lss` — Long stat advanced search

| Command | Result |
|---|---|
| `lss SF-Heal:` | All items with SF-Heal |
| `lss slot:FINGER,Hp:` | Finger slot items with Hp |
| `lss type:WEAPON,NO-MAGE` | Weapons mages can't use |
| `lss slot:WRIST,-NO-CLERIC` | Wrist items clerics CAN use |
| `lss flag:ANTI-GOOD,slot:BODY` | Anti-good body armor |
| `lss loc:Bahamut,rare:R` | Rare drops from Bahamut |
| `lss PRIEST-ONLY,SF-Heal:` | Priest-only SF-Heal gear |
| `lss key:bag,slot:HOLD` | Items with "bag" in keyword, HOLD slot |

**Prefix operators for `lss`:**

| Prefix | Targets |
|---|---|
| `slot:FINGER` | Wear slot |
| `type:WEAPON` | Item type |
| `flag:ANTI-GOOD` | Flags field only |
| `loc:Bahamut` | Location name |
| `rare:R` | Rarity code (R/Q/N/I/S/C) |
| `key:bag` | Keywords field only |
| `date:2025` | Date stamp |
| `-term` | Must NOT contain term |

---

### `cid` — Bag inspect (short db)

| Command | Result |
|---|---|
| `cid silk` | Full contents with stats |
| `cid silk potion` | Only potions |
| `cid silk cleric` | Only CLERIC-ONLY items |
| `cid pack Hp:` | Items with Hp bonus |
| `cid pack scroll,-quest` | Scrolls that aren't quest items |

---

### `lbag` — Bag inspect (long db, richer color)

Same syntax as `cid` but uses long_stats.txt with slot/flag coloring.

| Command | Result |
|---|---|
| `lbag cube sf-heal:` | SF-Heal items in cube |
| `lbag cube slot:WIELD` | Weapons only |
| `lbag cube rare:R` | Rare items only |

---

### `lmob` — Mob or player gear inspect

| Command | Result |
|---|---|
| `lmob me` | Your own gear with stats |
| `lmob fokle` | Fokle's gear with stats |
| `lmob guard` | Guard's gear with stats |

Items not found in the database show with a red `(?)`. Slot labels are color-coded by slot type.

---

## Rarity Color Key

| Color | Code | Meaning |
|---|---|---|
| Yellow | R | Rare |
| Cyan | Q | Quest |
| Green | N | Normal |
| Magenta | I | Infrequent |
