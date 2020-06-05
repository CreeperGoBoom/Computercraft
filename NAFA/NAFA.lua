--[[
NAFA - Not another Furnace Automater by CreeperGoBoom
This program works in 2 simple steps.
1. Network your chests and furnaces up.
2. Install this program onto a networked computer.

Alternatively you could set this up first and it will detect all new chests and furnaces as you set up.

To reconfigure chest / furnace layout:
Simply add and remove furnaces ((Coming soon!) and chests) as required.

BUGFIXES:
-Fixed furnaces crashing script due to disconnect bug. 
-Note: Now each furnace that disconnects is removed and then readded to furnace list.

TODO:
-Chest readding and checking like furnaces.
-Table to keep track of peripheral types.
-Shulker boxes.

FEATURES:
-Now runs in parallel, additional event features now possible.
-Now feeds fuel and ingredients based on vars below.
-For example, if a furnace runs out of fuel. it will then send fuel at the fuel rate specified 
 and wait for the furnace to run out before refueling.
-Plethora optimized.
-Fuel and ingredient rates shown on main screen.
]]

--VARS
local furnaceFuelRate = 1  --How much fuel will be placed into the furnaces when empty?
local furnaceIngredientsRate = 8  --How many ingredients to send to furnaces at one time?
local ingredients = {"minecraft:cobblestone", "minecraft:sand", "minecraft:iron_ore", "minecraft:gold_ore", "minecraft:log" }
local fuels = {"minecraft:coal", "minecraft:sapling"}
local idprint = false   --saves all item data from chests into file idprint.lua

local requiredAPIFuncs = {
  "fileWrite",
  "saveConfig",
  "colorPrint",
  "getPeripherals",
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

-- local function getStorage(...)
  -- local temp = {}
  -- local temp2 = {}
  -- local count = 1
  -- local peripherals = peripheral.getNames()
  -- for k , v in pairs({...}) do
    -- for _ , name in pairs(peripherals) do
      -- if name:find(v) then
        -- table.insert(temp,name)
      -- end
    -- end
  -- end
  -- return temp
-- end
    

local function main()
  while true do
    term.clear()
    term.setCursorPos(1, 1)
    CGBCoreLib.colorPrint("orange","NAFA V1.2 (Not Another Furnace Automater)")
    furnaces = CGBCoreLib.listPeripheralsByName("furnace")
    storage = CGBCoreLib.listPeripheralsByName("chest","shulker")
    CGBCoreLib.saveConfig("storage.lua",storage)
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

    --[[
    Need to check each item in each chest,
    Then build an item list of processable items.
    possibly in format of:
    {
      [num]= {
        chestNetworkName="",
        slot=0,
      }
    }
    Then process each item using a for in loop first checking the furnace to send to.
    Removing items from list as processed. 
    --Keeping track of [num]. or
    --List gets refreshed every "cycle"
    Building a seperate list of items in furnaces as sent to furnaces as to only check those furnaces for output.
    Need to also save/load each list to file to stop uneccessary checks etc.
    This in turn should make it more plethora friendly as well as remove the odd multiplying behavior encountered simply because currently the code simply isn't working how I think it will. 
    After close inspection of odd behaviour, I realize it is doing exactly as I coded it.
    
    Right now this code needs redoing as above.
    
    Also need to bring up the coreLib usage to current and update any func calls etc
    ]]
    --Main operation code
    local count={
      fuel = 1,
      ingredients = 1,
    }
    if furnaces[1] and storage[1] then
      local processList={
        fuels = {},
        ingredients={}
      } --Clear processing list for new "cycle"
      for chestName , chestContents in pairs(data) do --Check each chest and
        for slot , item in pairs(chestContents) do --process each slot
          for _ , fuel in pairs(fuels) do
            if item.name == fuel then
              --table.insert(debug,furnace .. " received " .. furnaceFuelRate .. " fuel from " .. chestName)
              processList.fuels[count.fuel]={}
              processList.fuels[count.fuel].chestName=chestName
              processList.fuels[count.fuel].slot=slot
              count.fuel = count.fuel + 1
            end
          end
          for _ , ingredient in pairs(ingredients) do
            if item.name == ingredient then
              --table.insert(debug,furnace .. " received " .. furnaceIngredientsRate .. " " .. item.name .. " from " .. chestName)
              processList.ingredients[count.ingredients]={}
              processList.ingredients[count.ingredients].chestName=chestName
              processList.ingredients[count.ingredients].slot=slot
              count.ingredients = count.ingredients + 1
            end
          end
        end
      end
      --for chestNum , chest in pairs(storage) do
      --for f = 1, #furnaces do
      for furnaceNum , furnace in pairs(furnaces) do --For each furnace
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
            for i = 1, #storage do
              if pcall(peripheral.call,furnace, "pushItems", storage[i], 3, furnaceContents[3].count) then
                break
              end
            end
          elseif not (furnaceContents[2] and furnaceContents[2].count) then -- Refuel
            for i = 1, #processList.fuels do
              if pcall(peripheral.call,processList.fuels[i].chestName, "pushItems", furnace, processList.fuels[i].slot, furnaceFuelRate, 2) then
                break 
              end
            end
          elseif not (furnaceContents[1] and furnaceContents[1].count) then -- Refill ingredients
            for i = 1, #processList.ingredients do
              if pcall(peripheral.call,processList.ingredients[i].chestName, "pushItems", furnace, processList.ingredients[i].slot, furnaceIngredientsRate, 1) then
                break 
              end
            end
          end
        
        end)
        if not success then
          print(furnaceNum)
          table.remove(furnaces, furnaceNum)
        end
      end
      --end
    end
    CGBCoreLib.saveConfig("debug.lua",debug)
  end
end

local function secondary()
  local x = 10 -- interval in seconds
  local tmr = os.startTimer(x)
  while true do
    local event = {os.pullEvent()}
    if event[1] == "timer" and event[2] == tmr then
      os.queueEvent("runmain") -- tell maim func to run
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
    end
  end
end


while true do
  parallel.waitForAny(main, secondary)
end