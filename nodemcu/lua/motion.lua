local module = {}

function module.start()
  -- Enable triggers for Motion sensor

  gpio.mode(config.SC501, gpio.INT, gpio.PULLUP)
  tm = tmr.now()
  last = 0
  connected = false;

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
    ws:connect('ws://bart:8081')
  end)


  function motionEvent(value)

    if value == last then
      print("Motion Event - False")
    else
      if connected == true then
        print("Motion Event", value, math.floor((tmr.now() - tm) / 1000000 + 0.5))
        tm = tmr.now()
        print("WS", ws)
        local response = sensors.read(value)
      ws:send(response, 1)
    else
      print( "Motion event not sent, no connection")
    end
  end
  last = value

end

gpio.trig(config.SC501, "both", motionEvent)
print("Motion Sensor Enabled")
end

return module
