local module = {}

local function readSensor()
  local motion = gpio.read(config.SC501)
  local motionStatus = 0
  if tmr.time() < 1 then
    motionStatus = 1
  end
  return motion,motionStatus
end

function module.start(wsserver)
  gpio.mode(config.SC501, gpio.INT)
  local tm = tmr.now()
  local last = 0
  local connected = false;

  ws = websocket.createClient()
  ws:connect(wsserver)
  ws:on("connection", function(ws)
    print('got ws connection', ws)
    connected = true;
  end)
  ws:on("receive", function(sck, msg, opcode)
    print('got message:', msg, opcode) -- opcode is 1 for text message, 2 for binary
    local sensors = require('sensors')
    sck:send(sensors.read(readSensor()), 1)
  end)
  ws:on("close", function(_, status)
    print('connection closed', status)
    connected = false;
    -- Reboot if connection lost
    node.restart()

  end)


  function motionEvent(value)

    print("Heap Available: event  " .. node.heap() )
    -- Ignore sensor for first minute
    if tmr.time() > 1 then
      if value == last then
        print("Motion Event - False")
      else
        if connected == true then
          print("Motion Event", value, math.floor((tmr.now() - tm) / 1000000 + 0.5))
          tm = tmr.now()
          local sensors = require('mpu6050')
          print("Heap Available: -sensors  " .. node.heap() )
          ws:send(sensors.read(value,0), 1)
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
