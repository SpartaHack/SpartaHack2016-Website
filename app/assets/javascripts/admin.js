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

	$('#popup-wrapper').click(function(e){
		  if (e.target !== this)
		    return;
		  
		  $('#popup-wrapper').fadeOut('fast');
	});

	$('#users').click(function(e){
		e.preventDefault();

		$('#popup-wrapper').html('\
			<section class="topic-selection">\
				<div class="row">\
			        <div class="hvr-underline-from-center full">\
			            <submit id="send_email" class="topic">Email Users</submit>\
			        </div>\
                    <div class="hvr-underline-from-center full">\
                        <a href="/admin/users/applications"><div class="topic" >Applications</div></a>\
                    </div>\
		        </div>\
	        </section>\
		');

		$('#send_email').click(function(e){
			e.preventDefault();

			$('#popup-wrapper').html('\
				<section class="topic-selection">\
					<div class="row">\
				        <div class="hvr-underline-from-center full">\
				            <submit id="send_decision_email" class="topic">Send Application Decisions</submit>\
				        </div>\
				        <div class="hvr-underline-from-center full">\
				            <submit id="send_empty_app_email" class="topic">Send Empty Appplication Notice</submit>\
				        </div>\
			        </div>\
		        </section>\
			');

			$('#send_decision_email').click(function(e){
				e.preventDefault();

		        $.ajax({
		            url: "/admin/users/email",
		            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
		            type: "post",
		            context: document.body,
		            data: "type=decision"
		        })

				$('#popup-wrapper').fadeOut('slow');
			});

			$('#send_empty_app_email').click(function(e){
				e.preventDefault();

		        $.ajax({
		            url: "/admin/users/email",
		            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
		            type: "post",
		            context: document.body,
		            data: "type=empty_app"
		        })

		        $('#popup-wrapper').fadeOut('slow');
			});	

		});
			
		$("#popup-wrapper").css("display", "flex");
	})


});