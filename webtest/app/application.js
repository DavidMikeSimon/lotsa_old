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

		var Chunk = WerldProto.Chunk;

		var ws = new WebSocket("ws://" + window.location.hostname + ":3000/websocket");
		ws.binaryType = 'arraybuffer';

		ws.onmessage = function (event) {
			var chunk = Chunk.decode(event.data);
			me.log(chunk);
		};

		ws.onopen = function (event) {
			me.log("Connected");
		};
	},

	log: function log(msg) {
		console.log(msg);
	}
};

module.exports = App;
