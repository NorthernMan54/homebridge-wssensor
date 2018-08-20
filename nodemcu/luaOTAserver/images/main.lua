--SAFETRIM

local lua_mdns = nil

local function hb_found(ws)
  print("WS Socket available http://"..ws.ipv4..":"..ws.port)
  lua_mdns = nil
  print("Heap Available: -pre motion  " .. node.heap() )
  print("Reset watch dog")
  tmr.softwd(600)
  led.connected()
  led=nil

  -- Load personaility module

  if string.find(config.Model, "ACL") then
    ms = require('accel')
  else
    if string.find(config.Model, "GD") then
      ms = require('garage')
    else
      ms = require('motion')
    end
  end

  package.loaded["main"]=nil
  print("Heap Available: personaility  " .. node.heap() )
  ms.start("ws://"..ws.ipv4..":"..ws.port)
  ms=nil
end

local function wifi_ready()
  print("\n====================================")
  print("Name is:         "..config.ID)
  print("ESP8266 mode is: " .. wifi.getmode())
  print("MAC address is: " .. wifi.ap.getmac())
  print("IP is "..wifi.sta.getip())
  print("====================================")
  setup = nil
  wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)

  print("Heap Available: -mdns  " .. node.heap() ) -- 18720

  led.mdns()
  lua_mdns = require("lua-mdns")
  lua_mdns.mdns_query("_"..config.mdnsName.."._tcp", hb_found)
end

return {entry = function(msg)
  -- Start of code, reboot if not connected within 60 seconds
  tmr.softwd(60)
  print("Heap Available:  " .. node.heap()) -- 38984
  config = require("config-"..wifi.sta.gethostname())
  package.loaded["config-"..wifi.sta.gethostname()]=nil
  print("Heap Available: config " .. node.heap()) -- 37248 1500
  led = require("led")
  print("Heap Available: led " .. node.heap()) -- 34200 3000ß
  --local setup = require("setup")
  --collectgarbage()
  --print("Heap Available: setup " .. node.heap()) -- 23280 4000

  led.boot()
  wifi_ready()
end}
