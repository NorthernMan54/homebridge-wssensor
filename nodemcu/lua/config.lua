local module = {}

-- Options are DHT or DHT-YL, used by homebridge to determine if moisture data is valid.
module.Model = "BME-MS"
module.Version = "2.0"

module.ID = wifi.sta.gethostname()

module.ledRed = 0 -- gpio16
module.ledBlue = 4 -- gpio2
module.sensor = 7 -- gpio14

module.bme280scl = 6  -- D5
module.bme280sda = 7  -- D6

module.DHT22 = 2 -- D2
module.YL69 = 0 -- adc pin 0
module.YL69P = 7 -- 5 with DHT and 7 with BME

module.SC501 = 5 -- AM312 Motion Sensor
module.SW420 = 2 -- SW-420 Vibration Sensor

-- Hardware Timers
-- 1 - Used by LED to flash LED's during setup
-- 2 - Used by main, to read moisture sensor
-- 6 - Used by setup, If wifi setup doesn't work REBOOT
-- wsReOpen - Used by Motion, to re-open websocket connection in case of connection loss


return module
