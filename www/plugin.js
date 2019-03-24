
var exec = require('cordova/exec');

var PLUGIN_NAME = 'CordovaPluginACRCloud';

var CordovaPluginACRCloud = {
  init: function(accessKey, accessSecret, host, cb) {
      exec(cb, null, PLUGIN_NAME, 'init', [accessKey, accessSecret, host]);
  },
  startRecognition: function(cb) {
      exec(cb, null, PLUGIN_NAME, 'startRecognition', []);
  },
  stopRecognition: function(cb) {
      exec(cb, null, PLUGIN_NAME, 'stopRecognition', []);
  },
  watchForVolumeChange: function(cb) {
      exec(cb, null, PLUGIN_NAME, 'watchForVolumeChange', []);
  }
};

module.exports = CordovaPluginACRCloud;
