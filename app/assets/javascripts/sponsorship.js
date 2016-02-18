function readURL(input) {
	if (input.files && input.files[0]) {
	  var reader = new FileReader();

	  reader.onload = function (e) {
	    $('#img_prev')
	      .attr('src', e.target.result)
	  };

	  reader.readAsDataURL(input.files[0]);
	}
}

$(document).ready(function() {	

	$('#level').select2({
	  placeholder: "Level of Sponsorship", 
	  allowClear: true
	});

	$('b[role="presentation"]').hide();
	$('.select2-selection__arrow').append('<i class="fa fa-angle-down"></i>');	
	$('.select2-container--open').append('<i class="fa fa-angle-up"></i>');	

});