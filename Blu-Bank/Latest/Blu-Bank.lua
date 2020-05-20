--[[
Blu-Bank(server) / ATM(client) code

By CreeperGoBoom]]

local tArgs = {...}


--VARS
local version = "V1.0"
local range = 2
local newAccAmount = 10000  --How much to start players off with on their first use
local currency= {}
local exchangeWindow
local greetingWindow

local blacklistNames= {
  "Creeper",
  "Skeleton",
  "Spider",
  "Enderman",
  "Chicken",
  "Cow",
  "Spider",
  "Slime",
  "Villager",
  "Bee",
  "Wolf",
  "Ocelot",
  "Squid"
  }
  
local keysraw = {
  {
    ["a"] = 30,
  },
  {
    ["b"] = 48,
  },
  {
    ["c"] = 46,
  },
  {
    ["d"] = 32,
  },
  {
    ["e"] = 18,
  },
  {
    ["f"] = 33,
  },
  {
    ["g"] = 34,
  },
  {
    ["h"] = 35,
  },
  {
    ["i"] = 23,
  },
  {
    ["j"] = 36,
  },
  {
    ["k"] = 37,
  },
  {
    ["l"] = 38,
  },
  {
    ["m"] = 50,
  },
  {
    ["n"] = 49,
  },
  {
    ["o"] = 24,
  },
  {
    ["p"] = 25,
  },
  {
    ["q"] = 16,
  },
  {
    ["r"] = 19,
  },
  {
    ["s"] = 31,
  },
  {
    ["t"] = 20,
  },
  {
    ["u"] = 22,
  },
  {
    ["v"] = 47,
  },
  {
    ["w"] = 17,
  },
  {
    ["x"] = 45,
  },
  {
    ["y"] = 21,
  },
  {
    ["z"] = 44,
  },
  {
    [ "1" ] = 2,
  },
  {
    [ "2" ] = 3,
  },
  {
    [ "3" ] = 4,
  },
  {
    [ "4" ] = 5,
  },
  {
    [ "5" ] = 6,
  },
  {
    [ "6" ] = 7,
  },
  {
    [ "7" ] = 8,
  },
  {
    [ "8" ] = 9,
  },
  {
    [ "9" ] = 10,
  },
  {
    [ "0" ] = 11,
  },
}

--Creates a list of all alphanumeric chars using the table above
local keys = {}
for i = 1,#keysraw do
  for a,_ in pairs(keysraw[i]) do
    keys[i]=a
  end
end

--PRELIMINARY--

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
  if not httpGet("https://pastebin.com/raw/xuMVS2GP", "apis/CGBCoreLib.lua") then
    error("Error: Dependancy 'CGBCoreLib' could not be downloaded. Please connect your internet and restart")
  end
end

local cgb = require("apis/CGBCoreLib") --Contains complete function library used accross multiple programs and to minimize code size.

cgb.saveConfig("data/keydata.lua",keys)
--For API check
local requiredAPIFuncs = {
  "getAnswerWithPrompts",
  "saveConfig",
  "fileWrite",
  "findPeripheralOnSide",
  "isInList",
  "stringToTable",
  }

--Check API to ensure not outdated
for _ , func in pairs(requiredAPIFuncs) do 
  if not cgb[func] then
    if not httpGet("https://pastebin.com/raw/xuMVS2GP", "apis/CGBCoreLib.lua") then
      error("Error: Your version of CGBCoreLib is outdated! Please connect your internet and restart!")
    else
      os.reboot()
    end
  end
end

local pcTypes = {"Bank","ATM","Store"}
--Now check to see what this is (Bank or ATM)
local function pcTypeCheck()
  local output=nil
  for key, type in pairs(pcTypes) do
    if fs.exists("data/blubank/" .. type .. ".type") then
      output = type
      return true,output
    end
  end
  if not output then
    return nil
  end
end

local modem = nil
--New computer. creates a blank file as a type placeholder
--Find modem, make sure it is wireless and open rednet.
--using sides first
local sides = redstone.getSides()
for _,side in pairs(sides) do
  if peripheral.getType(side) == "modem" and peripheral.call(side,"isWireless") then
    modem = true --no point with a wrap since we have found a modem to open rednet directly.
    rednet.open(side)
    break
  end
end
if not modem then --Wireless modem not on sides, must be on network
  local modemList = cgb.getPeripherals("modem")
  for _,v in pairs(modemList) do
    print(v)
    if peripheral.call(v,"isWireless") then
      modem = true
      rednet.open(v)
      break
    end
  end
  if not modem then
    error("Error: Wireless modem not found")
  end
end

