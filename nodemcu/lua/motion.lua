local module = {}

function module.start(wsserver)
  -- Enable triggers for Motion sensor

  sensors = require('sensors')
  print("Heap Available: -sensors  " .. node.heap() )
  gpio.mode(config.SC501, gpio.INT, gpio.PULLUP)
  tm = tmr.now()
  last = 0
  connected = false;

  ws = websocket.createClient()
  ws:connect(wsserver)
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
    wsReOpen:register(10000, tmr.ALARM_SINGLE, function (t) ws:connect(wsserver); t:unregister() end)
    wsReOpen:start()

  end)


  function motionEvent(value)

    print("Heap Available: event  " .. node.heap() )
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
