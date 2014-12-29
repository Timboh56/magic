// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require twitter/bootstrap
//= require jquery_nested_form
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/extras/dataTables.responsive
var window = window || document.window;
var btn, curr_val;

$(document).ready (function () {
	$('form').submit( function () {
		btn = $(this).find('input[type=submit], button');
		curr_val = btn.html() || btn.val();
		btn.html("Saving..");
		btn.prop('disabled', true);
	});

	$('form').on('ajax:complete', function () {
		if (btn) {
			btn.html(curr_val);
			btn.prop('disabled', false);
		}
	});
});

$(document).on('click', '.hide-btn', function () {
	var hideElement = $(this).data('toggle');
	$(hideElement).addClass('hide');
});

$(document).on('click', '.toggle-btn', function () {
	var klass = $(this).data('toggle');
	var id = $(this).attr('id');
	$('.active').removeClass('active');
	$(this).toggleClass('active');
	$(klass).addClass('hide');
	$('#' + id + klass).toggleClass('hide');
	$('input' + klass).val(id);
});

function set_bounce() {
	setInterval(function () {
		setTimeout( function () {
				bounce();
			}, 2000);
	}, 2000);
}

function bounce() {
	$(".bounce").animate({
		height: "+=10px"
	}, 1000);
	$(".bounce").animate({
		height: "-=10px"
	}, 1000);
}

function getElementFontColor(elm) {
	var fc	= window.getComputedStyle(elm).color;
		fc	= fc.match(/\((.*)\)/)[1];
		fc	= fc.split(",");
	for (var i = 0; i < fc.length; i++) {
		fc[i] = parseInt(fc[i], 10);
	}
	return fc;
}

function generateRGB() {
	var color = [];
	for (var i = 0; i < 3; i++) {
		var num = Math.floor(Math.random()*225);
		while (num < 25) {
			num = Math.floor(Math.random()*225);
		}
		color.push(num);
	}
	return color;
}

function rgb2hex(color) {
	var hex = [];
	for (var i = 0; i < 3; i++) {
		hex.push(color[i].toString(16));
		if (hex[i].length < 2) { hex[i] = "0" + hex[i]; }
	}
	return "#" + hex[0] + hex[1] + hex[2];
}

function calculateDistance(current, next) {
	var distance = [];
	for (var i = 0; i < 3; i++) {
		distance.push(Math.abs(current[i] - next[i]));
	}
	return distance;
}

var incrementStops = 50;
function calculateIncrement(distance) {
	var increment = [];
	for (var i = 0; i < 3; i++) {
		increment.push(Math.abs(Math.floor(distance[i] / incrementStops)));
		if (increment[i] == 0) {
			increment[i]++;
		}
	}
	return increment;
}

var iteration = Math.round(1000 / (incrementStops/2));
function createTransition(id, bg_or_font) {
	var elm				= document.getElementById(id);
	var currentColor	= getElementFontColor(elm);
	var randomColor		= generateRGB();
	var distance		= calculateDistance(currentColor, randomColor);
	var increment		= calculateIncrement(distance);
	
	function transition() {
		
		if (currentColor[0] > randomColor[0]) {
			currentColor[0] -= increment[0];
			if (currentColor[0] <= randomColor[0]) {
				increment[0] = 0;
			}
		} else {
			currentColor[0] += increment[0];
			if (currentColor[0] >= randomColor[0]) {
				increment[0] = 0;
			}
		}
		
		if (currentColor[1] > randomColor[1]) {
			currentColor[1] -= increment[1];
			if (currentColor[1] <= randomColor[1]) {
				increment[1] = 0;
			}
		} else {
			currentColor[1] += increment[1];
			if (currentColor[1] >= randomColor[1]) {
				increment[1] = 0;
			}
		}
		
		if (currentColor[2] > randomColor[2]) {
			currentColor[2] -= increment[2];
			if (currentColor[2] <= randomColor[2]) {
				increment[2] = 0;
			}
		} else {
			currentColor[2] += increment[2];
			if (currentColor[2] >= randomColor[2]) {
				increment[2] = 0;
			}
		}

		if (bg_or_font == "font")
			elm.style.color = rgb2hex(currentColor);
		else
			elm.style.backgroundColor = rgb2hex(currentColor);
		
		if (increment[0] == 0 && increment[1] == 0 && increment[2] == 0) {
			clearInterval(handler);
			createTransition(id, bg_or_font);
		}
	}
	var handler = setInterval(transition, iteration);
}