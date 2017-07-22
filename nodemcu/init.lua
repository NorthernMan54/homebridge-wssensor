config = require("config")
led = require("led")
bme = require("bme")
app = require("main")
gd = require("GarageDoorOpenSensor")
setup = require("setup")

led.boot()
setup.start()
-- Never gets here
