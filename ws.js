'use strict';

var util = require('util');
var Utils = require('./lib/utils.js').Utils;
var WsSensorAccessory = require('./lib/accessory.js').Accessory;
var Websocket = require('./lib/websocket.js').Websocket;
var debug = require('debug')('wssensor');
var Advertise = require('./lib/advertise.js').Advertise;

var Accessory, Service, Characteristic, UUIDGen;
var cachedAccessories = 0;

var platform_name = "wssensor";
var plugin_name = "homebridge-" + platform_name;
var storagePath;

module.exports = function(homebridge) {
  console.log("homebridge API version: " + homebridge.version);

  Accessory = homebridge.platformAccessory;

  Service = homebridge.hap.Service;
  Characteristic = homebridge.hap.Characteristic;
  UUIDGen = homebridge.hap.uuid; // Universally Unique IDentifier

  storagePath = homebridge.user.storagePath();

  homebridge.registerPlatform(plugin_name, platform_name, WsSensorPlatform, true);
}

function WsSensorPlatform(log, config, api) {

  this.log = log;
  this.accessories = {};
  this.hap_accessories = {};

  debug("storagePath = %s", storagePath);
  debug("config = %s", JSON.stringify(config));

  if (typeof(config) !== "undefined" && config !== null) {
    this.port = config.port || {
      "port": 4050
    };
  } else {
    this.log.error("config undefined or null!");
    this.log("storagePath = %s", storagePath);
    process.exit(1);
  }

  var plugin_version = Utils.readPluginVersion();
  this.log("%s v%s", plugin_name, plugin_version);

  var params = {
    "log": this.log,
    "plugin_name": plugin_name,
    "port": this.port,
    "accessories": this.accessories,
    "Characteristic": Characteristic,
    "addAccessory": this.addAccessory.bind(this),
    "removeAccessory": this.removeAccessory.bind(this),
    "getAccessories": this.getAccessories.bind(this),
    "sendEvent": this.sendEvent.bind(this)
  }
  this.Websocket = new Websocket(params);

  this.Advertise = new Advertise(params);

  Utils.read_npmVersion(plugin_name, function(npm_version) {
    if (npm_version > plugin_version) {
      this.log("A new version %s is avaiable", npm_version);
    }
  }.bind(this));

  if (api) {
    this.api = api;

    this.api.on('didFinishLaunching', function() {
      this.log("Plugin - DidFinishLaunching");

      this.Websocket.startServer();

      this.Advertise.createAdvertisement();

      debug("Number of cached Accessories: %s", cachedAccessories);
      this.log("Number of Accessories: %s", Object.keys(this.accessories).length);

      //      this.Websocket.updateParams(params);

    }.bind(this));
    //debug("WsSensorPlatform %s", JSON.stringify(this.accessories));
  }
}

//{ "Hostname": "NODE-2BA0FF", "Model": "MS", "Version": "2.0", "Firmware": "2.1.0", "Data": {  "Motion": "1" }}


WsSensorPlatform.prototype.sendEvent = function(message) {
  var name = message.Hostname;

  for (var k in message.Data) {
    debug(k, message.Data[k]);
    switch (k) {
      case "Motion":
        var value = message.Data[k] > 0;
        this.accessories[name].getService(Service.MotionSensor).getCharacteristic(Characteristic.MotionDetected)
          .updateValue(value, null, this);
        break;

      case "Temperature":
        var value = message.Data[k];
        this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.CurrentTemperature)
          .updateValue(value, null, this);
        break;

      case "Humidity":
        var value = message.Data[k];
        this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.CurrentRelativeHumidity)
          .updateValue(value, null, this);
        break;

      case "Status":
        var value = message.Data[k];
        switch (value) {
          case 0:
            this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusActive)
              .updateValue(true);
            this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusFault)
              .updateValue(Characteristic.StatusFault.NO_FAULT);
            this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusLowBattery)
              .updateValue(Characteristic.StatusLowBattery.BATTERY_LEVEL_NORMAL);
            this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusTampered)
              .updateValue(Characteristic.StatusTampered.NOT_TAMPERED);
            break;
          default:
            this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusActive)
              .updateValue(false);
            this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusFault)
              .updateValue(Characteristic.StatusFault.GENERAL_FAULT);
            this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusLowBattery)
              .updateValue(Characteristic.StatusLowBattery.BATTERY_LEVEL_LOW);
            this.accessories[name].getService(Service.TemperatureSensor).getCharacteristic(Characteristic.StatusTampered)
              .updateValue(Characteristic.StatusTampered.TAMPERED);
        }
    }
  }
}


