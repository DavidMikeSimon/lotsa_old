"use strict";

var $ = require("jquery");

var App = {
	init: function init() {
		var me = this;
		$(document).ready(function() { me.start(); });
	},

	start: function start() {
		var me = this;
		me.log("Starting...");

		var ws = new WebSocket("ws://" + window.location.hostname + ":3000/websocket");

		ws.onopen = function (event) {
			me.log("Connected");
		};

		ws.onmessage = function (event) {
			me.log("Received " + event.data);
		};
	},

	log: function log(msg) {
		console.log(msg);
	}
};

module.exports = App;
