function modelMatcher (params, data) {
  data.parentText = data.parentText || "";

  // Always return the object if there is nothing to compare
  if ($.trim(params.term) === '') {
    return data;
  }

  // Do a recursive check for options with children
  if (data.children && data.children.length > 0) {
    // Clone the data object if there are children
    // This is required as we modify the object to remove any non-matches
    var match = $.extend(true, {}, data);

    // Check each child of the option
    for (var c = data.children.length - 1; c >= 0; c--) {
      var child = data.children[c];
      child.parentText += data.parentText + " " + data.text;

      var matches = modelMatcher(params, child);

      // If there wasn't a match, remove the object in the array
      if (matches == null) {
        match.children.splice(c, 1);
      }
    }

    // If any children matched, return the new object
    if (match.children.length > 0) {
      return match;
    }

    // If there were no matching children, check just the plain object
    return modelMatcher(params, match);
  }

  // If the typed-in term matches the text of this term, or the text from any
  // parent term, then it's a match.
  var original = (data.parentText + ' ' + data.text).toUpperCase();
  var term = params.term.toUpperCase();


  // Check if the text contains the term
  if (original.indexOf(term) > -1) {
    return data;
  }

  // If it doesn't contain the term, don't return anything
  return null;
}


function createSelects() {
	$('#university').select2({
	  placeholder: "Which university do you attend *", 
	  allowClear: true,
	  matcher: modelMatcher
	});
	$('#gender').select2({
	  placeholder: "Gender *",
	  minimumResultsForSearch: -1, 
	  allowClear: true,
	});
	$('#birthmonth').select2({
	  placeholder: "Birth Month *", 
	  minimumResultsForSearch: -1,
	  allowClear: true
	});
	$('#birthday').select2({
	  placeholder: "Birth Day *",
	  minimumResultsForSearch: -1,
	  allowClear: true
	});
	$('#birthyear').select2({
	  placeholder: "Birth Year *", 
	  minimumResultsForSearch: -1,
	  allowClear: true
	});
	$('#major').select2({
	  placeholder: "Field of study *", 
	  allowClear: true
	});
	$('#gradeLevel').select2({
	  placeholder: "Year of school *", 
	  allowClear: true
	});
	$('#hackathons').select2({
	  placeholder: "MLH hackathons you've attended", 
	  multiple:true
	});

	// hide old selection arrow;
	$('b[role="presentation"]').hide();
	$('.select2-selection__arrow').append('<i class="fa fa-angle-down"></i>');	
	$('.select2-container--open').append('<i class="fa fa-angle-up"></i>');	
}

function popUpTop() {
	$("#popup").css("top", "60px")
	$("#popup").css("bottom", "")
	$("#popup-wrapper").fadeIn("fast");
}

function popUpBottom() {
	$("#popup").css("bottom", "170px");
	$("#popup").css("top", "")
	$("#popup-wrapper").fadeIn("fast");	
}

$(document).ready(function() {	
	createSelects();

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

		if ($("#email").val().length == 0 || $("#email").val().length == 0) {
			$("#popup").html("Email is required.")
			popUpBottom()
		} else if (typeof password !== 'undefined' && password.value.length == 0) {
			$("#popup").html("You must input a password.")
			popUpBottom()
		} else if (typeof password !== 'undefined' && password.value.length > 0 && password.value != confirm_password.value) {
			$("#popup").html("Passwords do not match.")
			popUpBottom()
		} else if (typeof password !== 'undefined' && password.value.length < 8) {
			$("#popup").html("Password is too short.")
			popUpBottom()
		} else if ($("#firstName").val().length == 0 || $("#lastName").val().length == 0) {
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
		} else if (document.getElementById('university-student').checked && $("#major").val() == null || document.getElementById('university-student').checked && $("#major").val().length == 0) {
			$("#popup").html("Please indicate your major.")
			popUpBottom()
		} else if (document.getElementById('university-student').checked && $("#gradeLevel").val().length == 0) {
			$("#popup").html("Please indicate your year in school.")
			popUpBottom()
		} else if (!document.getElementById('agree').checked) {
			$("#popup").html("Please agree to the MLH Code of Conduct.")
			popUpTop()
		} else {
			$("#popup").html("Saving Application...")
			popUpBottom()
	        setTimeout(function () {
	            $('#save_app').trigger('submit.rails');
	        }, 500);
			
		}
	})

	if (document.getElementById('university-student').checked) {
		$('.university-enrolled').fadeIn("fast");
		if (document.getElementById('other-university-confirm').checked) {
			$('.university').css("display", "none");
			$('.other-university-enrolled').fadeIn("fast");
		} else {
			$('.other-university-enrolled').fadeOut("fast");
		}
		createSelects();
	} else {
		$('.university-enrolled').fadeOut("fast");
		createSelects();
	}

	$('#popup-wrapper').click(function(){
		$('#popup-wrapper').fadeOut('fast');
	});

	$('#popup-error-wrapper').click(function(){
		$('#popup-error-wrapper').fadeOut('fast');
	});

	$('#university-student').click(function(){
		// $('.university-enrolled').fadeIn("fast")
		$('.university-enrolled').slideDown('slow');
		createSelects();
	})

	$('#highschool-student').click(function(){
		$('.university-enrolled').slideUp("slow");
		$('.other-university-enrolled').slideUp("slow");
		$('#other-university-confirm').prop('checked', false);
		$('#university').val("").change();
		$('#otherUniversity').val("");

		createSelects();
	})

	$('#other-university-confirm').change(function() {
		if ($(this).is(':checked')) {
			$('.university').slideUp("slow", function() {
				$('#university').val("").change();
				$('.other-university-enrolled').slideDown({duration:'slow', start: createSelects});
			});
			createSelects();
		} else {
			$('.other-university-enrolled').slideUp( "slow", function() {
				$('.university').slideDown({duration:'slow', start: createSelects});
				$('#otherUniversity').val("");
			});
		}

	});

})

$(window).resize(function() {
	createSelects();
})

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

$(window).scroll(function() {$("#popup-wrapper").fadeOut('fast');});

document.addEventListener("touchmove", ScrollStart, false);
document.addEventListener("scroll", Scroll, false);

function ScrollStart() {
    $("#popup-wrapper").fadeOut('fast');
}

function Scroll() {
	$("#popup-wrapper").fadeOut('fast');
}

function confirmJavascript() {
  $.ajax({
    url: "/javascript/confirm",
    context: document.body
  })
}

confirmJavascript();
setInterval(confirmJavascript, 10000); // invoke each 10 seconds
