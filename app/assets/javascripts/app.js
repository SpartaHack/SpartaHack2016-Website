function createSelects() {
	$('#university').select2({
	  placeholder: "What university do you attend?", 
	  allowClear: true
	});
	$('#gender').select2({
	  placeholder: "Gender", 
	  allowClear: true,
	});
	$('#birthmonth').select2({
	  placeholder: "Birth Month", 
	  allowClear: true
	});
	$('#birthday').select2({
	  placeholder: "Birth Day", 
	  allowClear: true
	});
	$('#birthyear').select2({
	  placeholder: "Birth Year", 
	  allowClear: true
	});
	$('#major').select2({
	  placeholder: "Field of study", 
	  allowClear: true
	});
	$('#gradeLevel').select2({
	  placeholder: "Year of school", 
	  allowClear: true
	});
	$('#hackathons').select2({
	  placeholder: "What other MLH hackathons have you attended?", 
	  multiple:true
	});
}

function popUpTop() {
	$("#popup").css("top", "60px")
	$("#popup").css("bottom", "")
	$("#popup").fadeIn("fast");
}

function popUpBottom() {
	$("#popup").css("bottom", "170px");
	$("#popup").css("top", "")
	$("#popup").fadeIn("fast");	
}

$(document).ready(function() {	
	createSelects();

	// hide old selection arrow;
	$('b[role="presentation"]').hide();
	$('.select2-selection__arrow').append('<i class="fa fa-angle-down"></i>');	
	$('.select2-container--open').append('<i class="fa fa-angle-up"></i>');	


	// Create inline svg;

	jQuery('img.icon').each(function(){
	    var $img = jQuery(this);
	    var imgID = $img.attr('id');
	    var imgClass = $img.attr('class');
	    var imgURL = $img.attr('src');

	    jQuery.get(imgURL, function(data) {
	        // Get the SVG tag, ignore the rest
	        var $svg = jQuery(data).find('svg');

	        // Add replaced image's ID to the new SVG
	        if(typeof imgID !== 'undefined') {
	            $svg = $svg.attr('id', imgID);
	        }
	        // Add replaced image's classes to the new SVG
	        if(typeof imgClass !== 'undefined') {
	            $svg = $svg.attr('class', imgClass+' replaced-svg');
	        }

	        // Remove any invalid XML tags as per http://validator.w3.org
	        $svg = $svg.removeAttr('xmlns:a');

	        // Check if the viewport is set, if the viewport is not set the SVG wont't scale.
	        if(!$svg.attr('viewBox') && $svg.attr('height') && $svg.attr('width')) {
	            $svg.attr('viewBox', '0 0 ' + $svg.attr('height') + ' ' + $svg.attr('width'))
	        }

	        // Replace image with new SVG
	        $img.replaceWith($svg);

	    }, 'xml');

	});

	//validation for form submit

	$('#save-app').click(function(e){
		e.preventDefault();
		console.log(document.getElementById('university-student').checked)

		if ($("#firstName").val().length == 0 || $("#lastName").val().length == 0) {
			$("#popup").html("You must input your full name.")
			popUpBottom()
		} else 	if ($("#gender").val().length == 0 ) {
			$("#popup").html("Gender is required.")
			popUpBottom()
		} else if ($("#birthday").val().length == 0 || $("#birthyear").val().length == 0 || $("#birthmonth").val().length == 0) {
			$("#popup").html("Your full birthdate is required.")
			popUpBottom()
		} else if (!document.getElementById('highschool-student').checked && !document.getElementById('university-student').checked) {
			$("#popup").html("Please indicate your current enrollment.")
			popUpBottom()
		} else if (document.getElementById('university-student').checked && $("#university").val().length == 0 && $("#otherUniversity").val().length == 0) {
			$("#popup").html("Please indicate your university.")
			popUpBottom()
		} else if ($("#major").val() == null || $("#major").val().length == 0) {
			$("#popup").html("Please indicate your major.")
			popUpBottom()
		} else if ($("#gradeLevel").val().length == 0) {
			$("#popup").html("Please indicate your year in school.")
			popUpBottom()
		} else {
			$('#save_app').trigger('submit.rails');
		}
	})

	$('#highschool-student').click(function(){
		$('.university-enrolled').fadeOut("fast")
		createSelects();
	})

	$('#university-student').click(function(){
		$('.university-enrolled').fadeIn("fast")
		createSelects();
	})

	if (document.getElementById('university-student').checked) {
		$('.university-enrolled').fadeIn("fast")
		createSelects();
	} else {
		$('.university-enrolled').fadeOut("fast")
		createSelects();
	}

})

$(window).resize(function() {
	createSelects();
})

if ($(window).width() < 550) {
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

$(window).scroll(function() {$("#popup").fadeOut('fast');});
document.addEventListener("touchmove", function(){$("#popup").fadeOut('fast');}, false);
