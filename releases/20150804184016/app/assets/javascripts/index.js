jQuery("#title-text").fitText(1);
jQuery(".responsive-text").fitText(1);

if (navigator.appVersion.indexOf("Win")!=-1) {
  $('#hero').find('a').addClass( "windowsCenter" );
}
$('#faq article h1').click(function() {
  $(this).next().slideToggle();
  $(this).children("i").toggleClass("fa-plus").toggleClass("fa-minus");
});

$('.anchorLink').click(function(){
  $('html, body').animate({
    scrollTop: $( $(this).attr('href') ).offset().top
  }, 500);
  return false;
});