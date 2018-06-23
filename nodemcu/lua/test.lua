local lua_mdns = nil

local function hb_found(ws)
  print("WS Socket available http://"..ws.ipv4..":"..ws.port)
  lua_mdns = nil
  print("Reset watch dog")
  tmr.softwd(600)
  led.connected()

  collectgarbage()
  print("Heap Available: -pre motion  " .. node.heap() )

  -- Load personaility module

  if string.find(config.Model, "ACL") then
    ms = require('accel')
  end
  if string.find(config.Model, "MS") then
    ms = require('motion')
  end

  print("Heap Available: personaility  " .. node.heap() )
  ms.start("ws://"..ws.ipv4..":"..ws.port)

end

local function wifi_ready()
  print("\n====================================")
  print("Name is:         "..config.ID)
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
print("Heap Available: config " .. node.heap()) -- 37248 1500
passwords = require("passwords")
print("Heap Available: passwords " .. node.heap()) -- 37248 1500
led = require("led")
print("Heap Available: led " .. node.heap()) -- 34200 3000
if string.find(config.Model, "BME") then
  bme = require("bme")
  print("Heap Available: bme" .. node.heap()) -- 34504    0
end

local setup = require("setup")
collectgarbage()
print("Heap Available: setup " .. node.heap()) -- 23280 4000

lua_mdns = require("lua-mdns")
print("Heap Available: mdns " .. node.heap()) -- 24144
led.boot()
setup.start(wifi_ready)
