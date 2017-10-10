local function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

local function hb_found(ws)
  print("WS Socket available http://"..ws.ipv4..":"..ws.port)
  lua_mdns = nil
  print("Cancelling watch dog")
  tmr.softwd(-1)
  led.connected()

  collectgarbage()
  print("Heap Available: -pre motion  " .. node.heap() )
  ms = require('vibration')
  print("Heap Available: -motion  " .. node.heap() )
  ms.start("ws://"..ws.ipv4..":"..ws.port)

end

local function wifi_ready()
  print("\n====================================")
  print("ESP8266 mode is: " .. wifi.getmode())
  print("MAC address is: " .. wifi.ap.getmac())
  print("IP is "..wifi.sta.getip())
  print("====================================")
  setup=nil
  wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)

  print("Heap Available: -mdns  " .. node.heap() ) -- 18720

  led.mdns()
  lua_mdns.mdns_query("_wssensor._tcp", hb_found)
end


-- Start of code
tmr.softwd(60)

print("Heap Available:  " .. node.heap()) -- 38984
config = require("config")
print("Heap Available: -c " .. node.heap()) -- 37248 1500
passwords = require("passwords")

led = require("led")
print("Heap Available: -l " .. node.heap()) -- 34200 3000
--bme = require("bme")
print("Heap Available: -b " .. node.heap()) -- 34504    0
--app = require("main")
print("Heap Available: -m " .. node.heap()) -- 27784 6000
-- gd = require("GarageDoorOpenSensor")
-- print("Heap Available: -gd " .. node.heap())
local setup = require("setup")
print("Heap Available: -setup " .. node.heap()) -- 23280 4000
-- led.boot()
print("Heap Available: -boot " .. node.heap()) -- 24144

lua_mdns = require("lua-mdns")
led.boot()
setup.start(wifi_ready)
