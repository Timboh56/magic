var document = window.document;
var uids = [];
var fb_users = [];
var iterations = 0;

function getUids() {
	if (iterations < 2) {
		iterations++; 
		var layer1 = document.getElementsByClassName('fcb fwb fsl');
		var layer_arr = Array.prototype.slice.call(layer1);
		layer_arr = layer_arr.slice(uids.length);
		for (var i in layer_arr){
			try {
				uids.push(layer_arr[i].getElementsByTagName('a')[0].dataset.hovercard.match(/id=(\d*)&/m)[1]);
			} catch (err) {
				// meh
			}
		}

		document.getElementsByClassName('pam uiBoxLightblue uiMorePagerPrimary')[0].click();

		// call getUids again after 5 seconds
		setTimeout(getUids, 5000);
	} else {
		console.log("all done!");
		console.log(uids);
		console.log(uids.length);
		userNameLookup();
	};
}

function userNameLookup() {
	var fb_user;
	var xmlhttp = new XMLHttpRequest();
	var res;

	function onload(xhr) {
		res = JSON.parse(xhr.responseText);
		console.log(res);
		fb_user = {
			email: res.username + "@facebook.com",
			name: res.name,
			id: res.id,
		};
		fb_users.push(fb_user);
	}

	for(var i in uids) {
		var xmlhttp = new XMLHttpRequest();
		console.log(uids[i]);
		var regex = /^(\d*)$/m;
		if (regex.test(uids[i])) {
			xmlhttp.open("GET", "https://graph.facebook.com/" + uids[i],true);
			xmlhttp.onload = onload;
			xmlhttp.send();
		}
	}
}