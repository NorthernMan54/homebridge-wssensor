
config = require("config")
print("Heap Available: -c " .. node.heap())
passwords = require("passwords")

led = require("led")
print("Heap Available: -l " .. node.heap())
bme = require("bme")
print("Heap Available: -b " .. node.heap())
app = require("main")
print("Heap Available: -m " .. node.heap())
-- gd = require("GarageDoorOpenSensor")
-- print("Heap Available: -gd " .. node.heap())
setup = require("setup")
print("Heap Available: -setup " .. node.heap())
led.boot()
print("Heap Available: -boot " .. node.heap())

ms = require("motion")

setup.start()
print("Heap Available: -start " .. node.heap())
-- Never gets here
