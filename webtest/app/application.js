"use strict";

var $ = require("jquery");
var _ = require("lodash");
var ProtoBuf = require("protobufjs");
var SVG = require("svg.js");
var ReconnectingWebSocket = require("reconnecting-websocket");

var GRID_CELLS = 16;
var GRID_CELL_SIZE = 32;
var GRID_CELL_GAP = 1;

var Application = {
	init: function init() {
		var me = this;
		$(document).ready(function() {
			ProtoBuf.loadProtoFile("proto/werld.proto", function (err, builder) {
				if (err) { throw err; }
				var sideLen = GRID_CELLS*(GRID_CELL_SIZE + GRID_CELL_GAP);
				me.gridSvg = SVG('grid').size(sideLen, sideLen);
				me.gridCells = [];
				for (var i = 0; i < GRID_CELLS; ++i) {
					var gridRow = [];
					for (var j = 0; j < GRID_CELLS; ++j) {
						var rect = me.gridSvg
							.rect(GRID_CELL_SIZE, GRID_CELL_SIZE)
							.move(j*(GRID_CELL_SIZE+GRID_CELL_GAP), i*(GRID_CELL_SIZE+GRID_CELL_GAP))
							.fill('#000');
						gridRow.push(rect);
					}
					me.gridCells.push(gridRow);
				}
				me.start(builder.build("WerldProto"));
			});
		});
	},

	start: function start(WerldProto) {
		var me = this;
		me.log("Starting...");

		var wsPath = "ws://" + window.location.hostname + ":3000/websocket"
		var ws = new ReconnectingWebSocket(wsPath, [], {
			maxReconnectionDelay: 5000,
			minReconnectionDelay: 250,
			connectionTimeout: 500
		});

		ws.onopen = function (event) {
			me.log("Connected");
			ws.binaryType = 'arraybuffer';
			var msg = WerldProto.MessageToServer.encode({
				chunk_request: {
					coords: [
						{ instance: 0, grid: 0, x: 0, y: 0 }
					]
				}
			});
			ws.send(msg.buffer);
		};

		ws.onclose = function (event) {
			me.log("Connection closed");
		}

		ws.onmessage = function (event) {
			var msg = WerldProto.MessageToClient.decode(event.data);
			if (msg.msg == "chunk") {
				var idx = 0;
				_.each(msg.chunk.block_runs, function (block_run) {
					for (var br_idx = 0; br_idx < block_run.count; ++br_idx) {
						var cell = me.gridCells[_.floor(idx/GRID_CELLS)][idx % GRID_CELLS];
						if (cell) {
							if (block_run.block_type == 0) {
								cell.fill("#000");
							} else {
								cell.fill("#00f");
							}
						}
						idx += 1;
					}
				});
			} else if (msg.msg == "global_notice") {
				me.log("NOTICE: " + msg.global_notice);
			} else if (msg.msg == "heartbeat_ack") {
				me.log("Heartbeat ack:" + msg.heartbeat_ack);
			}
		};

		var heartbeat = 0;
		setInterval(function() {
			if (ws && ws.readyState == 1) {
				var msg = WerldProto.MessageToServer.encode({heartbeat:  heartbeat})
				ws.send(msg.buffer);
				heartbeat += 1;
			}
		}, 5000);
	},

	log: function log(msg) {
		console.log(msg);
	}
};

module.exports = Application;
