

var xhr = new XMLHttpRequest();
var blobUrl = "blobUrlPlaceholder";
console.log(blobUrl);
xhr.open('GET', blobUrl, true);
console.log("GET");
//fetch(blobUrl)
//    .then(response => response.blob())
//    .then(blob => {
//      const reader = new FileReader();
//      reader.onload = function() {
//        callback(reader.result); // Send base64 data back to Dart
//      };
//      reader.readAsDataURL(blob);
//    })
//    .catch(error => console.log('Error fetching blob:', error));
//
xhr.responseType = 'blob';
xhr.onload = function(e) {
  if (this.status == 200) {
    var blob = this.response;
    var reader = new FileReader();
    reader.readAsDataURL(blob);
    reader.onloadend = function() {
      var base64data = reader.result;
      var base64ContentArray = base64data.split(",")     ;
      var mimeType = base64ContentArray[0].match(/[^:\s*]\w+\/[\w-+\d.]+(?=[;| ])/)[0];
      var decodedFile = base64ContentArray[1];
      console.log(mimeType);
      window.flutter_inappwebview.callHandler('downloadBlobFile', decodedFile, mimeType);
    };
  };
};
xhr.send();