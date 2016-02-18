$(document).ready( function () {
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

	$('#send_rsvp_reminder_email').click(function(e){
		e.preventDefault();

	    $.ajax({
	        url: "/admin/users/email",
	        beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
	        type: "post",
	        context: document.body,
	        data: "type=rsvp-reminder"
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