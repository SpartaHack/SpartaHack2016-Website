$(document).ready(function() {
    console.log('onReady');
	$("#takePictureField").on("change",gotPic);
	
});

qrcode.callback = function(data) {
	console.log(data)
	$("#yourcode").html(data);
}

function gotPic(event) {
    if(event.target.files.length == 1 && 
       event.target.files[0].type.indexOf("image/") == 0) {
        qrcode.decode(URL.createObjectURL(event.target.files[0]))
        
    }

}