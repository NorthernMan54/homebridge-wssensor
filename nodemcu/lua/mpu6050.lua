local module = {}

local id  = 0 -- always 0

local MPU6050SlaveAddress = 0x68

local AccelScaleFactor = 1;   -- sensitivity scale factor respective to full scale setting provided in datasheet
local GyroScaleFactor = 1;

local MPU6050_REGISTER_SMPLRT_DIV   =  0x19
local MPU6050_REGISTER_USER_CTRL    =  0x6A
local MPU6050_REGISTER_PWR_MGMT_1   =  0x6B
local MPU6050_REGISTER_PWR_MGMT_2   =  0x6C
local MPU6050_REGISTER_CONFIG       =  0x1A
local MPU6050_REGISTER_GYRO_CONFIG  =  0x1B
local MPU6050_REGISTER_ACCEL_CONFIG =  0x1C
local MPU6050_REGISTER_FIFO_EN      =  0x23
local MPU6050_REGISTER_INT_ENABLE   =  0x38
local MPU6050_REGISTER_ACCEL_XOUT_H =  0x3B
local MPU6050_REGISTER_SIGNAL_PATH_RESET  = 0x68

function module.start()
  -- Initialize sensors
  print(i2c.setup(id, config.mpu6050sda, config.mpu6050scl, i2c.SLOW))   -- initialize i2c
  print(id,config.mpu6050sda,config.mpu6050scl,i2c.SLOW)
  MPU6050_Init()
  _AccelX = 0
  _AccelY = 0
  _AccelZ = 0

end

function I2C_Write(deviceAddress, regAddress, data)
    i2c.start(id)       -- send start condition
    if (i2c.address(id, deviceAddress, i2c.TRANSMITTER))-- set slave address and transmit direction
    then
        i2c.write(id, regAddress)  -- write address to slave
        i2c.write(id, data)  -- write data to slave
        i2c.stop(id)    -- send stop condition
    else
        print("I2C_Write fails")
    end
end

function I2C_Read(deviceAddress, regAddress, SizeOfDataToRead)
    response = 0;
    i2c.start(id)       -- send start condition
    if (i2c.address(id, deviceAddress, i2c.TRANSMITTER))-- set slave address and transmit direction
    then
        i2c.write(id, regAddress)  -- write address to slave
        i2c.stop(id)    -- send stop condition
        i2c.start(id)   -- send start condition
        i2c.address(id, deviceAddress, i2c.RECEIVER)-- set slave address and receive direction
        response = i2c.read(id, SizeOfDataToRead)   -- read defined length response from slave
        i2c.stop(id)    -- send stop condition
        return response
    else
        print("I2C_Read fails")
    end
    return response
end

function unsignTosigned16bit(num)   -- convert unsigned 16-bit no. to signed 16-bit no.
    if num > 32768 then
        num = num - 65536
    end
    return num
end

function MPU6050_Init() --configure MPU6050
    tmr.delay(150000)
    I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_SMPLRT_DIV, 0x07)
    I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_PWR_MGMT_1, 0x01)
    I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_PWR_MGMT_2, 0x00)
    I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_CONFIG, 0x00)
    I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_GYRO_CONFIG, 0x00)-- set +/-250 degree/second full scale
    I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_ACCEL_CONFIG, 0x00)-- set +/- 2g full scale
    I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_FIFO_EN, 0x00)
    I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_INT_ENABLE, 0x01)
    I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_SIGNAL_PATH_RESET, 0x00)
    I2C_Write(MPU6050SlaveAddress, MPU6050_REGISTER_USER_CTRL, 0x00)
end

function _Round(X)
  return math.floor(math.abs(X/300))
end



