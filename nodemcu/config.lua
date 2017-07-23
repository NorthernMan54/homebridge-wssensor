local module = {}

-- Options are DHT or DHT-YL, used by homebridge to determine if moisture data is valid.
module.Model = "MS"
module.Version = "2.0"

module.ID = wifi.sta.gethostname()

module.ledRed = 0 -- gpio16
module.ledBlue = 4 -- gpio2
module.sensor = 7 -- gpio14

module.bme280scl = 5  -- D5
module.bme280sda = 6  -- D6

module.DHT22 = 2 -- D2
module.YL69 = 0 -- adc pin 0

module.SC501 = 2 -- D3

return module
