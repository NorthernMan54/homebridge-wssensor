config = require("config")
passwords = require("passwords")
led = require("led")
bme = require("bme")
app = require("main")
-- gd = require("GarageDoorOpenSensor")
setup = require("setup")
sensors = require("sensors")
ms = require("motion")

led.boot()

setup.start()
-- Never gets here
