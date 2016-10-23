"use strict";

var $ = require("jquery");

var App = {
	init: function init() {
		$(document).ready(function() {
			$('body').append("OK!");
		});
	}
};

module.exports = App;
