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

--Create a blank file for easy server determination of code
if not fs.exists("auto_trash_bin.txt") then
  f = fs.open("auto_trash_bin.txt","w")
  f.close()
end

--Make it movable
shell.run("label set auto_trash_bin")

--Only display operating message from here on in.
term.clear()
term.setCursorPos(1,1)
print("Auto Trash Bin V1")

--Chest/shulker might already be connected.
--No point waiting only on peripheral change.
--This allows for easy setup as you build the bin enclosure.
os.startTimer(5)
repeat
  event = os.pullEvent()
until event == "timer" or event == "peripheral"

--If Chest / shulker not connected yet then reboot and retry.
--Note: This is silent so if not working then chest used is not supported unless added below.
chest = (listPeripheralsByName("chest","shulker")[1]) or (os.reboot())

while true do
  sleep(30)
  for slot = 1, peripheral.call(chest,"size") do
    peripheral.call(chest,"drop",slot)
  end
end
