local module = {}

function module.start()
-- Turn off YL-69
gpio.mode(config.YL69P, gpio.OUTPUT)
gpio.write(config.YL69P, gpio.LOW)
 -- Start a simple http server
print("Web Server Started")
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
  conn:on("receive",function(conn,payload)
    led.flashRed()
    print(payload)
    gpio.write(config.YL69P, gpio.HIGH)
    tmr.alarm(2,1,tmr.ALARM_SINGLE,function()
      moist_value=adc.read(config.YL69)
      gpio.write(config.YL69P, gpio.LOW)
      temp = -999
      humi = -999
      baro = -999
      dew = -999
      gdstring = ""

      if string.find(config.Model,"BME") then
        status, temp, humi, baro, dew = bme.read()
      else
        status, temp, humi, temp_dec, humi_dec = dht.read(config.DHT22)
      end

--      print("Heap Available:" .. node.heap())
      if string.find(config.Model,"GD") then
        green, red = gd.getDoorStatus()
        gdstring = ", \"Green\": \""..green.."\", \"Red\": \""..red.."\""
      end
--      print("Heap Available:" .. node.heap())
--      print("33")
      majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
--      print("35")
      print("Status: "..status.."\nTemp: "..temp.."\nHumi: "..humi.."\nMoisture: "..moist_value..
      "\nBaro: "..baro.."\nDew: "..dew.."\n")
      local response = { "HTTP/1.1 200 OK\n", "Server: ESP (nodeMCU) "..chipid.."\n",
      "Content-Type: application/json\n",
      "Access-Control-Allow-Origin: *\n\n",
      "{ \"Hostname\": \""..config.ID.."\", \"Model\": \""..config.Model.."\", \"Version\": \""..config.Version..
      "\", \"Firmware\": \""..majorVer.."."..minorVer.."."..devVer.."\", \"Data\": {\"Temperature\": "..temp..
      ", \"Humidity\": "..humi..", \"Moisture\": "..moist_value..
      ", \"Status\": "..status..", \"Barometer\": "..baro..", \"Dew\": "..dew..""..gdstring.." }}\n" }

      local function sender (conn)
        if #response>0 then conn:send(table.remove(response,1))
        else conn:close()
        end
      end
      conn:on("sent", sender)
      sender(conn)
    end)
  end)
  conn:on("sent",function(conn) conn:close() end)
end)

end


return module