local ok, pcType = pcTypeCheck()
local function configure(boolOverride)
  boolOverride = boolOverride or false
  if not ok then --For new configurations
    local nonexisting
    local event = {}
    pcType = cgb.getAnswerWithPrompts("What type of computer is this?",pcTypes)
    cgb.fileWrite("data/blubank/" .. pcType .. ".type")  --Don't have to repeat this anywhere now
    if pcType == "Bank" then
      --Bank server selected. Ensure no other bank server active by pinging for server.
      --Start a 3 second timer for if there is no answer to ping.
      print("Reminder: This chunk must now remain loaded at all times to avoid problems with ATMs working. Press any key to continue.")
      os.pullEvent("key")
      print("Pinging for existing bank server...")
      nonexisting = os.startTimer(1)
      rednet.broadcast("Existing?","Blu-bank-SSL")
      repeat 
        event = {os.pullEvent()}
      --Do all checks here.
      until 
        (event[1] == "rednet_message" and event[3] == "yes") 
      or 
        (event[1] == "timer" and event[2] == nonexisting)
      --We have already checked for other event args in repeat until so no need to repeat them below.
      if event[1] == "rednet_message" then
        --Bank server already exists. Ensure that type remains unset.
        print("There is already a Bank server active. Restarting!")
        fs.delete("data/blubank/" .. pcType ..".type")
        sleep(2)
        os.reboot()
      elseif event[1] == "timer" then
        --No bank server exists or active
        print("Other bank server not found. Bank server configured!")
        sleep(2)
      end
    end
  end
end

if not pcType then configure() end

local function mkFile(fileName)
  f=fs.open(fileName)
  f.close()
end

if pcType ~= "Bank" then --Stores and ATMs will have a redstone output
  rs.setOutput("bottom",true)
end

local function resetTerm()
  term.setBackgroundColor(colors.white)
  term.clear()
  if term.isColor() then
  term.setTextColor(colors.blue)
  elseif not term.isColor() then
  term.setTextColor(colors.black)
  end
  term.setCursorPos(1,1)
  if commands ~= nil and pcType == "Bank" then
    print("Blu-Bank OS " .. version .. " Bank")
    print("Command Bank server active!")
    shell.run("bg")
  elseif not commands then
    print("Blu-Bank OS " .. version .. " " .. pcType)
    if pcType == "Bank" then
      print("Bank server active!")
      shell.run("bg")
    else
      print("Accessing bank server...")
    end
  end
end

local function listPeripheralsByName(...)
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

local function alignText(tableScreen, stringText, stringAlignTo, boolLastLine)
  --prints on previous line. Allows things like !item        cost!
  local boolLastLine = boolLastLine or false
  local screen = tableScreen
  local x,y = screen.getSize()
  local stringLength = stringText:len()
  local midpoint = ((x / 2) - (stringLength / 2))+1
  local right = (x - stringLength) + 1
  local cursorPosX, cursorPosY = screen.getCursorPos()
  if stringLastLine then
    cursorPosY = cursorPosY - 1
  end
  if stringAlignTo == "left" then
    screen.setCursorPos(cursorPosX,cursorPosY)  
  elseif stringAlignTo == "center" then
    screen.setCursorPos(midpoint,cursorPosY)
  elseif stringAlignTo == "right" then
    screen.setCursorPos(right,cursorPosY)
  else
    error("alignText: Bad argument #3: expected left, center or right!")
  end
  screen.write(stringText)
end


