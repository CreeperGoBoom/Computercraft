--[[
NAFA - Not another Furnace Automater by CreeperGoBoom
This program works in 3 simple steps.
1. Network your chests and furnaces up.
2. Install this program onto a networked computer.
3. Add / remove chests, shulkers, furnaces as desired.

Alternatively you could set this up first and it will detect all new chests and furnaces as you set up.

To reconfigure chest / furnace layout:
Simply add and remove furnaces and chests as required.

BUGFIXES:
-Fixed furnaces crashing script due to disconnect bug. 
-Note: Now each furnace that disconnects is removed and then readded to furnace list.
-Fixed Fuels and ingredients being sent randomly in multiples, this meant that not all furnaces were put to use.
-Fixed system requiring extra fuel in chests in order to extract output.

FEATURES:
-Only runs to fuel avilability. if there are 40 furnaces but only enough fuel to run 5, it will only send ingredients to 5 furnaces until there is more fuel made avilable.
-Now runs in parallel, additional event features now possible.
-Feeds fuel and ingredients based on vars below.
-For example, if a furnace runs out of fuel. it will then send fuel at the fuel rate specified 
 and wait for the furnace to run out before refueling.
-Plethora optimized.
-Fuel and ingredient rates shown on main screen.
-On the fly configuration, just add and remove furnaces, chests, shulkers etc as desired.
-Works with anything containing "chest" or "shulker" in the name, this means that iron chest mod chests and shulker boxes will work without any interaction. Add your own custom names below.
-Also works with anything containing "furnace" or custom
-Works with anything containing "_ore" in the tooltip. This should mean that this allows processing of Nether Ore mod ores.
NOTE: Please keep in mind that for Tinkers Construct. Not all ores can be processed.
So please consult your furnace recipe list (NEI, JEI, etc) before inserting any ores into a NAFA controlled storage device as this can block up your furnaces.

To Do:
-Purge Mode
-Auto ingredient rate detection based on fuel
]]

--VARS
local version = "V1.4"
local furnaceFuelRate = 1  --How much fuel will be placed into the furnaces when empty?
local furnaceIngredientsRate = 8  --How many ingredients to send to furnaces at one time?
local ingredients = {
  "minecraft:cobblestone", 
  "minecraft:sand", 
  "_ore", 
  "log", 
}

local fuels = {
  "coal", 
  --"minecraft:sapling",
}
local idprint = false   --saves all item data from chests into file idprint.lua

--Enter all custom chest names here
--Checked against chest names eg: 'minecraft:chest'
local storageTypes = {
  "chest",
  "shulker",
  --"box",
  --"storage",
  --"crate",
}

--Enter all custom furnaces here.
--Should work with Thermal Expansion right away.
local furnaceTypes = {
  "furnace",
  
}

local requiredAPIFuncs = {
  "saveConfig",
  "colorPrint",
  "listPeripheralsByName",
  }

local function httpGet(stringURL, stringFileNameToSaveTo)
  local h, err = http.get(stringURL)
  if not h then printError(err) return nil end
  local f = fs.open(stringFileNameToSaveTo, "w")
  f.write(h.readAll())
  f.close()
  h.close()
  return true
end

if not fs.exists("apis/CGBCoreLib.lua") then
  if not httpGet("https://pastebin.com/raw/xuMVS2GP", "apis/CGBCoreLib.lua") then
    error("Error: Dependancy 'CGBCoreLib' could not be downloaded. Please connect your internet and restart")
  end
end

require("apis/CGBCoreLib") --Contains complete function library used accross multiple programs and to minimize code size.

for _ , func in pairs(requiredAPIFuncs) do --For API checking to ensure not outdated
  if not CGBCoreLib[func] then
    if not httpGet("https://pastebin.com/raw/xuMVS2GP", "apis/CGBCoreLib.lua") then
      error("Error: Your version of CGBCoreLib is outdated! Please connect your internet and restart!")
    else
      os.reboot()
    end
  end
end

if not fs.exists("NAFA.txt") then
  f = fs.open("NAFA.txt","w")
  f.close()
end

local furnaces
local chests
local shulkers
local storage
local data = {}
local debug = {}

local function getItemList(chestName)
  local meta = peripheral.call(chestName,"list")
  return meta
end

local function getChestInfo()
  local meta = {}
  for key, val in pairs(storage) do
    meta.chestName = val.name
    meta[val] = getItemList(val)
  end
  if idprint then 
    local sData = textutils.serialize(meta)
    CGBCoreLib.fileWrite("data/idprint.lua", sData) 
  end
  CGBCoreLib.saveConfig("data.lua",meta)
  return meta
end

local purgeMode = false


