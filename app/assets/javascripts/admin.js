function confirmJavascript() {
  $.ajax({
    url: "/javascript/confirm",
    context: document.body
  });
}

$(document).ready(function() {	

	if ($(window).width() < 775) {
	  $("#header").headroom({
	    "offset": 205,
	    "tolerance": 5,
	    "classes": {
	      "initial": "animated",
	      "pinned": "slideDown",
	      "unpinned": "slideUp"
	    }
	  });
	}

	$(function() {
	    var pull        = $('#pull');
	        menu        = $('.mobile');
	 
	    $(pull).on('click', function(e) {
	        e.preventDefault();
	        menu.slideToggle();
	    });

	    $('.mobile li a').on('click', function(e) {
	        menu.slideToggle();
	    });

	});

	confirmJavascript();
	setInterval(confirmJavascript, 10000); // invoke each 10 seconds

	$('#popup-wrapper').click(function(){
		$('#popup-wrapper').fadeOut('fast');
	});

	$('#users').click(function(e){
		e.preventDefault();

		$('#popup-wrapper').html('\
			<section class="topic-selection">\
				<div class="row">\
			        <div class="hvr-underline-from-center full"> \
			            <a href=""><div class="topic">User Roles</div></a>\
			        </div>\
			        <div class="hvr-underline-from-center full">\
			            <a href=""><div class="topic">Email</div></a>\
			        </div>\
		        </div>\
	        </section>\
		');

		$("#popup-wrapper").css("display", "flex");
	})

});