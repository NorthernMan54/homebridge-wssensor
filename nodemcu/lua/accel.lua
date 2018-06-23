local module = {}

local mpu = require('mpu6050')

function module.start(wsserver)
  local tm = tmr.now()
  local last = 0
  local connected = false
  mpu.init()

  ws = websocket.createClient()
  ws:connect(wsserver)
  ws:on("connection", function(ws)
    print('got ws connection', ws)
    connected = true;
  end)
  ws:on("receive", function(sck, msg, opcode)
    print('\ngot message:', msg, opcode) -- opcode is 1 for text message, 2 for binary
    sck:send(mpu.read(), 1)
  end)
  ws:on("close", function(_, status)
    print('connection closed', status)
    connected = false;
    -- Reboot if connection lost
    node.restart()

  end)


  function motionEvent(value, interval)

    print("Heap Available: event  " .. node.heap() )
    -- Ignore sensor for first minute
    if tmr.time() > 1 then
      if value == last then
        print("Motion Event - False")
      else
        if connected == true then
          print("Motion Event", value, math.floor((tmr.now() - tm) / 1000000 + 0.5))
          tm = tmr.now()

          print("Heap Available: -sensors  " .. node.heap() )
          ws:send(mpu.read(value, interval), 1)
        else
          print( "Motion event not sent, no connection")
        end
      end
    else
      print( "Motion Event - Ignored, sensor warming up")
    end
    last = value
  end

  local movementA, movementG, Temperature = 0, 0, 0
  local interval = tmr.time()

  tmr.create():alarm(100, tmr.ALARM_AUTO, function()

    local trigger = false
    local status = nil
    if (tmr.time() - interval) > -1 -- Minimum event length is 1 second
    then
      uart.write(0, "-")
      local _movementA, _movementG, _Temperature = mpu.rawRead()
      if ( _movementA + _movementG > 0 )
      then
        -- Movement
        if ( movementA + movementG == 0 )
        then
          trigger = true
          status = true
        end
      else
        -- Movement stopped
        if ( movementA + movementG > 0 )
        then
          trigger = true
          status = false
        end
      end
      movementA = _movementA
      movementG = _movementG

      if ( trigger )
      then
        motionEvent(status, tmr.time() - interval)
        interval = tmr.time()
      end
    else
      uart.write(0, ".")
    end
  end)


  print("Acceleration Sensor Enabled")
end

return module
