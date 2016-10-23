"use strict";

var $ = require("jquery");
var ProtoBuf = require("protobufjs");

var App = {
	init: function init() {
		var me = this;
		$(document).ready(function() {
			ProtoBuf.loadProtoFile("proto/werld.proto", function (err, builder) {
				if (err) { throw err; }
				me.start(builder.build("WerldProto"));
			});
		});
	},

	start: function start(WerldProto) {
		var me = this;
		me.log("Starting...");

		var ws = new WebSocket("ws://" + window.location.hostname + ":3000/websocket");
		ws.binaryType = 'arraybuffer';

		ws.onopen = function (event) {
			me.log("Connected");
		};

		ws.onerror = function (event) {
			me.log("WebSocket error", event);
		}

		ws.onclose = function (event) {
			me.log("Connection closed", event);
		}

		ws.onmessage = function (event) {
			var msg = WerldProto.MessageToClient.decode(event.data);
			me.log(msg);
		};
	},

	log: function log(msg) {
		console.log(msg);
	}
};

module.exports = App;
