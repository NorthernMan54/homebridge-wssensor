# homebridge-wssensor ESP8266 LUA Code

LUA programs for a nodeMCU device to read various sensors and integrate into homebridge-wssensor.  Supports direct notification and alerting of motion events from a PIR motion sensor.

# Hardware

1. Bill of materials
   - nodeMCU / esp8266 dev kit
   - dht22 Temperature / Humidity Sensor
	Or
   - BME280 Bosch DIGITAL HUMIDITY, PRESSURE AND TEMPERATURE SENSOR
   - PIR Monition Sensor ( https://www.aliexpress.com/item/Mini-IR-Pyroelectric-Infrared-PIR-Motion-Human-Sensor-Automatic-Detector-Module-high-reliability-12mm-x-25mm/32749737125.html?spm=a2g0s.9042311.0.0.6ec74c4dwcSLq4 )

# Circuit Diagrams

## BME-MS

![BME-MS](ESP8266%20-%20WSSensor_bb.jpg)

![BME-MS](ESP8266%20-%20WSSensor_schem.jpg)

# nodeMCU Firmware

1. Using http://nodemcu-build.com, create a custom firmware containing at least
   these modules:

   adc,bit,bme280,dht,file,gpio,i2c,mdns,net,node,tmr,uart,websocket,wifi


2. Please use esptool to install the float firmware onto your nodemcu.  There are alot of guides for this, so I won't repeat it here.

# Configuration

1. WIFI Setup - Copy passwords_sample.lua to passwords.lua and add your wifi SSID and passwords.  Please note
   that the configuration supports multiple wifi networks, one per config line.
   ```
   module.SSID["SSID1"] = { ssid="SSID1", pwd = "password" }
   ```

2. Model - Either DHT or BME, used by homebridge-wssensor to determine if Moisture
   sensor is included.
   ```
   module.Model = "DHT"
   or
   module.Model = "BME"
   ```

# Lua Program installation

1. Please use ESPlorer to install the lua files on the device.

config.lua
setup.lua
test.lua
passwords.lua
led.lua
lua-mdns.lua

ACL / MPU6050

accel.lua
mpu6050.lua





2. Reboot your device

3. Output from boot via the serial console should look like this.

```
NodeMCU custom build by frightanic.com
	branch: master
	commit: cdaf6344457ae427d8c06ac28a645047f9e0f588
	SSL: false
	modules: adc,am2320,bit,dht,file,gpio,mdns,net,node,tmr,uart,wifi
 build 	built on: 2016-06-27 22:58
 powered by Lua 5.1.4 on SDK 1.5.1(e67da894)
Booting...
Setting Init Timer
Configuring Wifi ...
> Connecting to XXXXXXX ...
IP unavailable, Waiting...

====================================
ESP8266 mode is: 1
MAC address is: 5e:cf:7f:18:a6:b3
IP is 192.168.1.146
====================================
```
