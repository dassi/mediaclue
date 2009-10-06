# Das Translations-File für den JumpLoader wird komisch gecached, so dass Änderungen in den Texte nicht aktualisiert werden.
# Als Workaround benennen wir das File jedesmal neu, anhand des Zeitstempels, sofern es nicht schon existiert.

jumploader_path = "#{RAILS_ROOT}/public/applets"
jumploader_translations = "#{jumploader_path}/messages.properties"
timestamp = File.mtime(jumploader_translations)
jumploader_translations_zip_format = "messages_%s.zip"

# Name des ZIP als Konstante speichern. Wir beim Uploader wieder verwendet.
JUMPLOADER_TRANSLATIONS_ZIP = format(jumploader_translations_zip_format, timestamp.strftime('%Y%m%d%H%M%S'))

jumploader_translations_zip_filepath = "#{jumploader_path}/#{JUMPLOADER_TRANSLATIONS_ZIP}"

# Wir prüfen, ob das File schon da ist
if not File.exists?(jumploader_translations_zip_filepath)
  # Wir löschen alle allenfalls vorhandenen Files mit dem gleichen Format
  FileUtils.rm(Dir.glob(format("#{jumploader_path}/#{jumploader_translations_zip_format}", '*')), :force => true)

  # Wir erstellen das ZIP-File
  Zip::ZipFile.open(jumploader_translations_zip_filepath, Zip::ZipFile::CREATE) do |zipfile|
    zipfile.add 'messages.properties', jumploader_translations
  end
end