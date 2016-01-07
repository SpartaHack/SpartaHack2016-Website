function confirmJavascript() {
  $.ajax({
    url: "/javascript/confirm",
    context: document.body
  });
}

$(document).ready(function() {
    console.log('onReady');
	$("#takePictureField").on("change",gotPic);
	
	confirmJavascript();
	setInterval(confirmJavascript, 10000); // invoke each 10 seconds
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