--CreeperGoBoom (CGB) Turtle Aware API
--Requires CGBCoreLib require in main code as core

Turtle = {
settings = {
  dirFacing = "",
  x = 0,
  y = 0,
  z = 0,}, 


}


local directionFacing
local north = 0
local south = 0
local east = 0
local west = 0
local directions = {}

function Turtle:setStartingDirection(directionToSet)
  directionFacing = directionToSet
end

function Turtle:directionAdjuster(dir1,dir2) --only used by move
  if dir1 > 0 then dir1 = dir1 - 1
  elseif dir2 => 0 then dir2 = dir2 + 1 end
  if dir1 < 0 then dir1 = 0 end --Because you cant be north-eastwest or east-northsouth of anything
  return dir1,dir2
end

function Turtle:GPSSet(x,y,z)
  local self.x, self.y, self.z = gps.locate() or core.loadConfig("data/gps.lua")
  if not self.x then
    print("GPS Tower not found or location not previously set. Please enter my exact block location")
    {...}=
  else 

local function move(directionToMove,numSpacesToMove)
  if directionFacing == "north" then 
    if directionToMove == "south" then
      for i = 1,2 do turtle.turnLeft() end
      directionFacing = "south"
      for i = 1,numSpacesToMove do 
        turtle.forward()
        directions.north, directions.south = self:directionAdjuster(directions.north,directions.south)
      end
    elseif directionToMove == "east" then
      turtle.turnRight()
      directionFacing = "east"
      for i = 1,numSpacesToMove do turtle.forward() end
    elseif directionToMove == "west" then
      turtle.turnLeft()
      directionFacing = "west"
      for i = 1,numSpacesToMove do turtle,forward() end
    end
  end
end



local function recordLocation(fileName,tableData) -- A new name for fileWrite
  core.fileWrite(fileName,tableData)
end

local function getNewDirection(currentDirection,directionTurning) -- Returns string new direction facing.
  if CurrentDirection == "north" and directionTurning == "left" then
    return "west"
  elseif CurrentDirection == "north" and directionTurning == "right" then
    return "east"
  elseif CurrentDirection == "west" and directionTurning == "left" then
    return "south"
  elseif CurrentDirection == "west" and directionTurning == "right" then
    return "north"
  elseif CurrentDirection == "south" and directionTurning == "left" then
    return "east"
  elseif CurrentDirection == "south" and directionTurning == "right" then
    return "west"
  elseif CurrentDirection == "east" and directionTurning == "left" then
    return "north"
  elseif CurrentDirection == "east" and directionTurning == "right" then
    return "south"
  end
end

--Usages:
--returnTo("file",stringDirectionToTravelFirst,stringFileName)
--returnTo("waypoint",stringDirectionToTravelFirst,numNavNorthSouth,numNavEastWest)
--Also you can use moveTo with same syntax
local function returnTo(stringType,stringDirectionToTravelFirst,arg1,arg2,arg3)
  if stringType == "file" then
    if not fs.exists(arg1) then error("returnTo/moveTo Wrong arg #3, file not found!")
    else directions = core.loadConfig(arg1) end
    move(stringDirectionToTravelFirst,directions[textutils.unserialize(stringDirectionToTravelFirst)])
    for i , v in pairs(directions) do
      if v > 0 then move(i,v) end
    end
  elseif stringType == "waypoint" then
    
  else error("returnTo/moveTo Wrong arg #1, stringType can only be 'file' or 'waypoint'. Entered: " .. stringType) end
end

return {
  setStartingDirection = setStartingDirection,
  move = move,
  recordLocation = recordLocation,
  getNewDirection = getNewDirection,
  returnTo = returnTo,
  moveTo = returnTo
}