local sign
local chest
local trash
local sensor=nil
local config = {}
if pcType ~= "Bank" then --no point trying to wrap a sensor for bank server.
  sensor = peripheral.find("plethora:sensor")
  if not sensor then
    error("Error: Sensor not found. The ATM requires a sensor turtle with wireless modem to function")
  end
  if not fs.exists("data/blubank/config.lua") then
    --Chests
    repeat
      print("What is the network name of your input chest?")
      input = io.read()
      chest = peripheral.wrap(input)
      if not chest then
        print("Chest not found or input network name not a chest or storage. please check network name and try again")
      end
    until chest
    config["chest"]= input
    --trash for deposits to delete items
    repeat
      print("What is the network name of your trash chest?")
      input = io.read()
      trash = peripheral.wrap(input)
      if not trash then
        print("Chest not found or input network name not a chest or storage. please check network name and try again")
      end
    until trash
    config["trash"] = input
    --configure screens
    print("Please right click on the monitor you wish to use as greeting sign")
    print("OR invoke a redstone signal for network name / side")
    repeat
      event,monitorraw,x,y = os.pullEvent()
    until event == "monitor_touch" or event == "redstone"
    if event == "monitor_touch" then
      config["greeting_monitor"]=monitorraw
      monitor = peripheral.wrap(monitorraw)
    elseif event == "redstone" then
      repeat
        print("What is the network name / side of the screen?")
        input = io.read()
        monitor = peripheral.wrap(input)
        if not monitor then
          print("Entered network name / side not found. Please try again")
        end
      until monitor
      config["greeting_monitor"]=input
    end
    monitor.write("BLU-BANK OS")
    
    
    print("Please right click on the monitor you wish to use as currency sign")
    print("OR invoke a redstone signal for network name / side")
    repeat
      event,monitorraw,x,y = os.pullEvent()
    until event == "monitor_touch" or event == "redstone"
    if event == "monitor_touch" then
      config["currency_monitor"]=monitorraw
      cmonitor = peripheral.wrap(monitorraw)
    elseif event == "redstone" then
      repeat
        print("What is the network name / side of the screen?")
        input = io.read()
        cmonitor = peripheral.wrap(input)
        if not cmonitor then
          print("Entered network name / side not found. Please try again")
        end
      until cmonitor
    config["currency_monitor"]=input
    end    
    cmonitor.write("BLU-BANK OS")
    
    print("Please right click on the monitor you wish to use as ATM Building sign")
    print("OR invoke a redstone signal for network name / side")
    repeat
      event,monitorraw,x,y = os.pullEvent()
    until event == "monitor_touch" or event == "redstone"
    if event == "monitor_touch" then
      config["sign_monitor"]=monitorraw
      sign = peripheral.wrap(monitorraw)
    elseif event == "redstone" then
      repeat
        print("What is the network name / side of the screen?")
        input = io.read()
        sign = peripheral.wrap(input)
        if not sign then
          print("Entered network name / side not found. Please try again")
        end
      until sign
    config["sign_monitor"]=input
    end    
    sign.write("BLU-BANK OS")
    
    --get and save id of bank server
    rednet.broadcast("bank id?","Blu-bank-SSL")
    event, id, message, protocol = os.pullEvent("rednet_message")
    config.bankId = tonumber(id)
    cgb.saveConfig("data/blubank/config.lua",config)
  else
    --Config exists... load all devices and settings
    config = cgb.loadConfig("data/blubank/config.lua")
    
    --This allows a bank to be moved to a new computer without any ATM config needed.
    --Will stop ATMs turning on if server is not working
    rednet.broadcast("bank id?","Blu-bank-SSL")
    term.clear()
    term.setCursorPos(1,1)
    print("BLU-BANK OS")
    print("Querying bank server...")
    expired = os.startTimer(1)
    repeat
      event, id, message, protocol = os.pullEvent()
    until (event == "rednet_message" and message == "ok") or (event == "timer" and id == expired)
    if event == "rednet_message" then
      config.bankId = tonumber(id)
      monitor = peripheral.wrap(config.greeting_monitor)
      monitor.clear()
      monitor.setCursorPos(1,1)
      monitor.write("Blu-bank OS")
      --cmonitor = peripheral.wrap(config.currency_monitor)
      chest = peripheral.wrap(config.chest)
      trash = peripheral.wrap(config.trash)
      --sign = peripheral.wrap(config.sign_monitor) 
    elseif id == expired then
      print("Bank server not responding! auto restarting in:")
      for i = 5,1,-1 do
        print(i .. "...")
        sleep(1)
      end
      os.reboot()
    end
  end