local function main()
  while true do
    term.clear()
    term.setCursorPos(1, 1)
    CGBCoreLib.colorPrint("orange","NAFA " .. version .. " (Not Another Furnace Automater)")
    --Recompile all chests and furnaces for this new cycle. 
    --This allows chests and furnaces to be added on the fly.
    --Should also make all furnaces available most of the time.
    furnaces = CGBCoreLib.listPeripheralsByName(table.unpack(furnaceTypes))
    storage = CGBCoreLib.listPeripheralsByName(table.unpack(storageTypes))
    CGBCoreLib.saveConfig("storage.lua",storage)
    --Get item info from all storage.
    data = getChestInfo()
    --Statuses
    if not storage[1] then
      CGBCoreLib.colorPrint("red","STATUS: No Storage found!")
      sleep(5)
    elseif not furnaces[1] then
      CGBCoreLib.colorPrint("red","STATUS: No Furnaces found!")
      sleep(5)
    elseif storage[1] and furnaces[1] then
      CGBCoreLib.colorPrint("green","STATUS: OK!")
      CGBCoreLib.colorPrint("green","Fuel rate: " .. furnaceFuelRate .. " per refuel.")
      CGBCoreLib.colorPrint("green","Ingredient rate: " .. furnaceIngredientsRate .. " per refill.")
    end
    
    --Purge needs to take over program without losing peripheral handling.
    while purgeMode do
      local status
      local key
      print("Note: This will purge all furnaces of ingredients and fuel, would you like to continue? Y N")
      key = CGBCoreLib.getKeyPressYN()
      if key == keys.y then
        print("Purging, please wait")
        print("Complete: ")
        for furnaceID, furnace in pairs(furnaces) do
          local ok,furnaceList = pcall(peripheral.call,furnace,"list")
          for _, chest in pairs(storage) do
            for slot,item in pairs(furnaceList) do
              peripheral.call(furnace,"pushItems",chest,slot)
            end
            status = math.floor((furnaceID / #furnaces) * 100)
            posx, posy = term.getCursorPos()
            term.clearLine(posy - 1)
            term.setCursorPos(1, posy - 1)
            print("Complete: %" .. status)
          end
        end
        print("Done, Please check your chests, remove any unwanted items and then come back here and press any key to resume NAFA")
        os.pullEvent("key")
        purgeMode = false
      elseif key == keys.n then
        purgeMode = false
      end
    end
    
    --Main operation code
    local count={
      fuel = 1,
      ingredients = 1,
    }
    if furnaces[1] and storage[1] then
      --Clear processing list for new cycle
      local processList={
        fuels = {},
        ingredients={}
      }
      --Write list for this cycle
      for chestName , chestContents in pairs(data) do --Check each chest and
        for slot , item in pairs(chestContents) do --process each slot
          for _ , fuel in pairs(fuels) do
            if item.name:find(fuel) then
              processList.fuels[count.fuel]={}
              processList.fuels[count.fuel].chestName=chestName
              processList.fuels[count.fuel].slot=slot
              count.fuel = count.fuel + 1
            end
          end
          for _ , ingredient in pairs(ingredients) do
            if item.name:find(ingredient) then
              processList.ingredients[count.ingredients]={}
              processList.ingredients[count.ingredients].chestName=chestName
              processList.ingredients[count.ingredients].slot=slot
              count.ingredients = count.ingredients + 1
            end
          end
        end
      end
      --List created. Process what can be processed this cycle.
      for furnaceNum , furnace in pairs(furnaces) do 
        --For each furnace
        --Ensure operation cycle a success.\/
        local success  = pcall(function ()   
          furnaceContents = peripheral.call(furnace, "list")
          --[[Basic order of operation here:
                  1.Check if theres any output to push to chests.
                  No point checking fuel levels or ingredients if furnace output is full.
                  This allows other furnaces to be used in this case.
                  
                  2.Check fuel.
                  Refuel if needed.
                  
                  3.Check that ingredients slot is empty.
              Send new lot of ingredients as per vars at top.]]
          if furnaceContents[3] and furnaceContents[3].count then --only pushes items out if theres something there else it wont call it, makes it more plethora friendly.
            -- If there is output available then attempt push to each chest until push successful. No point processing any more if chests are full.
            for i = 1, #storage do
              if pcall(peripheral.call,furnace, "pushItems", storage[i], 3, furnaceContents[3].count) then
                break
              end
            end
          -- Refuel
          elseif not (furnaceContents[2] and furnaceContents[2].count) then
            for i = 1, #processList.fuels do
              if pcall(peripheral.call,processList.fuels[i].chestName, "pushItems", furnace, processList.fuels[i].slot, furnaceFuelRate, 2) then
                break 
              end
            end
          -- Refill ingredients
          elseif not (furnaceContents[1] and furnaceContents[1].count) then
            for i = 1, #processList.ingredients do
              if pcall(peripheral.call,processList.ingredients[i].chestName, "pushItems", furnace, processList.ingredients[i].slot, furnaceIngredientsRate, 1) then
                break 
              end
            end
          end
        
        end)
        --Else remove problem furnace from furnace list. Disconnect catcher below should handle readding (partially).
        if not success then
          table.remove(furnaces, furnaceNum)
        end
      end
      --end
    end
    CGBCoreLib.saveConfig("debug.lua",debug)
  end
end

local function secondary()
  -- Furnace disconnect catcher
  -- Removes problem furnace and readds it as soon as it becomes available again. 
  -- This allows furnaces to be added / removed on the fly.
  local x = 10 -- interval in seconds
  local tmr = os.startTimer(x)
  while true do
    local event = {os.pullEvent()}
    if event[1] == "timer" and event[2] == tmr then
      os.queueEvent("runmain") -- tell main func to run
      tmr = os.startTimer(x)
    elseif event[1] == "peripheral_detach" then
      for k , v in pairs(furnaces) do
        if v == event[2] then
          table.remove(furnaces, k)
          break
        end
      end
    elseif event[1] == "peripheral" then
      if peripheral.getType(event[2]) == "furnace" then
        table.insert(furnaces, #furnaces + 1, event[2])
      end
    elseif event[1] == "key" and event[2] == keys.p then
      purgeMode = true
      --Make purge mode immediately available by forcing parallel to restart
      return
    end
  end
end


while true do
  parallel.waitForAny(main, secondary)
end