unless SUPRESS_EARLY_DB_CONNECTION

  # Aus allen content_types der Medien über MIME::Types die Rails-eigenen Mime::Type registrieren
  # damit die respond_to handler funktionieren.
  Medium.all_media_content_types.each do |content_type|
    mime_types = MIME::Types[content_type]
    mime_types.first.extensions.each_with_index do |ext, idx|
      # Erste Extension mit register, weiter mit register_alias registrieren
      meth = (idx == 0) ? :register : :register_alias
      Mime::Type.send meth, content_type, ext
    end
  end
end