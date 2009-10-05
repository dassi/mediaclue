function uploaderFileStatusChanged( uploader, file )
{
  var response = file.getResponseContent();
  if (response)
  {
    window.eval(String.interpret(response));
  }
}

function setAuthenticityToken(authenticity_token)
{
  setPostAttribute("authenticity_token", authenticity_token);
}

function setPostAttribute(attributeName, value) {
  var uploader = document.jumpLoaderApplet.getUploader();
  var attrSet = uploader.getAttributeSet();
  var attr = attrSet.createStringAttribute(attributeName, value);
  attr.setSendToServer(true);
}
