--[[
Concrete Buster turtle
Ensure that:
-Turtle is facing water 
OR 
-Dust will be touching water
]]

local chest = peripheral.find("minecraft:chest")
local turtleDir="west"  --can also be network address
shell.run("label set concrete_processor")

term.clear()
term.setCursorPos(1,1)
print("Concrete Breaker V1.1")
turtle.dig()

turtle.select(1)
while true do
  local info = turtle.getItemDetail(1)
  if info and not string.find(info.name,"powder") then
    chest.pullItems(turtleDir,1)
  end
  sleep()
  local chestInfo = chest.list()
  for i,k in pairs(chestInfo) do
    -- turtle.select(i)
    local check = chestInfo[i].name
    if string.find(check,"powder") then
      chest.pushItems(turtleDir,i)
      for i = 1,info.count do
        if turtle.place() then 
          turtle.dig()
          chest.pullItems(turtleDir,2,1,i)
        end 
      end
    end 
  end
end