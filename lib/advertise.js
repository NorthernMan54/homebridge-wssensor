'use strict';

var mdns = require('mdns');
var debug = require('debug')('wssensor');

var port, plugin_name, accessories, Characteristic, addAccessory, removeAccessory, getAccessories,sendEvent;

module.exports = {
  Advertise: Advertise
}

function Advertise(params) {
  this.log = params.log;
  port = params.port;
  plugin_name = params.plugin_name;
  accessories = params.accessories;
  Characteristic = params.Characteristic;
  addAccessory = params.addAccessory;
  removeAccessory = params.removeAccessory;
  getAccessories = params.getAccessories;
  sendEvent = params.sendEvent;
}

Advertise.prototype.createAdvertisement = function () {
  var ad = mdns.createAdvertisement(mdns.tcp('wssensor'), port);
  ad.start();
  debug("Sensor Advertised 'wssensor'",port);
}