elseif (tArgs[1] == "currency-config") or 
(pcType == "Bank" and commands and not fs.exists("data/blubank/currency.lua")) then --new bank server, need to configure item list
  local storage = listPeripheralsByName("chest","shulker")
  if not storage[1] then --at least one chest is needed
    repeat
      print("Chests / shulkers: " .. #storage)
      print("A chest or shulker is required for configuration of server. (Exchange and Withdrawal items). Press any key when you have connected a chest or shulker.")
      os.pullEvent("key")
      storage = listPeripheralsByName("chest","shulker")
      if not storage[1] then
        print("Chest or shulker not yet found, Please make sure they are networked and the modem is 'connected'.")
      end
    until storage[1]
  end
  print("Please now insert the items you wish to use in order from most expensive to least expensive and press any key.")
  print("note: You can simply add additional exchange items by placing them after your cheapest item (ensure that the first additional item is worth more than your cheapest item otherwise they will be considered withdrawal items also)")
  os.pullEvent("key")
  local n = 0
  local data = {}
  for slot,_ in pairs(peripheral.call(storage[1],"list")) do
    n=n+1
    dataRaw = peripheral.call(storage[1],"getItemMeta",slot) 
    data={ --Let's trim down the saved data a little, do not need maxDamage etc
    ["displayName"] = dataRaw.displayName,
    ["name"] = dataRaw.name,
    ["rawName"] = dataRaw.rawName,
    ["maxCount"] = dataRaw.maxCount,
    ["damage"] = dataRaw.damage
    }
    repeat
      print("How many credits is '" .. dataRaw.displayName .."' worth?")
      input = tonumber(io.read())
      if not input then
        print("Sorry! That's not a number. Please try again.")
      end
    until input
    currency[n] ={["value"] = input, ["data"] = data} --ensures items are in an ordered table with all needed data to allow correct checking of funds against it for withdrawals. allows #currency use
  end
  n = 0
  cgb.saveConfig("data/blubank/currency.lua",currency)
  
end

--if pcType == "Bank" then
  currency = cgb.loadConfig("data/blubank/currency.lua")
--end

local currencyLookupName = {}
local function currencyLookupSimple()
  local output = {}
  for count= 1, #currency do
    output[currency[count].data.name] = currency[count].value
    --allows player to enter displayname instead of minecraft:etc
    currencyLookupName[currency[count].data.displayName]=currency[count].data.name
  end
  return output
end

local simpleCurrency = currencyLookupSimple()
--returns an unordered currency list and allows things like if simpleCurrency[name] == cost then

local function updateCurrencyScreen()
  cmonitor.setBackgroundColor(colors.white)
  cmonitor.clear()
  cmonitor.setTextScale(1)
  cmonitor.setCursorPos(1,1)
  if cmonitor.isColor then
    cmonitor.setTextColor(colors.blue)
  else
    cmonitor.setTextColor(colors.black)
  end
  cmonitor.write("Credit rates:")
  cmonitor.setCursorPos(1,2)
  for count = 1, #currency do
    local line = count + 2
    local dispName = currency[count].data.displayName
    local cost = currency[count].value
    --Make cost have nice thousands seperator on screen
    local hundreds = cost % 1000
    hundreds = tostring(hundreds)
    local thousands,_ = math.floor(cost / 1000) --Calculate thousands and drop fraction.
    if hundreds:len() < 3 and tonumber(thousands) > 0 then --only add 0s to hundreds if there are thousands and there are less than 3 digits in hundreds
      repeat 
        hundreds = "0" .. hundreds
      until hundreds:len() == 3
    end
    if thousands == 0 then
      alignText(cmonitor,dispName .. ":","left")
      alignText(cmonitor,hundreds,"right",true)
      --cmonitor.write(dispName .. ": ".. hundreds)
    else
      alignText(cmonitor,dispName .. ":","left")
      alignText(cmonitor,thousands .. "," .. hundreds,"right")
      --cmonitor.write(dispName .. ": " .. thousands .. "," .. hundreds)
    end
    cmonitor.setCursorPos(1,line)
  end
end

local function updateMonitor(stringNewMsg,colorName)
  monitor.setBackgroundColor(colors.white)
  if colorName then 
    monitor.setTextColor(colorName)
  else
    monitor.setTextColor(colors.blue)
  end
  if not monitor.isColor() then
    monitor.setTextColor(colors.black)
  end
  monitor.setTextScale(2)
  monitor.clear()
  monitor.setCursorPos(1,1)
  alignText(monitor,"Blu-Bank " .. pcType,"center")
  monitor.setCursorPos(1,2)
  alignText(monitor,stringNewMsg,"center")
end

local function buildingSign()
  sign.setBackgroundColor(colors.white)
  sign.clear()
  sign.setCursorPos(2,1)
  sign.setTextScale(5)
  sign.setTextColor(colors.blue)
  sign.write("BLU-BANK")
end


if pcType == "Bank" and not commands then
  print("Warning: This pc is not a command pc, as such only deposits and store purchases are available. Please ensure everyone knows that direct withdrawals are not possible.")
end

--Prevents a hacker from making any transactions on other players behalf. must be called.
local function authenticate(stringAuthType)
  rednet.send(senderID, "authorization required")
  event, senderID, message = os.pullEvent()
  if message == "password?" then
    local pass = ""
    for i = 1, 20 do
      k = math.random(1,#keys)
      pass = pass .. keys[k]
    end
    passExpired = os.startTimer(1) --if ATM received password it should have bounced back within 1 second.
    rednet.send(senderID,"pass: " .. pass)
    repeat
      event, senderID, message = os.pullEvent()
    until (event == "rednet_message" and message == pass) or (event == "timer" and senderID == passExpired)
    if event == "rednet_message" then 
      rednet.send(senderID, stringAuthType .. " Authorized")
    elseif event == "timer" then
      rednet.send(senderID, "Authorization timed out!")
    end
  end
end

local sensordata={}
local function updateSensorData()
  sensordata=sensor.sense() --this is also stored in upper sensordata so we can still do whatever we want with it
end

local function getPlayerInRange()
  local id = nil
  updateSensorData()
  for i,_ in pairs(sensordata) do
    if sensordata[i].x > -range and 
    sensordata[i].x < range and 
    sensordata[i].z > -range and 
    sensordata[i].z < range and
    sensordata[i].y > -range and
    sensordata[i].y < range then
      if not cgb.isInList(sensordata[i].name,blacklistNames) then
        id = sensordata[i].name
        return true, id--ensures only one player is found at a time. also allows id to be discarded if not needed at the time.
      end
    end
  end
end


local event
local function secondary()
  local messagedata = {}
  local commanddata = {}
  local funds = {}
  local bal = 0
  while true do
    event, senderID, message, protocol = os.pullEvent("rednet_message")
    if protocol == "Blu-bank-SSL" then --hard protocol name for players to guess and take over the server with... especially since they dont know how the commands are even sent or read. (Whatever you do, DO NOT TELL THEM!)
      if pcType == "Bank" then
        if message == "Existing?" then
          rednet.send(senderID,"yes") --makes sure reply is securely sent to enquiring computer.
        elseif message == "bank id?" then
          rednet.send(senderID,"ok")
        end
      end
    end
    --
    if pcType == "Bank" then
      --print(message)
      if commands ~= nil then --allows give command to be sent using ATMs
      --limit commands to give only
        if message:find("command") and message:find("give") then 
          print(message)
          messagedata = cgb.stringToTable(message)
          for i = 3,#messagedata do
            commanddata[i-2]=messagedata[i]
          end
          commands[messagedata[2]](table.unpack(commanddata))
          commanddata = {} --This is a must otherwise additional arguments are passed to the next command if your last was long.
        elseif message:find("command") and not message:find("give") then
        --Command use exceeds limit, alert everyone to a potential hacker.
          print("Unauthorized command attempt from PC ID: " .. senderID ..". Attempt: '" .. message .."'.")
          commands.say("Unauthorized access attempt...CC HACKER ALERT!")
        end
      end
      --"exchange playername item cost quantity"
      if message:find("exchange") then
        -- authenticate("exchange")
        -- event, senderID, message, protocol = os.pullEvent("rednet_message")
        -- if message == "exchange Authorized" then
          print(message)
          _, player, item, credcost, qty = cgb.stringToVarsAll(message)
          print(player .. " requested to exchange " .. qty .. " " .. item)
          local cost = tonumber(credcost) * qty
          funds = cgb.loadConfig("data/blubank/users/" .. player .. ".lua")
          if cost <= funds.balance then
            rednet.send(senderID, "exchange-success")
            funds.balance = funds.balance - cost
            cgb.saveConfig("data/blubank/users/" .. player .. ".lua",funds)
            --Check item maxcount and give accordingly
            --avoids no give bug if qty higher than maxcount
            for i = 1,#currency do
              --check that the cost is also correct
              if item == currency[i].data.name and tonumber(credcost) == currency[i].value then
                maxCount = currency[i].data.maxCount
                damage = currency[i].data.damage
                --/\ ensures that the correct item is given, Eg, 'computercraft:peripheral' is Disk Drive, where as 'computercraft:peripheral 1 4' is 1 Advanced monitor
                break
              end
            end
            qty = tonumber(qty)
            if qty > maxCount then 
              repeat
                commands.give(player .. " " .. item .. " " .. maxCount .. " " .. damage)
                qty = qty - maxCount
              until qty <= maxCount
              commands.give(player .. " " .. item .. " " .. qty .. " " .. damage) 
            elseif qty <= maxCount then
              commands.give(player .. " " .. item .. " " .. qty .. " " .. damage)
            end
          elseif cost > funds.balance then
            rednet.send(senderID,"insufficient funds This item costs " .. cost .. " credits and you have " .. funds.balance .. " credits!")
          end
        -- end
      --"withdraw playername amount"
      elseif message:find("withdraw") then
        local qty
        print(message)
        --authenticate("Withdrawal")
        --event, senderID, message, protocol = os.pullEvent("rednet_message")
        --if message == "Withdrawal Authorized" then
          _, player, amount = cgb.stringToVars(message)
          funds = cgb.loadConfig("data/blubank/users/" .. player .. ".lua")
          print("funds: " .. funds.balance)
          withdrawalRequest = tonumber(amount)
          if withdrawalRequest <= funds.balance then
            rednet.send(senderID,"withdrawal-success")
            if funds.balance == withdrawalRequest then
              funds.balance = 0 
            elseif funds.balance > withdrawalRequest then
              funds.balance = funds.balance - withdrawalRequest
            end
            print("Remaining: " .. funds.balance)
            cgb.saveConfig("data/blubank/users/" .. player .. ".lua",funds)
            --calculate how many of each item to give
            for count = 1, #currency do
              itemName = currency[count].data.name
              cost = currency[count].value
              maxCount = currency[count].data.maxCount
              damage = currency[count].data.damage
              --/\ ensures that the correct item is given, Eg, 'computercraft:peripheral' is Disk Drive, where as 'computercraft:peripheral 1 4' is 1 Advanced monitor
              qty,fraction=math.modf(withdrawalRequest / cost) --how many items can be given at this cost?
              --item has been calculated. give item
              --This avoids give not happening due to qty higher than maxcount bug
              if qty > maxCount then 
                repeat
                  commands.give(player .. " " .. itemName .. " " .. maxCount .. " " .. damage)
                  qty = qty - maxCount
                until qty <= maxCount
                commands.give(player .. " " .. itemName .. " " .. qty .. " " .. damage) 
              elseif qty <= maxCount then
                commands.give(player .. " " .. itemName .. " " .. qty .. " " .. damage)
              end
              withdrawalRequest = fraction * cost --How many credits remain after item count?
            end
            --make sure remaining unwithdrawable credits get refunded
            funds.balance = funds.balance + withdrawalRequest
            cgb.saveConfig("data/blubank/users/" .. player .. ".lua",funds)
          elseif withdrawalRequest > funds.balance then
            rednet.send(senderID, "insufficient funds Balance " .. funds.balance .. " credits.")
          end
        --end
      --"deposit playername amount"
      elseif message:find("deposit") then
        --authenticate("Deposit")
        -- event, senderID, message, protocol = os.pullEvent("rednet_message")
        -- if message == "Deposit Authorized" then
          _,player,amount = cgb.stringToVars(message)
          print("Depositing " .. amount .. " credits into " .. player .. "s' account") 
          funds = cgb.loadConfig("data/blubank/users/" .. player .. ".lua")
          funds.balance = funds.balance + tonumber(amount)
          cgb.saveConfig("data/blubank/users/" .. player .. ".lua",funds)
          rednet.send(senderID,"deposit-success")
          --Funds addition code here
        -- end
      elseif message == "password?" then
        --password generator code
        --generates a one time password which must be bounced back to server for authentication.
        authenticate()
      --"balance playername"
      elseif message:find("balance") then
        --authenticate("Balance query")
        -- event, senderID, message, protocol = os.pullEvent("rednet_message")
        -- if message == "Balance query Authorized" then
           _, player= cgb.stringToVars(message)
          if not fs.exists("data/blubank/users/" .. player .. ".lua") then
            print("Creating new account for: " .. player)
            if newAccAmount > 0 then
              print("Adding " .. newAccAmount .. " credits for " .. player)
            end
            funds.balance = newAccAmount
            cgb.saveConfig("data/blubank/users/" .. player .. ".lua",funds)
          else
            print("Loading funds of: " .. player)
            funds = cgb.loadConfig("data/blubank/users/" .. player .. ".lua")
          end
          rednet.send(senderID, "bal " .. funds.balance)
        --end
      elseif message:find("transfer") then
        _, fromplayer, toplayer, amount = cgb.stringToVarsAll(message)
        amount = tonumber(amount)
        funds = cgb.loadConfig("data/blubank/users/" .. fromplayer .. ".lua")
        if amount > funds.balance then
          rednet.send(senderID, "insufficient funds You requested to transfer " .. amount .. " credits but have " .. funds.balance .. " credits!")
        elseif amount <= funds.balance then
          rednet.send(senderID, "transfer-success")
          funds.balance = funds.balance - amount
          cgb.saveConfig("data/blubank/users/" .. fromplayer .. ".lua",funds)
          funds = cgb.loadConfig("data/blubank/users/" .. toplayer .. ".lua")
          funds.balance = funds.balance + amount
          cgb.saveConfig("data/blubank/users/" .. toplayer .. ".lua",funds)
          if commands then commands.tell(toplayer .. " " .. fromplayer .. " has just transferred you " .. amount .. " credits!") end
        end
      end
    elseif pcType == "ATM" then
      if message == "withdraw-success" then
        print("Success. Dispensing cash... please check your inventory :D")
      elseif message == "authorization required" then
        rednet.send(senderID, "password?")
        event,senderID,message = os.pullEvent("rednet_message")
        if message:find("pass:") then
          _, pass = cgb.stringToVars(message)
          rednet.send(senderID,pass)
          event,senderID,message = os.pullEvent("rednet_message")
          if message == "Authorization timed out!" then
            error("BluBank OS: err_auth_failed. Please contact server admin.")
          end
        end
      end
    end
  end
end

--No matter how long the number is, thousand seperators will be accurately added.  
local function stringNumberToThousands(inputString)
  local numcheck = tonumber(inputString)
  --Check if input converts to a number
  if (type(inputString)=="nil") or (not numcheck) then
    error("stringNumberToThousands: Input not a number or number string. Got: '" .. (inputString or "nil") .. "'.",2)
  end
  --Convert if number
  if type(inputString) == "number" then
    inputString = tostring(inputString)
  end
  local output = ""
  --Check if thousands seperator can be added, no point continuing if not
  if inputString:len() <=3 then
    output = inputString
    return output
  end
  --Get every digit of stringInput and save to table
  local reconstruct = {}
  for s in string.gmatch(inputString,"%d") do
    table.insert(reconstruct,s)
  end
  local n = 0
  --Reconstruct number string with thousands seperator(s)
  for i = inputString:len(),1,-1 do
    n= n+1
    --String is reconstructed from back to front
    output = reconstruct[i] .. output
    --Adds a seperator every 3 chars only if there has been 3 chars since last seperator and there are more chars after a new seperator
    if i ~= 1 and n == 3 then
      output = "," .. output
      n = 0
    elseif i == 1 and n == 3 then
      break
    end
  end
  return output
end

local function pressAnyKey()
  print("Press any key to continue")
  os.pullEvent("key")
end

local outputString = ""
local player = "nil"
local playercheck
local playermem
local function main()
  while true do
    if pcType == "ATM" --[[or pcType == "Store"]] then
      --buildingSign()
      -- monitor.setTextScale(2)
      -- local maxSizeX,maxSizeY = monitor.getSize()
      -- exchangeWindow = window.create(monitor,1,1,maxSizeX / 2, maxSizeY * 0.9)
      -- exchangeWindow.setBackgroundColor(colors.red)
      -- exchangeWindow.clear()
      -- greetingWindow = window.create(monitor,1,maxSizeY * 0.9,maxSizeX,maxSizeY * 0.2)
      -- greetingWindow.setBackgroundColor(colors.blue)
      -- greetingWindow.setTextColor(colors.white)
      -- greetingWindow.clear()
      -- alignText(greetingWindow,"Hello player","center")
      updateMonitor("Awaiting Player approach...")
      resetTerm()
      currencyLookupSimple() --updates the 
      repeat
        ok,player = getPlayerInRange()
        if not ok then
          sleep(1)
        end
      until ok
      rs.setOutput("bottom",false)
      playermem = player
      updateMonitor("WELCOME " .. player .. "!")
      --updateCurrencyScreen()
      print("Welcome " .. player .. "!")
      rednet.send(config.bankId, "balance " .. player)
      --"bal balance"
      repeat
        event,senderID,message = os.pullEvent("rednet_message")
      until message:find("bal")
      _, bal= cgb.stringToVars(message)
      outputString = stringNumberToThousands(bal)
      print("Your balance: " .. outputString .. " credits.")
      if pcType == "ATM" then
        print("Press W for Withdrawal")
      end
      if pcType == "ATM" then
        print("Press D for Deposit")
      elseif pcType == "Store" then
        print("Press S to Sell")
      end
      if pcType == "ATM" then
        print("Press T to Transfer credits")
      end
      if pcType == "ATM" then
        print("Press E for the Credit Exchange Store")
      elseif pcType == "Store" then
        print("Press B for the Store")
      end
      print("Press L to Logoff")
      repeat
        event,c = os.pullEvent("char")
      until c
      if c == "l" then  --Logoff
        rs.setOutput("bottom",true)
        print("Logged off! Thanks for using Blu-Bank! See you soon!")
        print("Please step away from the ATM.")
        updateMonitor("Farewell Tenant!")
        --cmonitor.setBackgroundColor(colors.black)
        --cmonitor.clear()
        
        repeat
          ok,player = getPlayerInRange()
          if ok then
            sleep(1)
          end
        until not ok
      elseif c == "w" then --Withdraw
        print("How much would you like to withdraw?")
        local amount = io.read()
        rednet.send(config.bankId,"withdraw " .. player .. " " .. amount)
        event,senderID,message = os.pullEvent("rednet_message")
        if message == "withdrawal-success" then
          print("Success. Dispensing cash... please check your inventory :D")
        elseif message:find("insufficient") then
          local replyString = "" 
          local insufficientFundsMessage = {}
          --"insufficent funds message"
          messagedata = cgb.stringToTable(message)
          for i = 3, #messagedata do
            insufficientFundsMessage[i-2]=messagedata[i]
          end
          for _, str in pairs(insufficientFundsMessage) do
            replyString = replyString .. " " .. str
          end
          replyString = replyString .. "!"
          print("Insufficient funds! " .. replyString)
        end
        pressAnyKey()
      elseif c == "d" or c == "s" then --Deposit or sell
        local itemvalue
        local total=0
        local stringVar1 = ""
        local stringVar2 = ""
        if pcType == "ATM" then
          stringVar1 = "credit rates"
          stringVar2 = "place your deposit in"
        elseif pcType == "Store" then
          stringVar1 = "buy list"
          stringVar2 = "insert the items you want to sell into"
        end
        print("Take a look at the " .. stringVar1 .. " and " .. stringVar2 .. " the chest.")
        pressAnyKey()
        print("Processing, please wait.")
        for slot,item in pairs(chest.list()) do
          --only move item if listed in currency
          if simpleCurrency[item.name] then
            chest.pushItems(config.trash,slot,item.count)
            total = total + (item.count * simpleCurrency[item.name])
          end
        end
        if total == 0 then
          print("Nothing inserted or items do not match list. please check your items and try again.")
        else
          print("You have inserted " .. stringNumberToThousands(total) .. " credits")
          local stringVar = ""
          if pcType == "ATM" then 
            stringVar = "deposit"
          elseif pcType == "Store" then
            stringVar = "sale"
          end
          print("Are you happy to finalize your " .. stringVar .. "? Y or N")
          repeat  
            event,c = os.pullEvent("char")
          until c == "y" or c == "n"
          if c == "n" then
            print("Returning your " .. stringVar .. " items.")
            for slot,item in pairs(trash.list()) do
              trash.pushItems(config.chest,slot,item.count)
            end
          elseif c == "y" then
            print("Sending deposit request...")
            rednet.send(config.bankId, "deposit " .. player .. " " .. total)
            event,senderID,message = os.pullEvent("rednet_message")
            if message == "deposit-success" then
              for slot,_ in pairs(trash.list()) do
                trash.drop(slot)
              end
              print("Deposit of " .. stringNumberToThousands(total) .. " credits success!")
            end
          end
        end
        pressAnyKey()
      elseif c == "t" then --Transfer
        print("Transfers are performed as following:")
        print("toPlayerName amount")
        print("Please ensure you have spelled the playername correctly E.g: 'playername' is not 'PlayerName'")
        repeat
          input = io.read()
          toplayer, amount = cgb.stringToVarsAll(input)
          print("You have requested: " .. amount .. " credits to be transferred to: '" .. toplayer .."'.")
          print("Is this correct? Press Y or N. N will cancel the operation")
          event,c = os.pullEvent("char")
        until c=="y" or c=="n"
        if c=="y" then
          rednet.send(config.bankId, "transfer " .. player .. " " .. toplayer .. " " .. amount)
          event,senderID,message = os.pullEvent("rednet_message")
          if message == "transfer-success" then
            print("Transfer successful!")
          elseif message:find("insufficient") then
            local replyString = "" 
            local insufficientFundsMessage = {}
            --"insufficent funds message"
            messagedata = cgb.stringToTable(message)
            for i = 3, #messagedata do
              insufficientFundsMessage[i-2]=messagedata[i]
            end
            for _, str in pairs(insufficientFundsMessage) do
              replyString = replyString .. " " .. str
            end
            replyString = replyString .. "!"
            print("Insufficient funds! " .. replyString)
          end
          pressAnyKey()
        end
      elseif c == "e" then --Credit Exchange Store
        term.clear()
        term.setCursorPos(1,1)
        print("Credit Exchange Store")
        print("Your Balance: " .. outputString .. " credits.")
        for count = 1, #currency do
          local line = count + 3
          local dispName = currency[count].data.displayName
          local cost = currency[count].value
          --Make cost have nice thousands seperator on screen
          local hundreds = cost % 1000
          hundreds = tostring(hundreds)
          local thousands,_ = math.floor(cost / 1000) --Calculate thousands and drop fraction.
          if hundreds:len() < 3 and tonumber(thousands) > 0 then --only add 0s to hundreds if there are thousands and there are less than 3 digits in hundreds
            repeat 
              hundreds = "0" .. hundreds
            until hundreds:len() == 3
          end
          if thousands == 0 then
            alignText(term,"'" .. dispName .. "':","left")
            alignText(term,hundreds,"right",true)
          else
            alignText(term,"'" .. dispName .. "':","left")
            alignText(term,thousands .. "," .. hundreds,"right",true)
          end
          term.setCursorPos(1,line)
        end
        -- for count = 1,#currency do
          -- itemName = currency[count].data.displayName
          -- cost = currency[count].value
          -- print("'" .. itemName .. "' = " .. cost)
        -- end
        repeat
          print("Please enter as: item qty")
          input =io.read()
          local recInput = ""
          local wordList = {}
          --split the string into relevant items
          for word in string.gmatch(input, "%a+") do
            table.insert(wordList,word)
          end
          for n in string.gmatch(input,"%d+") do
            qty = n
          end
          if not qty then qty = 1 end
          --Reconstruct recorded item name. This keeps it seperate from qty
          recInput=wordList[1]
          for i = 2 , #wordList do
            recInput = recInput .. " " .. wordList[i]
          end
          --get raw item name from currency data
          item = currencyLookupName[recInput]
          if not simpleCurrency[item] then
            print("Entry is case-senitive. Please ensure you have typed your item correctly. Got: '" .. input .. "'.")
          end
          --We already know that the raw item name is correct. Now to get the damage value. Check against raw name and display name just to be sure we have the correct damage value.
          for i = 1 , #currency do
            if currency[i].data.name == item and currency[i].data.displayName == recInput then
              damage = currency[i].data.damage
              break
            end
          end
        until simpleCurrency[item]
        rednet.send(config.bankId, "exchange " .. player .. " " .. item .. " " .. simpleCurrency[item] .. " " .. qty .. " " .. damage)
        event,senderID,message = os.pullEvent("rednet_message")
        if message == "exchange-success" then
          print("Exchange successful, please check your inventory.")
        elseif message:find("insufficient") then
          local replyString = "" 
          local insufficientFundsMessage = {}
          --"insufficent funds message"
          messagedata = cgb.stringToTable(message)
          for i = 3, #messagedata do
            insufficientFundsMessage[i-2]=messagedata[i]
          end
          for _, str in pairs(insufficientFundsMessage) do
            replyString = replyString .. " " .. str
          end
          replyString = replyString .. "!"
          print("Insufficient funds! " .. replyString)
        end
        pressAnyKey()
      end
    elseif pcType == "Bank" then
      resetTerm()
      while true do
        os.pullEvent()
      end
    end
    --while not logged in by anyone, monitor reads 'Blu-bank ATM'. white background, blue writing if colors supported
    --when someone approaches, they are logged in and the screen changes to 'WELCOME playername'
    --When someone is logged in a redstone signal is output at bottom for door
    --When player leaves the detection range, a message is displayed 'Thankyou for using Blu-Bank. See you soon!' before going back to not logged in screen
  end
end

while true do
  parallel.waitForAny(main, secondary)
  --secondary()
end