# homebridge-wssensor
Plugin for NodeMCU Based sensors using WebSockets for realtime updates

# Design Concept

* Realtime device communications via WebSockets, and device discovery via mDNS
* Homebridge Plugin creates a websocket server to receive updates from nodemcu devices.
* Plugin advertises websocket server onto network via mDNS
* NodeMCU discovers server by watching for mDNS advertisement
* NodeMCU sends message to plugin containing sensor config
* Plugin creates HK accessory for sensor ( Have ability to alias sensor name in config.json )
* Plugin sends sensor state changes in realtime to plugin via WebSockets
* Default publishing every minute?
* Have sensor support multiple websocket servers?
* Support for Legacy mcuiot mode?
* Support for data logging to mcuiot-logger?

# Supported sensors

* HC-SR501 Motion Sensor Module

# Backlog - Plugin

* Homebridge Plugin creates a websocket server to receive updates from nodemcu devices.  -- Done
* Plugin advertises websocket server onto network via mDNS -- Done
* Plugin creates HK accessory for sensor ( Have ability to alias sensor name in config.json )  -- 1/2 done
* Plugin sends sensor state changes in realtime to HomeKit -- Done
* Plugin use Low Battery or other status for warmup period
* Default publishing every minute?  -- Done
* Support for Legacy mcuiot mode?
* Support for data logging to mcuiot-logger?

# Backlog - NodeMCU

* NodeMCU discovers server by watching for mDNS advertisement -- Done
* NodeMCU sends message to plugin containing sensor config -- Done
* Sensor sends state changes in realtime to plugin via WebSockets -- Done
* Allow sensor to warm up before publishing, I believe I read 1 minute -- Done
* Have sensor send not available status during warm up period
* Default publishing every minute?
* Have sensor support multiple websocket servers?
* Support for Legacy mcuiot mode?
* Support for data logging to mcuiot-logger?
* Stop committing passwords to github!! - Done

# Installation - homebridge-wssensor

# Installation - NodeMCU

# Configuration - homebridge-wssensor

``{
  "platform" : "wssensor",
  "name" : "wssensor",
  "port": 8081
}
``

# Configuration - NodeMCU

# Credits

* cflurin - Borrowed websocket implementation from homebridge-websocket
