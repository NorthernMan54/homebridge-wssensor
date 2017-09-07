local module = {}

function module.start()
  -- Enable triggers for Motion sensor

  gpio.mode(config.SC501, gpio.INT, gpio.PULLUP)
  tm = tmr.now()
  last = 0
  connected = false;

  res = sdns.mdns_query()
  if (res) then
    for k, v in pairs(res) do
      -- output key name
      print(k)
      for k1, v1 in pairs(v) do
        -- output service descriptor fields
        print('  '..k1..': '..v1)
      end
    end
  else
    print('no result')
  end

  ws = websocket.createClient()
  ws:connect('ws://bart:8081')
  ws:on("connection", function(ws)
    print('got ws connection', ws)
    connected = true;
  end)
  ws:on("receive", function(_, msg, opcode)
    print('got message:', msg, opcode) -- opcode is 1 for text message, 2 for binary
  end)
  ws:on("close", function(_, status)
    print('connection closed', status)
    connected = false;
    local wsReOpen = tmr.create()
    wsReOpen:register(10000, tmr.ALARM_SINGLE, function (t) ws:connect('ws://bart:8081'); t:unregister() end)
    wsReOpen:start()

  end)


  function motionEvent(value)

    -- Ignore sensor for first minute
    if tmr.time() > 60 then
      if value == last then
        print("Motion Event - False")
      else
        if connected == true then
          print("Motion Event", value, math.floor((tmr.now() - tm) / 1000000 + 0.5))
          tm = tmr.now()
          ws:send(sensors.read(value), 1)
        else
          print( "Motion event not sent, no connection")
        end
      end
    else
      print( "Motion Event - Ignored, sensor warming up")
    end
    last = value
  end

  gpio.trig(config.SC501, "both", motionEvent)
  print("Motion Sensor Enabled")
end

return module
