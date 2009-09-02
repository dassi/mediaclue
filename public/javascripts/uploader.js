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
  var uploader = document.jumpLoaderApplet.getUploader();
  var attrSet = uploader.getAttributeSet();
  var attr = attrSet.createAttribute('authenticity_token', authenticity_token);
  attr.setSendToServer( true );
}