WsSensorPlatform.prototype.addAccessory = function(accessoryDef) {

  var name = accessoryDef.Hostname;
  var ack, message;
  var isValid;

  this.log("addAccessory", name);

  if (!this.accessories[name]) {
    var uuid = UUIDGen.generate(name);

    var newAccessory = new Accessory(name, uuid);
    newAccessory.reachable = true;
    newAccessory.context.service_name = accessoryDef.Model;

    newAccessory.getService(Service.AccessoryInformation)
      .setCharacteristic(Characteristic.Manufacturer, "WSSENSOR")
      .setCharacteristic(Characteristic.Model, accessoryDef.Model + " " + accessoryDef.Version)
      .setCharacteristic(Characteristic.SerialNumber, name);

    var sensors = accessoryDef.Model.split('-');

    for (var i = 0; i < sensors.length; i++) {
      switch (sensors[i]) {
        case "MS":
          newAccessory.addService(Service.MotionSensor, name);
          break;
        case "BME":
          newAccessory.addService(Service.TemperatureSensor, name);
          newAccessory
            .getService(Service.TemperatureSensor)
            .addCharacteristic(Characteristic.CurrentRelativeHumidity);
          break;
      }
    }
    this.accessories[name] = newAccessory;
    this.api.registerPlatformAccessories(plugin_name, platform_name, [newAccessory]);

  } else {
    debug("accessory already created");
  }
}

WsSensorPlatform.prototype.configureAccessory = function(accessory) {

  //debug("configureAccessory %s", JSON.stringify(accessory.services, null, 2));

  cachedAccessories++;
  var name = accessory.displayName;

  this.accessories[name] = accessory;

}

WsSensorPlatform.prototype.removeAccessory = function(name) {

  var ack, message;

  if (typeof(this.accessories[name]) !== "undefined") {
    debug("removeAccessory '%s'", name);

    this.api.unregisterPlatformAccessories(plugin_name, platform_name, [this.hap_accessories[name]]);
    delete this.accessories[name];
    delete this.hap_accessories[name];
    ack = true;
    message = "accessory '" + name + "' is removed.";
  } else {
    ack = false;
    message = "accessory '" + name + "' not found.";
  }
  this.log("removeAccessory %s", message);
  this.Websocket.sendAck(ack, message);
}

WsSensorPlatform.prototype.getAccessories = function(name) {

  var accessories = {};
  var def = {};
  var service, characteristics;

  switch (name) {
    case "all":
      for (var k in this.accessories) {
        //this.log("getAccessories %s", JSON.stringify(this.accessories[k], null, 2));
        service = this.accessories[k].service_name;
        characteristics = this.accessories[k].i_value;
        def = {
          "service": service,
          "characteristics": characteristics
        };
        accessories[k] = def;
      }
      break;

    default:
      service = this.accessories[name].service_name;
      characteristics = this.accessories[name].i_value;
      def = {
        "service": service,
        "characteristics": characteristics
      };
      accessories[name] = def;
  }

  //this.log("getAccessory %s", JSON.stringify(accessories, null, 2));
  this.Websocket.sendAccessories(accessories);
}

WsSensorPlatform.prototype.buildParams = function(accessoryDef) {

  var params = {
    "accessoryDef": accessoryDef,
    "log": this.log,
    "Service": Service,
    "Characteristic": Characteristic,
    "WebSocket": this.WebSocket
  }
  debug("configureAccessories %s", JSON.stringify(params));
  return params;
}
