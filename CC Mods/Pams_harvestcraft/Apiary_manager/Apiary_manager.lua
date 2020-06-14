--[[
Apiary Manager by creeperGoBoom for "Pams harvestcraft" mod.
Can handle multiple apiaries into one chest or vice versa.
Custom chest types can be added in where chests and apiaries are defined.

listPeripheralsByName used so Iron chests supported. 
Along with anything that contains "chest" or "shulker" in the tooltip.

-Process process process! Can use multiple pressers to process any honeycombs / waxcombs (if connected)

On the fly configuration available.
]]


--Returns a table of all peripherals containing "x","y","z"
--Allows for (storage = listPeripheralsByName("chest","shulker")
--Peripherals cannot be on sides.
function listPeripheralsByName(...)
  local temp = {}
  local peripherals = peripheral.getNames()
  for k , v in pairs({...}) do
    for _ , name in pairs(peripherals) do
      if name:find(v) then
        table.insert(temp,name)
      end
    end
  end
  return temp
end

apiaries = listPeripheralsByName("apiary")
chests = listPeripheralsByName("chest","shulker")
pressers = listPeripheralsByName("presser")
fileName = "apiary_manager.txt"
presserConnected = false
if pressers[1] then 
  presserConnected = true 
end

if not fs.exists(fileName) then
  local f=fs.open(fileName,"w")
  f.close()
end

term.clear()
term.setCursorPos(1,1)
print("Apiary Manager V1.2")

local function main()
  while true do
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
  end
end

--Is stringName in tableCheck?
function isInList(stringName,tableCheck)
  for id, check in pairs(tableCheck) do
    if stringName == check then
      return true,id
    end
  end
  return false
end

local function secondary()
  while true do
    _, p = os.pullEvent("peripheral")
    if (p:find("chest") or p:find("shulker")) then
      ok, id = isInList(p,chests)
      if not ok then
        table.insert(chests,p)
      else
        table.remove(chests,id)
      end
    elseif p:find("apiary") then
      ok, id = isInList(p,apiaries)
      if not ok then
        table.insert(apiaries,p)
      else
        table.remove(apiaries,id)
      end
    elseif p:find("presser") then
      ok, id = isInList(p,pressers)
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