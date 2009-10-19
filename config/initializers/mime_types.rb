unless SUPRESS_EARLY_DB_CONNECTION

  # Playlist-Format, www.xspf.org
  Mime::Type.register('application/xspf+xml', :xspf)
  
  # Aus allen content_types der Medien über MIME::Types die Rails-eigenen Mime::Type registrieren
  # damit die respond_to handler funktionieren.
  for media_class in Medium.sub_classes
    media_class.allowed_content_types.each do |content_type|
      mime_types = MIME::Types[content_type]

      if mime_types.any?
        extensions = mime_types.first.extensions.dup # Sehr wichtig dup! Sonst zerstören wir unten den Original-Array... (typisch ruby!)

        # Hole allfällige zusätzliche Dateiendungen zu diesem MIME-Typ
        if media_class.additional_file_extensions[content_type]
          extensions.concat(media_class.additional_file_extensions[content_type])
        end
    
        if extensions.any?
          # Register the first extension
          Mime::Type.register(content_type, extensions.pop)

          # Alias for all other extensions
          extensions.each do |ext|
            Mime::Type.register_alias(content_type, ext)
          end
        end
      end
    end
  end
end