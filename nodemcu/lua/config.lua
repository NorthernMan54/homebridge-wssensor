local module = {}

-- Options are DHT or DHT-YL, used by homebridge to determine if moisture data is valid.
module.Model = "BME-GD"
module.Version = "2.2"

module.ID = wifi.sta.gethostname()

-- LED state
module.ledState = 1 -- 0: fully disabled, 1: LEDs on, 2: Connected off (Boot/Error only)

module.ledRed = 0   -- gpio16
module.ledBlue = 4  -- gpio2
module.sensor = 7   -- gpio14

-- Garage Door relay and status sensors

module.gdrelay = 2    -- Relay to control garage door
module.gdclosed = 7   -- Magnetic reed sensor to detect door closed state
module.gdopened = 1   -- Magnetic reed sensor to detect door open state

-- BME280 sensor

module.bme280scl = 5  -- D5
module.bme280sda = 6  -- D6

-- MPU6050 / Acceleration sensor

module.mpu6050scl = 6  -- D5 and D6 didn't work with the MPU 6050 for some reason
module.mpu6050sda = 7  --

-- DHT-22

module.DHT22 = 2    -- D2

-- Moisture Sensor

module.YL69 = 0     -- adc pin 0
module.YL69P = 7    -- 5 with DHT and 7 with BME

-- Motion Sensor

module.SC501 = 2    -- AM312 Motion Sensor
module.SW420 = 2    -- SW-420 Vibration Sensor

-- Hardware Timers
-- 1 - Used by LED to flash LED's during setup
-- 2 - Used by main, to read moisture sensor
-- 6 - Used by setup, If wifi setup doesn't work REBOOT
-- wsReOpen - Used by Motion, to re-open websocket connection in case of connection loss


return module
