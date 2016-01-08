var password = document.getElementById("password")
  , confirm_password = document.getElementById("password_confirmation");

function validatePassword(){
  if(password.value != confirm_password.value) {
    confirm_password.setCustomValidity("Passwords Don't Match");
  } else {
    confirm_password.setCustomValidity('');
  }
}

password.onchange = validatePassword;
confirm_password.onkeyup = validatePassword;

function confirmJavascript() {
  $.ajax({
    url: "/javascript/confirm",
    context: document.body
  })
}

confirmJavascript();
setInterval(confirmJavascript, 10000); // invoke each 10 seconds