--CreeperGoBoom (CGB) Core Library API
--A bunch of useful functions

local funcs = {}
local doOnceNoColorWarning = {
  ["colorPrint"] = true, 
  ["errorPrint"] = true
}  -- For displaying a one time warning about no color capability


--Writes data to a file, data can be anything except a function
function funcs.fileWrite(stringFileName,data) 
  local file = fs.open(stringFileName, "w")
  file.write(data)
  file.close()
end

--Gets user input for a prompt
function funcs.getUserInput(stringPrompt)  
  print(stringPrompt)
  local result = io.read()
  return result
end

--Checks a string against a table of answers and prints available answers if incorrect
function funcs.checkAnswer(stringInput,tableAnswers) 
  for _, key in pairs(tableAnswers) do
    if key == stringInput then
      return true
    end
  end
  print("Answer not available, please use one of: ", table.concat(tableAnswers, ", "), ".")
  return false
end

--Checks a string against a table of answers.
function funcs.checkAnswerSilent(stringInput, tableAnswers) 
  for _, key in pairs(tableAnswers) do
    if key == stringInput then
      return true
    end
  end
  return false
end

--Gets user input and checks input against answer table.
function funcs.getAnswer(stringPrompt, tableAnswers)  
  local input
  repeat
    input = funcs.getUserInput(stringPrompt)
  until funcs.checkAnswer(input, tableAnswers)
  return input
end

--Gets user input and checks against answer table while showing available answers in prompt
function funcs.getAnswerWithPrompts(stringPrompt, tableAnswers) 
  local input
  repeat
    input = funcs.getUserInput(stringPrompt .. " " .. table.concat(tableAnswers, ", "), ".")
  until funcs.checkAnswer(input, tableAnswers)
  return input
end

--Returns wrap if peripheral name found
function funcs.findPeripheral(stringName,stringAltName)  
  if type(stringName) ~= "string" then return end
  if type(stringAltName) ~= "string" then return end
  return peripheral.find(stringName) or peripheral.wrap(stringAltName)
end

--Returns entered name or altname if peripheral found
function funcs.peripheralCheck(stringName, stringAltName) 
  if type(stringName) ~= "string" then return end
  if type(stringAltName) ~= "string" then return end
  if peripheral.find(stringName) then return stringName elseif peripheral.wrap(stringAltName) then return stringAltName end
end

--Returns a table of all connected peripheral names containing Name
--Function idea by FatBoyChummy
function funcs.getPeripherals(stringName)
  local peripherals = {}
  local n = 0
  for _, name in pairs(peripheral.getNames()) do
    if name:find(stringName) then
      n = n + 1
      peripherals[n] = name
    end
  end
  return peripherals
end

function funcs.listPeripheralsByName(...)
  local temp = {}
  local temp2 = {}
  local count = 1
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

--Returns a table of color names as string
function funcs.getColorNames()
  local doNotAddIfContain = {"test","pack","rgb","combine","subtract"}
  local colorNames = {}
  local doNotAdd = false
  for k, v in pairs(colors) do
    for _ , check in pairs(doNotAddIfContain) do
      if k:find(check) then  --check k against list of do not adds.
        doNotAdd = true
        break
      end
    end
    if not doNotAdd then 
      table.insert(colorNames,k)      -- Test did not find a match in do not add, add checked color name.
    else 
      doNotAdd = false   -- Test found a match containing a do not add. Reset for next check.
    end  
  end
  return colorNames
end

local colorNamesList = funcs.getColorNames()

function funcs.loadConfig(configFileName)
  local file = fs.open(configFileName, "r")
  local fData = file.readAll()
  local config = textutils.unserialize(fData)
  file.close()
  return config
end

function funcs.saveConfig(configFileName,data)
  local sData = textutils.serialize(data)
  funcs.fileWrite(configFileName,sData)
end

function funcs.tablePrint(tableVar)
  if tableVar then local sData = textutils.serialize(tableVar)
  print(sData)
  end
end

function funcs.getTableSize(table)
  local count = 0
  for i , _ in pairs(table) do
    count = count + 1
  end
  return count
end

function funcs.getAnswerAsNumbers(stringPrompt,tableAnswers) --returns answer chosen from table.
  --Lists entries
  local answer
  local tableVar = {} --stores key and value depending if key is a number or not
  repeat 
    local count = 0
    print(stringPrompt)
    for key , value in pairs(tableAnswers) do
      if type(key) == "number" then --key isnt always a number
        print(key,value)
        tableVar[key]=value --What you see come up on screen is what is saved.
      else
        count = count + 1
        print(count,key)
        tableVar[count]=key
      end
    end
    print("Please enter the corresponding number for your selection.")
    answer = tonumber(io.read())
    if answer then          --Answer must be a number else it is a string
      if answer > funcs.getTableSize(tableVar) then
        print("That's out of range, please try again!")
      end
    else  --in case someone enters something other than a number
      print("That's not a number. Please only answer with a number!")
    end
  until answer and answer <= funcs.getTableSize(tableVar)  --must have this check else it will error if answer is string
  return tableVar[answer] 
end

