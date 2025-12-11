-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external Scripts --
-------------------------------------------------

-- Initialize item cache
NyyLIB = NyyLIB or {}
NyyLIB.itemcache = NyyLIB.itemcache or {}
NyyLIB.itemdb = NyyLIB.itemdb or {}

-------------------------------------------------------
-- ITEM DATABASE LOADER (replaces SQL for items)
-------------------------------------------------------

function loadItemDatabase()
  -- Load items from short_stats.txt into memory
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
      -- Extract item name (everything before the first parenthesis)
      local itemname = line:match("^([^%(]+)")
      if itemname then
        itemname = itemname:trim()
        
        table.insert(NyyLIB.itemcache, {
          name = itemname,
          name_lower = itemname:lower(),
          stats = line,
          stats_lower = line:lower()
        })
        count = count + 1
      end
    end
  end
  
  file:close()
  cecho("<green>[Loaded " .. count .. " items from text database]\n")
  return true
end

-------------------------------------------------------
-- DROP-IN REPLACEMENT FUNCTIONS (same signatures as SQL)
-------------------------------------------------------

function sqliditem(xitemname)
  -- DROP-IN REPLACEMENT for SQL version
  -- Returns array of stat lines matching item name
  
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    cecho("<red>[Item cache not loaded! Run loadItemDatabase()]\n")
    return {}
  end
  
  -- remove trailing (poisoned) from name  
  xitemname = string.gsub(xitemname, "%(poisoned%)", "")
  xitemname = xitemname:trim()
  
  local searchterm = xitemname:lower()
  local retval = {}
  
  -- Search through cache
  for i, item in ipairs(NyyLIB.itemcache) do
    if string.find(item.name_lower, searchterm, 1, true) then
      table.insert(retval, item.stats)
    end
  end
  
  return retval
end

function sqlshortstats(xsqlstring)
  -- DROP-IN REPLACEMENT for SQL version
  -- Search by stat criteria (supports AND and NOT logic)
  
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    cecho("<red>[Item cache not loaded!]\n")
    return {}
  end
  
  local sqlitems = xsqlstring:split(",")
  
  for nx = 1, #sqlitems, 1 do
    sqlitems[nx] = sqlitems[nx]:trim()
  end
  
  local retval = {}
  
  -- Build search criteria
  local positive_terms = {}
  local negative_terms = {}
  
  for nx = 1, #sqlitems, 1 do
    if sqlitems[nx]:sub(1,1) == "-" then
      table.insert(negative_terms, sqlitems[nx]:sub(2):lower())
    else
      table.insert(positive_terms, sqlitems[nx]:lower())
    end
  end
  
  -- Search through items
  for i, item in ipairs(NyyLIB.itemcache) do
    local match = true
    
    -- Check all positive terms must exist
    for _, term in ipairs(positive_terms) do
      if not string.find(item.stats_lower, term, 1, true) then
        match = false
        break
      end
    end
    
    -- Check all negative terms must NOT exist
    if match then
      for _, term in ipairs(negative_terms) do
        if string.find(item.stats_lower, term, 1, true) then
          match = false
          break
        end
      end
    end
    
    if match then
      table.insert(retval, item.stats)
    end
  end
  
  return retval
end

function sqlIsWeapon(xitemname)
  -- DROP-IN REPLACEMENT for SQL version
  -- Find weapons matching name
  
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    return {}
  end
  
  local searchterm = xitemname:lower()
  local retval = {}
  
  for i, item in ipairs(NyyLIB.itemcache) do
    local stats_lower = item.stats_lower
    
    -- Check if it's a weapon (contains WIELD and has damage dice like 4D6)
    if string.find(item.name_lower, searchterm, 1, true) then
      if string.find(stats_lower, "wield") and string.find(stats_lower, "%d+d%d+") then
        table.insert(retval, item.stats)
      end
    end
  end
  
  return retval
end

function sqlIsBow(xitemname)
  -- DROP-IN REPLACEMENT for SQL version
  -- Find ranged weapons (bows) matching name
  
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    return {}
  end
  
  local searchterm = xitemname:lower()
  local retval = {}
  
  for i, item in ipairs(NyyLIB.itemcache) do
    -- Look for ranged weapon indicators (Type:Bow, crossbow, etc)
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
  -- DROP-IN REPLACEMENT for SQL version
  -- Find 2-handed weapons matching name
  
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    return {}
  end
  
  local searchterm = xitemname:lower()
  local retval = {}
  
  for i, item in ipairs(NyyLIB.itemcache) do
    if string.find(item.name_lower, searchterm, 1, true) then
      -- Look for "WIELD 2H" or "two_hand" or similar 2H indicators
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
  -- DROP-IN REPLACEMENT for SQL version
  -- Returns array of item names (not full stats)
  
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    return {}
  end
  
  local searchterm = xitemname:lower()
  local retval = {}
  
  for i, item in ipairs(NyyLIB.itemcache) do
    if string.find(item.name_lower, searchterm, 1, true) then
      display(i)  -- mimics the rowid display
      display(item.name)
      table.insert(retval, item.name)
    end
  end
  
  return retval
