local module = {}

local function register_mdns()
  print("Registering service dht22 with mDNS")
  mdns.register(config.ID, {service="dht22", hardware='NodeMCU'})
end



local function wifi_reboot()
  print("REBOOT....")
  node.restart()
end

local function wifi_start(list_aps)
  if list_aps then
    local found = 0
    for key,value in pairs(list_aps) do
      if passwords.SSID and passwords.SSID[key] then
        wifi.setmode(wifi.STATION);
        wifi.sta.config(key,passwords.SSID[key])
        wifi.sta.connect()
        print("Connecting to " .. key .. " ...")
        found = 1
        --config.SSID = nil -- can save memory

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

  print("Configuring Wifi ...")
  wifi.setmode(wifi.STATION);
  wifi.sta.getap(wifi_start)
end

return module
