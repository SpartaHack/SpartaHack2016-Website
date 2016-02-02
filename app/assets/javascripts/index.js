console.log("Ha you're funny, looking under the hood")

if (navigator.appVersion.indexOf("Win")!=-1) {
  $('#hero').find('a').addClass( "windowsCenter" );
}

var last_p = 1;

$('#faq article h3').click(function() {
  current = $(this);
  $("article").removeClass("active-q");
  $(".a-hline").removeClass("hide");

  current.parent().addClass("active-q");
  current.parent().prev().addClass("hide");
  current.parent().next().addClass("hide");

  $("#answers p:nth-child("+ last_p +")").fadeOut("fast", function() {
    $( "#answers p:nth-child("+ current.attr("id") +")" ).fadeIn();
  });

  last_p = current.attr("id")
});

$('#questions').on('scroll', function() {
    if($(this).scrollTop() + $(this).innerHeight() >= $(this)[0].scrollHeight) {
        $(".fa-angle-down").fadeOut();
    } else {
      $(".fa-angle-down").fadeIn();
    }
})


$('.anchorLink').click(function(){
  $('html, body').animate({
    scrollTop: $( $(this).attr('href') ).offset().top - 58
  }, 500);
  return false;
});

var desktop_menu = [
  {"scroll_to": "#home-nav", "elem": $("#hero")},
  {"scroll_to": "#faq-nav", "elem": $("#faq")},
  {"scroll_to": "#contact-nav", "elem": $("#contact")},
  {"scroll_to": "#team-nav", "elem": $("#team")},
  {"scroll_to": "#sponsor-nav", "elem": $("#sponsors")},
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


$(window).scroll(function() {
  if ($(window).width() >= 775) {
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

function confirmJavascript() {
  $.ajax({
    url: "/javascript/confirm",
    context: document.body
  })
}

confirmJavascript();
setInterval(confirmJavascript, 10000); // invoke each 10 seconds