while true do   --read and print accelero, gyro and temperature value
    data = I2C_Read(MPU6050SlaveAddress, MPU6050_REGISTER_ACCEL_XOUT_H, 14)

    _AccelX = AccelX
    _AccelY = AccelY
    _AccelZ = AccelZ
    _GyroX = GyroX
    _GyroY = GyroY
    _GyroZ = GyroZ

    AccelX = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 1), 8), string.byte(data, 2))))
    AccelY = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 3), 8), string.byte(data, 4))))
    AccelZ = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 5), 8), string.byte(data, 6))))
    Temperature = unsignTosigned16bit(bit.bor(bit.lshift(string.byte(data,7), 8), string.byte(data,8)))
    GyroX = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 9), 8), string.byte(data, 10))))
    GyroY = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 11), 8), string.byte(data, 12))))
    GyroZ = unsignTosigned16bit((bit.bor(bit.lshift(string.byte(data, 13), 8), string.byte(data, 14))))

    AccelX = AccelX/AccelScaleFactor   -- divide each with their sensitivity scale factor
    AccelY = AccelY/AccelScaleFactor
    AccelZ = AccelZ/AccelScaleFactor
    Temperature = Temperature/340+36.53-- temperature formula
    GyroX = GyroX/GyroScaleFactor
    GyroY = GyroY/GyroScaleFactor
    GyroZ = GyroZ/GyroScaleFactor

    movementA = _Round(_AccelX - AccelX)+ _Round(_AccelY - AccelY)+ _Round(_AccelZ - AccelZ)
    movementG = _Round(_GyroX - GyroX)+ _Round(_GyroY - GyroY)+ _Round(_GyroZ - GyroZ)

    print(string.format("Ax:%d Ay:%d Az:%d T:%+.1f Gx:%d Gy:%d Gz:%d -> MA:%d MG:%d",
                        _Round(_AccelX - AccelX), _Round(_AccelY - AccelY),
                        _Round(_AccelZ - AccelZ), Temperature, _Round(_GyroX - GyroX),
                        _Round(_GyroY - GyroY), _Round(_GyroZ - GyroZ),
                        movementA, movementG))
    _AccelX = AccelX

    tmr.delay(100000)   -- 100ms timer delay
end

--
-- END of MPU6050 Copy and Paste
--


function module.read(motion, motionStatus, current)
  -- Read sensors
  local status
  local moist_value = 0
  local temp = -999
  local humi = -999
  local baro = -999
  local dew = -999
  local gdstring = ""
  local motionstring = ""
  local tempstring = ""
  local currentstring = ""
  local filler = ""

  if string.find(config.Model, "BME") then
    local bme = require("bme")
    status, temp, humi, baro, dew = bme.read()
    if status ~= 0 then
      temp = -999
      humi = -999
      baro = -999
      dew = -999
    end
    tempstring = "\"Temperature\": "..temp..
    ", \"Humidity\": "..humi..", \"Moisture\": "..moist_value..
    ", \"Status\": "..status..", \"Barometer\": "..baro..", \"Dew\": "..dew
    filler = ","
    bme = nil
  end
  if string.find(config.Model, "DHT") then
    status, temp, humi, temp_dec, humi_dec = dht.read(config.DHT22)
    if status ~= 0 then
      temp = -999
      humi = -999
      baro = -999
      dew = -999
    end
    tempstring = "\"Temperature\": "..temp..
    ", \"Humidity\": "..humi..", \"Moisture\": "..moist_value..
    ", \"Status\": "..status..", \"Barometer\": "..baro..", \"Dew\": "..dew
    filler = ","
  end

  if string.find(config.Model, "MS") then
    motionstring = filler.." \"Motion\": "..motion..", \"MotionStatus\": "..motionStatus.." "
  end

  if string.find(config.Model, "GD") then
    local green, red = gd.getDoorStatus()
    gdstring = filler.." \"Green\": \""..green.."\", \"Red\": \""..red.."\""
  end

  if current ~= nil then
    if string.find(config.Model, "CU") then
      currentstring = filler.." \"Current\": "..current
    end
  end
  --      print("Heap Available:" .. node.heap())
  --      print("33")
  majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
  --      print("35")
  local response =
  "{ \"Hostname\": \""..config.ID.."\", \"Model\": \""..config.Model.."\", \"Version\": \""..config.Version..
  "\", \"Firmware\": \""..majorVer.."."..minorVer.."."..devVer.."\", \"Data\": { "..tempstring..""
..gdstring..""..motionstring..""..currentstring.." }}\n"
print(response)

return response
end

return module
