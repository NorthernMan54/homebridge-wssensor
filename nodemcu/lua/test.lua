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

local function mdns_wait_svc()
  if lua_mdns.getServices()== nil then
    print("WS Socket unavailable, waiting")
  else
    ws = lua_mdns.getServices()
    tmr.stop(1)
    print("WS Socket available http://"..ws.ipv4..":"..ws.port)
    lua_mdns = nil
    print("Heap Available: -post ws  " .. node.heap() )

  end
end

local function wifi_wait_ip()
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is "..wifi.sta.getip())
    print("====================================")
    tmr.stop(6)
    --wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED,node.restart())


    print("Heap Available: -mdns  " .. node.heap() ) -- 18720

    lua_mdns.mdns_query("_dht22._tcp")

    tmr.alarm(1, 2500, 1, mdns_wait_svc)
  end
end

print("Heap Available:  " .. node.heap()) -- 38984
config = require("config")
print("Heap Available: -c " .. node.heap()) -- 37248 1500
passwords = require("passwords")

-- led = require("led")
print("Heap Available: -l " .. node.heap()) -- 34200 3000
--bme = require("bme")
print("Heap Available: -b " .. node.heap()) -- 34504    0
--app = require("main")
print("Heap Available: -m " .. node.heap()) -- 27784 6000
-- gd = require("GarageDoorOpenSensor")
-- print("Heap Available: -gd " .. node.heap())
setup = require("setup")
print("Heap Available: -setup " .. node.heap()) -- 23280 4000
-- led.boot()
print("Heap Available: -boot " .. node.heap()) -- 24144

lua_mdns = require("lua-mdns")

--ms = require("motion")

setup.start()

tmr.alarm(1, 2500, 1, wifi_wait_ip)

-- Reboot if wifi doesn't connect in 60 seconds

tmr.alarm(6,60000, tmr.ALARM_SINGLE, node.restart)
