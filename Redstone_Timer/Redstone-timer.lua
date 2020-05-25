--[[
Redstone timer

Allows exact timing of things like farms etc. timers continue from last point on world reopening.

]]

local data = {
  hours = 0,
  minutes = 0,
  seconds = 0,
  redOutSide = "",
  delayOff = {
    hours = 0,
    minutes = 0,
    seconds = 0
  },
  repeatTimer = false,
  timerIsSet = false,
  timerDataRaw = "",
  timerDelayOffDataRaw = "",
  timerPhase = 1
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

--Get API if don't already have
if not fs.exists("apis/CGBCoreLib.lua") then
  if not httpGet("https://pastebin.com/raw/xuMVS2GP", "apis/CGBCoreLib.lua") then
    error("Error: Dependancy 'CGBCoreLib' could not be downloaded. Please connect your internet and restart")
  end
end

require("apis/CGBCoreLib") --Contains complete function library used accross multiple programs and to minimize code size.

--For API check
local requiredAPIFuncs = {
  "getAnswerWithPrompts",
  "getUserInput",
  "saveConfig",
  "loadConfig",
  "stringToVars",
  }
  
--Check API to ensure not outdated
for _ , func in pairs(requiredAPIFuncs) do 
  if not CGBCoreLib[func] then
    if not httpGet("https://pastebin.com/raw/xuMVS2GP", "apis/CGBCoreLib.lua") then
      error("Error: Your version of CGBCoreLib is outdated! Please connect your internet and restart!")
    else
      os.reboot()
    end
  end
end


if not fs.exists("data/redtimer/settings.lua") then
  print("First time start configuration.")
  data.redOutSide = CGBCoreLib:getAnswerWithPrompts("What side will redstone output at end of timer?",rs.getSides())
  CGBCoreLib:saveConfig("data/redtimer/settings.lua",data)
else
  data = CGBCoreLib:loadConfig("data/redtimer/settings.lua")
end

local function convertTime()
  local toConvert = {
    hours,
    minutes,
    seconds,
    delayOff.hours,
    delayOff.minutes,
    delayOff.seconds
  }
  for _, val in pairs(toConvert) do
    data[val] = tonumber(data[val])
  end
end

while true do
  term.clear()
  term.setCursorPos(1,1)
  print("Redstone Timer")
  if (not data.repeatTimer) and (not data.timerIsSet) then
    data.timerDataRaw = CGBCoreLib:getUserInput("How long before redstone is turned on? please enter as 'hh mm ss' (including spaces)")
    data.hours, data.minutes, data.seconds = CGBCoreLib:stringToVars(data.timerDataRaw)
    data.timerDelayOffDataRaw = CGBCoreLib:getUserInput("How long until redstone needs to be turned off? please enter as 'hh mm ss' (including spaces)")
    data.delayOff.hours, data.delayOff.minutes, data.delayOff.seconds = CGBCoreLib:stringToVars(data.timerDelayOffDataRaw)
    convertTime()
    print("Should the timer repeat this when finished? Y or N")
    repeat
      event,c = os.pullEvent("char")
    until c == "y" or c == "n"
    if c == "y" then
      data.repeatTimer = true
    end
    data.timerIsSet = true
    CGBCoreLib:saveConfig("data/redtimer/settings.lua",data)
    os.reboot()
  elseif data.timerIsSet then
    while data.timerPhase == 1 do
      if data.seconds > 0 or data.minutes > 0 or data.hours > 0 then
        term.clearLine(2)
        term.setCursorPos(1,2)
        print("Time to redstone ON:")
        term.clearLine(3)
        term.setCursorPos(1,3)
        print(data.hours .. ":" .. data.minutes .. ":" .. data.seconds)
      end
      if data.seconds > 0 then
        data.seconds = data.seconds - 1
      elseif data.seconds == 0 and data.minutes >= 0 and data.hours >= 0 then
        data.seconds = 59
        if data.minutes > 0 then
          data.minutes = data.minutes - 1
        elseif data.minutes == 0 and data.hours > 0 then
          data.minutes = 59
          if data.hours > 0 then
            data.hours = data.hours - 1
          end
        end
      end
      if data.hours == 0 and data.minutes == 0 and data.seconds == 0 then
        rs.setOutput(data.redOutSide,true)
        data.timerPhase = 2
      end
      CGBCoreLib:saveConfig("data/redtimer/settings.lua",data)
      sleep(1)
    end
    while data.timerPhase == 2 do
      term.clearLine(2)
      term.setCursorPos(1,2)
      print("Time to redstone OFF:")
      term.clearLine(3)
      term.setCursorPos(1,3)
      print(data.delayOff.hours .. ":" .. data.delayOff.minutes .. ":" .. data.delayOff.seconds)
      -- if data.delayOff.seconds > 0 or data.delayOff.minutes > 0 or data.delayOff.hours > 0 then
        -- term.clearLine(2)
        -- term.setCursorPos(1,2)
        -- print("Time to redstone OFF:")
        -- term.clearLine(3)
        -- term.setCursorPos(1,3)
        -- print(data.delayOff.hours .. ":" .. data.delayOff.minutes .. ":" .. data.delayOff.seconds)
      -- end
      if data.delayOff.seconds > 0 then
        data.delayOff.seconds = data.delayOff.seconds - 1
      elseif data.delayOff.seconds == 0 and data.delayOff.minutes >= 0 and data.delayOff.hourse >= 0 then
        data.delayOff.seconds = 59
        if data.delayOff.minutes > 0 then
          data.delayOff.minutes = data.delayOff.minutes - 1
        elseif data.delayOff.minutes == 0 and data.delayOff.hours > 0 then
          data.delayOff.minutes = 59
          if data.delayOff.hours > 0 then
            data.delayOff.hours = data.delayOff.hours - 1
          end
        end
      end
      if data.delayOff.hours == 0 and data.delayOff.minutes == 0 and data.delayOff.seconds == 0 then
        rs.setOutput(data.redOutSide,false)
        data.timerIsSet = false
        data.timerPhase = 1
      end
      CGBCoreLib:saveConfig("data/redtimer/settings.lua",data)
      sleep(1)
    end
  elseif data.repeatTimer and not data.timerIsSet then
    --We already have this data. reset timer.
    data.hours, data.minutes, data.seconds = CGBCoreLib:stringToVars(data.timerDataRaw)
    data.delayOff.hours, data.delayOff.minutes, data.delayOff.seconds = CGBCoreLib:stringToVars(data.timerDelayOffDataRaw)
    convertTime()
    data.timerIsSet = true
    data.timerPhase = 1
    CGBCoreLib:saveConfig("data/redtimer/settings.lua",data)
  end
end