end

function createconsumabledb()
  -- DROP-IN REPLACEMENT for SQL version
  -- Cache potions, scrolls, and poisons
  
  if not NyyLIB.itemcache or #NyyLIB.itemcache == 0 then
    cecho("<red>[Item cache not loaded! Cannot create consumable DB]\n")
    return
  end
  
  NyyLIB.itemdb = {}
  
  for i, item in ipairs(NyyLIB.itemcache) do
    local stats = item.stats
    
    -- Check for potions
    if string.find(stats, "%(Potion%) ") then
      local st, en, retval = string.find(stats, "%(Potion%)([A-Za-z0-9: -]+)%*")
      if retval then
        NyyLIB.itemdb[item.name] = {"potion", retval:trim()}
      end
    end
    
    -- Check for scrolls
    if string.find(stats, "%(Scroll%) ") then
      local st, en, retval = string.find(stats, "%(Scroll%)([A-Za-z0-9: -]+)%*")
      if retval then
        NyyLIB.itemdb[item.name] = {"scroll", retval:trim()}
      end
    end
    
    -- Check for poisons
    if string.find(stats, "%(Poison%) ") then
      local st, en, retval = string.find(stats, "%(Poison%)([A-Za-z0-9: -]+)%*")
      if retval then
        NyyLIB.itemdb[item.name] = {"poison", retval:trim()}
      end
    end
  end
  
  cecho("<red>[Consumable database cached: Potions, Scrolls, Poisons]\n")
end

-------------------------------------------------------
-- CHARACTER DATABASE FUNCTIONS (still use SQL)
-------------------------------------------------------

function sqlOpen()
  NyyLIB.env = assert (luasql.sqlite3())
  
  NyyLIB.conn = assert (NyyLIB.env:connect(mainpath("toril.db")))

  local recs, row

  -- cache chars table
  recs = assert(NyyLIB.conn:execute([[SELECT * FROM chars  ]]))

  row = recs:fetch({})

  while row do
    row= recs:fetch({})
  end

  recs:close()

  -- Load text-based item database instead of SQL items
  loadItemDatabase()
end

function sqlinwho(xname)
  local recs, row
  local profilename

  recs = assert(NyyLIB.conn:execute([[SELECT class_name, char_race, account_name FROM chars WHERE char_name = ']] .. xname .. [[']]))

  row = recs:fetch({})

  recs:close()
  
  if row == nil then
    return(false)
  else
    for k, v in pairs(NyyLIB.fullclasslist) do
      if v[1] == row[1]:trim()   then
        whoadd(xname, v[2], row[2], row[3])
        profilename = row[3]
        --echo("\n[Adding - " .. xname .. " " .. v[2] .. " " .. row[2] .. "]\n")
      end
    end

    return(profilename)
  end
end

function sqlprofilename(xname)
  local recs, row

  recs = assert(NyyLIB.conn:execute([[SELECT class_name, char_race, account_name FROM chars WHERE char_name = ']] .. xname .. [[']]))

  row = recs:fetch({})

  recs:close()
  
  if row == nil then
    --echo(" [Not found in database]\n")
    return(false)
  else
    return(row[3])
  end
end

function sqlclist(xname)
  local recs, row

  local retval = {}

  recs = assert(NyyLIB.conn:execute([[
        SELECT char_name, class_name, char_race, char_level, account_name FROM 
        chars WHERE vis = 't' AND (account_name = (SELECT account_name 
        FROM chars WHERE LOWER(char_name) = LOWER(']] .. xname .. [[') AND vis = 't') OR 
        LOWER(account_name) = LOWER(']] .. xname .. [[')) ORDER BY char_level DESC, 
        char_name ASC]]))

  row = recs:fetch({})

  while row do
    retval[#retval+1] = {row[4], row[2], row[1], row[3], row[5]}
    row= recs:fetch({})
  end

  recs:close()

  return(retval)
end

function sqlwhoclass(xname)
  display(NyyLIB.conn)

  recs = assert(NyyLIB.conn:execute([[SELECT class_name FROM chars WHERE char_name LIKE ']] .. xname .. [[']]))

  row = recs:fetch({})

  while row do
  
    echo ( row[1] .. "\n")
    row = recs:fetch({})
  end

  recs:close()

end

-------------------------------------------------------
-- AUTO-INITIALIZE ON LOAD
-------------------------------------------------------

-- If sqlOpen hasn't been called yet, just load items
if not NyyLIB.conn then
  loadItemDatabase()
end
