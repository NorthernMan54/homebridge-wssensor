local module = {}

local function register_mdns()
  print("Registering service dht22 with mDNS")
  mdns.register(config.ID, {service="dht22", hardware='NodeMCU'})
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
    led.connected()
    register_mdns()
    tmr.stop(6)
    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED,wifi_reboot)
    app.start()
  end
end

local function wifi_reboot()
  print("REBOOT....")
  node.restart()
end

local function wifi_start(list_aps)
  if list_aps then
    local found = 0
    for key,value in pairs(list_aps) do
      if config.SSID and config.SSID[key] then
        wifi.setmode(wifi.STATION);
        wifi.sta.config(key,config.SSID[key])
        wifi.sta.connect()
        print("Connecting to " .. key .. " ...")
        found = 1
        --config.SSID = nil -- can save memory
        tmr.alarm(1, 2500, 1, wifi_wait_ip)
      end
    end
    if found == 0 then
      print("Error finding AP")
      led.error(1)
    end
  else
    print("Error getting AP list")
    led.error(2)
  end
end

function module.start()
  print("Setting Init Timer")
  -- reboot after 60 seconds if we don't get wifi
  tmr.alarm(6,60000, tmr.ALARM_SINGLE, wifi_reboot)
  print("Configuring Wifi ...")
  wifi.setmode(wifi.STATION);
  wifi.sta.getap(wifi_start)
end

return module
