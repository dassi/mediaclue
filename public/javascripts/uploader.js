function uploaderFileStatusChanged( uploader, file )
{
  var response = file.getResponseContent();
  if (response)
  {
    window.eval(String.interpret(response));
  }
}

function setAuthenticityToken(applet, authenticity_token)
{
  setPostAttribute("authenticity_token", authenticity_token, applet);
}

function setPostAttribute(attributeName, value, uploader) {
  if (uploader === undefined || uploader === null) {
    uploader = document.jumpLoaderApplet.getUploader();
  }
  var attrSet = uploader.getAttributeSet();
  var attr = attrSet.createStringAttribute(attributeName, value);
  attr.setSendToServer(true);
}
