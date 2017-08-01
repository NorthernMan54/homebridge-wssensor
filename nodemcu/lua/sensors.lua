local module = {}

function module.start()
  -- Initial sensors

end

function module.read(motion)
  -- Read sensors
  moist_value = 0
  temp = -999
  humi = -999
  baro = -999
  dew = -999
  local gdstring = ""
  local motionstring = ""
  local tempstring = ""
  local filler = ""

  if string.find(config.Model,"BME") then
    status, temp, humi, baro, dew = bme.read()
    tempstring = "\"Temperature\": "..temp..
    ", \"Humidity\": "..humi..", \"Moisture\": "..moist_value..
    ", \"Status\": "..status..", \"Barometer\": "..baro..", \"Dew\": "..dew.." "
    filler = ","
  end
  if string.find(config.Model,"DHT") then
    status, temp, humi, temp_dec, humi_dec = dht.read(config.DHT22)
    tempstring = "\"Temperature\": "..temp..
    ", \"Humidity\": "..humi..", \"Moisture\": "..moist_value..
    ", \"Status\": "..status..", \"Barometer\": "..baro..", \"Dew\": "..dew.." "
    filler = ","
  end

  if string.find(config.Model,"MS") then
    motionstring = filler.." \"Motion\": \""..motion.."\""
  end

  if string.find(config.Model,"GD") then
    local green, red = gd.getDoorStatus()
    gdstring = filler.." \"Green\": \""..green.."\", \"Red\": \""..red.."\""
  end
--      print("Heap Available:" .. node.heap())
--      print("33")
  majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
--      print("35")
  local response =
  "{ \"Hostname\": \""..config.ID.."\", \"Model\": \""..config.Model.."\", \"Version\": \""..config.Version..
  "\", \"Firmware\": \""..majorVer.."."..minorVer.."."..devVer.."\", \"Data\": { "..tempstring..""
  ..gdstring..""..motionstring.." }}\n"
  print(response)

  return response
end

return module