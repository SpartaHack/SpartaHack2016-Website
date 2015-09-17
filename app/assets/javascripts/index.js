//jQuery("#title-text").fitText(1);
//jQuery(".responsive-text").fitText(1);

if (navigator.appVersion.indexOf("Win")!=-1) {
  $('#hero').find('a').addClass( "windowsCenter" );
}
$('#faq article h3').click(function() {
  $(this).next().slideToggle();
});

$('.anchorLink').click(function(){
  $('html, body').animate({
    scrollTop: $( $(this).attr('href') ).offset().top - 58
  }, 500);
  return false;
});

var desktop_menu = [
  {"scroll_to": "#home-nav", "elem": $("#hero")},
  {"scroll_to": "#faq-nav", "elem": $("#faq")},
  {"scroll_to": "#mobile-nav", "elem": $("#mobile")},
  {"scroll_to": "#contact-nav", "elem": $("#contact")},
];

var current = "#home-nav";

$(".svg-wrapper").hover( 
  function () { 
    $(".svg-wrapper").removeClass("active");
    $(this).addClass("active"); 
  },
  function () { 
    $(".svg-wrapper").removeClass("active");
    $(current).addClass("active"); 
  }

);

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


$(window).scroll(function() {
  if ($(window).width() > 550) {
    var halfHeight = $(this).scrollTop() + ($(this).height() / 1.7);

    for(var i = 0; i < desktop_menu.length; i++) {
      var topOffset = desktop_menu[i]["elem"].offset().top;
      var height = desktop_menu[i]["elem"].height();

      if(halfHeight >= topOffset && halfHeight <= (topOffset + height) && current != desktop_menu[i]["scroll_to"]) {
        var scroll_to = desktop_menu[i]["scroll_to"];
        // change the selected menu element
        $(".svg-wrapper").removeClass("active");
        $(scroll_to).addClass("active");
        current = scroll_to;
      }
    }

  }
});

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



