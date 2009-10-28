# Name des mediaclue-Projektes. Titel der Applikation.
PROJECT_NAME = 'Digitale Sammlung XY'

# Generiert ein Link im Menu zu einer externen Hilfe-Seite (FAQ etc.)
URL_TO_EXTERNAL_HELP = 'http://www.mediaclue.ch/'

MEDIA_STORAGE_PATH_PREFIX = 'public/m/'
PREVIEWS_STORAGE_PATH_PREFIX = 'public/m/previews/'

# # LDAP Group-ID, welche die Medien per default als viewer zugeordnet werden sollten (Gruppe "Lehrer")
# DEFAULT_GROUP_ID = nil

# Liste der Tags die als Schulfach gelten
SUBJECT_SELECTIONS = [
'Biologie',
'Bildnerisches Gestalten', 
'Chemie', 
'Chinesisch', 
'Deutsch', 
'Englisch', 
'Wirtschaft und Recht', 
'Französisch', 
'Geographie', 
'Griechisch', 
'Geschichte', 
'Italienisch', 
'Informatik', 
'Kunstgeschichte', 
'Latein', 
'Mathematik', 
'Medien und Gesellschaft', 
'Musik', 
'Physik', 
'Philosophie', 
'Religion', 
'Russisch', 
'Spanisch', 
'Sport', 
'Theater'
]

JUMPLOADER_VERSION = [2, 12, 8]

# Meta-Daten extrahieren und darstellen?
FEATURE_METADATA = true

# Global gültige Beschränkung der Dateigrösse
# = nil, falls keine Beschränkung
MAX_FILE_SIZE = nil # Zum Beispiel 8 * (1024**2)  => 8MB
                  
# Maximale Anzahl Suchergebnisse
# Zahl oder nil für unbeschränkt
MAX_SEARCH_RESULTS = 100

# Pfad zum temporären Ordner
# Standard Rails: TEMP_PATH = File.join(RAILS_ROOT, 'tmp')
# Warnung! RAILS_ROOT ist hier nicht immer definiert! Bei Webserver schon, aber in Konsole nicht?
TEMP_PATH = './tmp'

# Anzahl Seiten, welche als Vorschau für Dokumente generiert werden                    
MAX_PAGES_DOCUMENT_PREVIEW = 5