local module = {}

function module.read()

  local alt = 320 -- altitude of the measurement place
  local device = bme280.init(config.bme280sda, config.bme280scl) -- bme280.init(sda, scl,
  local status, temp, humi, baro, dew

  if device == 2 then
    status = 0
    local P = bme280.baro()
    if P == 0 then
     baro = 0
     else 
       baro = P / 1000
    end
  
    --    print(string.format("QFE=%d.%03d", P/1000, P%1000))

    -- convert measure air pressure to sea level pressure
    --local QNH = bme280.qfe2qnh(P, alt)
    --    print(string.format("QNH=%d.%03d", QNH/1000, QNH%1000))

    local H, T = bme280.humi()
    --    print(string.format("T=%d.%02d", T/100, T%100))
    --    print(string.format("humidity=%d.%03d%%", H/1000, H%1000))

    temp = T / 100
    humi = H / 1000

    local D = bme280.dewpoint(H, T)
    dew = D / 100
    --    print(string.format("dew_point=%d.%02d", D/100, D%100))

    -- altimeter function - calculate altitude based on current sea level pressure (QNH) and measure pressure
    --    local P = bme280.baro()
    --    local curAlt = bme280.altitude(P, QNH)
    --    print(string.format("altitude=%d.%02d", curAlt/100, curAlt%100))
  else

    print( "BME280 Read Error %d", device )
    status = 1

  end

  return status, temp, humi, baro, dew

end

return module
