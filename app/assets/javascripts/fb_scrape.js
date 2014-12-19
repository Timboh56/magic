var document = window.document;
var uids = [];
var iterations = 0;

function getUids() {
	if (iterations < 5) {
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
	};
}