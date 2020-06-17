--[[
Apiary Manager by creeperGoBoom for "Pams harvestcraft" mod.
Can handle multiple apiaries into one chest or vice versa.
Custom chest types can be added in where chests and apiaries are defined.

listPeripheralsByName used so Iron chests supported. 
Along with anything that contains "chest" or "shulker" in the tooltip.

-Process process process! Can use multiple pressers to process any honeycombs / waxcombs (if connected)

On the fly configuration available.

Will move bees out of apiaries when chest becomes too full.
This is done by reserving slots calculated by number of apiaries + ((pressers x 2) (if connected))
This allows pressers to finish as so there is no huge surprise when room is made in storage or storage upgraded.
]]

local function httpGet(stringURL, stringFileNameToSaveTo)
  local h, err = http.get(stringURL)
  if not h then printError(err) return nil end
  local f = fs.open(stringFileNameToSaveTo, "w")
  f.write(h.readAll())
  f.close()
  h.close()
  return true
end

--Get API if don't already have
if not fs.exists("apis/CGBCoreLib.lua") then
  if not httpGet("https://raw.githubusercontent.com/CreeperGoBoom/Computercraft/Latest/apis/CGBCoreLib.lua", "apis/CGBCoreLib.lua") then
    error("Error: Dependancy 'CGBCoreLib' could not be downloaded. Please connect your internet and restart")
  end
end

require("apis/CGBCoreLib") --Contains complete function library used accross multiple programs and to minimize code size.

--For API check
local requiredAPIFuncs = {
  "isInList",
  "listPeripheralsByName",
  "getNetworkStorage",
  }

--Check API to ensure not outdated
for _ , func in pairs(requiredAPIFuncs) do 
  if not CGBCoreLib[func] then
    if not httpGet("https://raw.githubusercontent.com/CreeperGoBoom/Computercraft/Latest/apis/CGBCoreLib.lua", "apis/CGBCoreLib.lua") then
      error("Error: Your version of CGBCoreLib is outdated! Please connect your internet and restart!")
    else
      os.reboot()
    end
  end
end

apiaries = CGBCoreLib.listPeripheralsByName("apiary")
chests = CGBCoreLib.listPeripheralsByName("chest","shulker")
pressers = CGBCoreLib.listPeripheralsByName("presser")
fileName = "apiary_manager.txt"
presserConnected = false
if pressers[1] then 
  presserConnected = true 
end

term.clear()
term.setCursorPos(1,1)
print("Apiary Manager V1.2")

local killSwitch = false

local function main()
  while true do
    local chestData = CGBCoreLib.getNetworkStorage("chest","shulker")
    local slotsToReserve = #apiaries + ((#pressers * 2) or 0)
    if (killSwitch == true) and (chestData.freeSlots > slotsToReserve) then
      --There is more room, put the bees back
      --Make a list first
      print("returning bees")
      local beeLocations = {}
      for _, chest in pairs(chests) do
        for slot, item in pairs(peripheral.call(chest,"list")) do
          if item.name == "harvestcraft:queenbeeitem" then
            if not beeLocations[chest] then 
              beeLocations[chest] = {}
            end
            table.insert(beeLocations[chest],slot)
          end
        end
      end
      --lets now go through that list and put back the bees
      for _, apiary in pairs(apiaries) do
        for chest, chestData in pairs(beeLocations) do
          for _,slot in pairs(chestData) do
            if pcall(peripheral.call,chest,"pushItems",apiary,slot,1,19) then
              break
            end
          end
        end
      end
      killSwitch=false
    --Only work if there is enough room in chests still
    elseif (chestData.freeSlots > slotsToReserve) and (not killSwitch) then 
      for _, apiary in pairs(apiaries) do --For each apiary
        for slot, item in pairs(peripheral.call(apiary,"list")) do --process by list
          for _, chest in pairs(chests) do --into each chest
            if slot ~= 19 and item.name == "harvestcraft:queenbeeitem" then
              --Move new queen to input slot of current apiary and move to next apiary
              if pcall(peripheral.call,apiary,"pushItems","self",slot,item.count,19) then
                break
              end
            elseif item.name ~= "harvestcraft:queenbeeitem" then
                --move everything else to chest
              if not pcall(peripheral.call,apiary,"pushItems",chest,slot) then
                --Chest must be full so skip to next chest,
                break
              end
            end
            if presserConnected then
              for presserID, presser in pairs(pressers) do
                for cslot, citem in pairs(peripheral.call(chest,"list")) do
                  if citem.name:find("comb") then
                    if pcall(peripheral.call,chest,"pushItems",presser,cslot,citem.count,1) then
                      break
                    end
                  end
                end
                for pslot,pitem in pairs(peripheral.call(presser,"list")) do
                  if (pslot ~= 1) and (pitem.count > 0) then
                    for _, chestName in pairs(chests) do
                      if pcall(peripheral.call,presser,"pushItems",chestName,pslot,pitem.count) then
                        break
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    elseif (chestData.freeSlots <= slotsToReserve) and (not killSwitch) then
      --Move the bees out of the apiaries as there is now only enough storage space for the bees to be saved and the pressers to finish.
      for _, apiary in pairs(apiaries) do --For each apiary
        for _, chest in pairs(chests) do
          if pcall(peripheral.call,apiary,"pushItems",chest,19) then
            break
          end
        end
      end
      killSwitch = true
    end
    sleep(10)
  end
end

local function secondary()
  while true do
    _, p = os.pullEvent("peripheral")
    if (p:find("chest") or p:find("shulker")) then
      ok, id = CGBCoreLib.isInList(p,chests)
      if not ok then
        table.insert(chests,p)
      else
        table.remove(chests,id)
      end
    elseif p:find("apiary") then
      ok, id = CGBCoreLib.isInList(p,apiaries)
      if not ok then
        table.insert(apiaries,p)
      else
        table.remove(apiaries,id)
      end
    elseif p:find("presser") then
      ok, id = CGBCoreLib.isInList(p,pressers)
      if not ok then
        table.insert(pressers,p)
        if pressers[1] then
          presserConnected = true
        end
      else
        table.remove(pressers,id)
        if not pressers[1] then
          presserConnected = false
        end
      end
    end
  end
end

while true do
  parallel.waitForAny(main,secondary)
end