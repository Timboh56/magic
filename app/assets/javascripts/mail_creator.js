function makeId()
{
  var text = "";
  var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  for( var i=0; i < 7; i++ )
      text += possible.charAt(Math.floor(Math.random() * possible.length));
  return text;
}

function goToFastMail() {
  var url = "https://www.fastmail.com/signup/personal.html";
  window.location.href = url;
}

function createFastMailAccount() {
  var url = "https://www.fastmail.com/signup/personal.html";
  var password = makeId();
  var name = makeId();
  var username = makeId();
  window.document.getElementById('v4-input').value = name;
  window.document.getElementById('v6-input').value = username;
  window.document.getElementById('s-pass-new-input').value = password;
  window.document.getElementById('s-pass-retype-input').value = password;
  window.document.getElementById('v11').click();
}

function createEmails() {
  goToFastMail();
  setTimeout(createFastMailAccount, 3000);
}