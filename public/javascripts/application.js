
function byId (i) { return document.getElementById(i); } 
  // I know, but let's get js framework agnostic

//var ById = function () {
//  var bi = {};
//  bi.__noSuchMethod__ = function (i, a) { alert(i); return document.getElementById(i); };
//  return bi;
//}();
  //
  // fail :(

function linkToCss (href) {
  var e = document.createElement('link');
  e.setAttribute('href', '/stylesheets/' + href + '.css');
  e.setAttribute('media', 'screen');
  e.setAttribute('rel', 'stylesheet');
  e.setAttribute('type', 'text/css');
  document.getElementsByTagName('head')[0].appendChild(e);
}