function funcs.getAnswerAsNumbersGrouped(stringPrompt,tableAnswers) --returns answer chosen from table.
  --groups entries as per num per line, recommend no more than 3
  local answer
  local tableVar = {}  --creates a searchable table. since not all tables that are entered have numbers as keys
  local tableVarNumbered = {}
  repeat 
    local count = 0
    print(stringPrompt)
    for key , value in pairs(tableAnswers) do
      if type(key) == "number" then --key isnt always a number
        tableVar[key] = value --What you see come up on screen is what is saved.
        tableVarNumbered[key] = key .. " " .. value
      else
        count = count + 1
        tableVar[count] = key
        tableVarNumbered[count] = count .. " " .. key
      end
    end
    local tableSize = funcs.getTableSize(tableVar)
    textutils.tabulate(tableVarNumbered)
    print("Please enter the corresponding number for your selection.")
    answer = tonumber(io.read())
    if answer then          --Answer must be a number else it is a string
      if answer > tableSize then
        print("That's out of range, please try again!")
      end
    else  --in case someone enters something other than a number
      print("That's not a number. Please only answer with a number!")
    end
  until answer and answer <= tableSize  --must have this check else it will error if answer is string
  return tableVar[answer] 
end

function funcs.findPeripheralOnSide(stringPeripheral) --returns side. Ignores peripherals behind modems etc.
  local sides = redstone.getSides()
  for _ , side in pairs(sides) do
    if peripheral.getType(side) == stringPeripheral then
      local peripheralSide = side --This is needed for check below
      return side
    end
  end
  if not peripheralSide then  --peripheral not found as such is nil
    return nil
  end
end

function funcs.peripheralCall(stringName,stringMethod,...)  --An enhanced peripheral.call
  --Can check for name or side
  --Also checks network for peripheral
  local periph = peripheral.wrap(stringName)
  -- Check that stringName peripheral exists
  if not periph then
    error("'" .. stringName .. "' is not a peripheral, check spelling and try again.")
  end
  -- Check that peripheral supports stringMethod
  if not periph[stringMethod] then
    print("'" .. stringName .. "' Methods:")
    print(textutils.pagedTabulate(peripheral.getMethods(stringName)))
    error("'" .. stringMethod .. "' is not a method of: '" .. stringName .. "', check method names listed above and try again.")
  else 
  -- Peripheral exists and method supported, run it.
    periph[stringMethod](...)
    periph = nil   --peripheral interaction successful. clear wrap from memory
  end
end

-- A simplified table.insert
function funcs.tableInsert(tableVar,numOrStringKey,value)
  if type(value) == "nil"  then
    table.insert(tableVar,numOrStringKey)
  else
    local key = numOrStringKey or #tableVar + 1
    tableVar[key]=value
  end
end

function funcs.colorPrint(stringColorName,string)
  if term.isColor() then
    if not pcall(term.setTextColour,colors[stringColorName]) then
      print(textutils.pagedTabulate(colorNamesList))
      error("Error: colorPrint: incorrect color name entered: '" .. stringColorName .. "'. please check with above list")
    else
      print(string)
      term.setTextColour(colors.white)
    end
  else
    if doOnceNoColorWarning.colorPrint == true then
      print("Warning: colorPrint: Cannot output color here! This message only shows once!")
      doOnceNoColorWarning.colorPrint = false
    end
    print(string)
  end
end

function funcs.errorPrint(string)
  if term.isColor() then
    term.setTextColour(colors.red)
    print(string)
    term.setTextColour(colors.white)
  else
    if doOnceNoColorWarning.errorPrint == true then
      print("Warning: errorPrint: Cannot output color here! This message only shows once!")
      doOnceNoColorWarning.errorPrint = false
    end
    print(string)
  end
end

--Checks a string against a list of strings. Only returns true or false
function funcs.isInList(stringToCheck,tableList)
  local isListed = false
  for k,v in pairs(tableList) do
    if v == stringToCheck then
      isListed = true
      return true
    end
  end
  if not isListed then
    return false
  end
end

--Turns a string into a table
--ignores non alphanumeric chars
function funcs.stringToTable(stringInput)
  local tableOutput = {}
  local n=0
  for i in string.gmatch(stringInput, "%w+") do
    n = n+1
    tableOutput[n] = i
  end
  return tableOutput
end

--Turns a string into a table
--ignores only spaces
function funcs.stringToTable(stringInput)
  local tableOutput = {}
  local n=0
  for i in string.gmatch(stringInput, "%S+") do
    n = n+1
    tableOutput[n] = i
  end
  return tableOutput
end

--Splits a string into seperate vars
--Example: this, string = stringToVars("this string")
--ignores non alphanumeric characters and counts them as spaces (-=+:;>?/) etc
function funcs.stringToVars(stringInput)
  local tableOutput = {}
  local n=0
  for i in string.gmatch(stringInput, "%w+") do
    n = n+1
    tableOutput[n] = i
  end
  return table.unpack(tableOutput)
end

--Splits a string into seperate vars
--Example: this, string = stringToVars("this string")
--More inclusive, only ignores spaces
function funcs.stringToVarsAll(stringInput)
  local tableOutput = {}
  local n=0
  for i in string.gmatch(stringInput, "%S+") do
    n = n+1
    tableOutput[n] = i
  end
  return table.unpack(tableOutput)
end

return funcs
