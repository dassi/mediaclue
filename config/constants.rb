# Name des mediaclue-Projektes. Titel der Applikation.
PROJECT_NAME = 'Digitale Sammlung XY'

# Generiert ein Link im Menu zu einer externen Hilfe-Seite (FAQ etc.)
URL_TO_EXTERNAL_HELP = 'http://www.mediaclue.ch/'

MEDIA_STORAGE_PATH_PREFIX = 'public/m/files/'
PREVIEWS_STORAGE_PATH_PREFIX = 'public/m/previews/'

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

# Auswahl für Quelle/Copyright
# TODO: Evt. als Model License auslagern
MEDIUM_SOURCES = [
  ['Unbekannt', 'unknown'],
  ['Rechte beim Besitzer', 'owner'],
  ['Netzklau (nur für persönlichen Gebrauch)', 'personal'],
  ['Schulcopyright (offiziell für Schulzwecke lizensiert)', 'school'],
  ['Frei (Creative Commons Licence)', 'free']
]


# Jumploader-Version
JUMPLOADER_VERSION = [2, 19, 4]

# Jumploader-Erscheinung: Neuste Browsers verhindern, dass die Drag&Drop Funktionen an das Java Applet gesendet werden, und fangen dies selbst ab.
# Deshalb verwenden wir als Default den Jumploader in einem eigenen Java-Fenster, dann funktioniert Drag&Drop
JUMPLOADER_IN_SEPARATE_WINDOW = true

# Meta-Daten extrahieren und darstellen?
FEATURE_METADATA = true

# An einem LDAP-Server authentifizieren
FEATURE_LDAP_AUTHENTICATION = true

# Zeigt einen Hinweis an, dass der Internet Explorer keine gute Wahl ist
FEATURE_DISLIKE_INTERNET_EXPLORER = true

# Für Server-Konfiguration siehe config/ldap.yml (Wird auch von ActiveLdap gem verwendet)
LDAP_USERS_DN_PREFIX = 'cn=users'
LDAP_GROUPS_DN_PREFIX = 'cn=groups'
LDAP_USERNAME_ATTRIBUTE = 'uid'
LDAP_IMPORTED_USER_GROUPS = ['lehrer']
LDAP_ADDITIONAL_GROUP_NAME_ATTRIBUTES = ['description']

# Global gültige Beschränkung der Dateigrösse
# = nil, falls keine Beschränkung
MAX_FILE_SIZE = nil # Zum Beispiel 8 * (1024**2)  => 8MB
                  
# Maximale Anzahl Suchergebnisse
# Zahl oder nil für unbeschränkt
MAX_SEARCH_RESULTS = 100

# Ob in der Suchresultat-Ansicht auch gleich alle Medien der gefundenen Kollektionen angezeigt werden, oder nicht.
SEARCH_RESULT_SHOWS_MEDIA_FROM_SETS = false

# Pfad zum temporären Ordner
# Standard Rails: TEMP_PATH = File.join(RAILS_ROOT, 'tmp')
# Warnung! RAILS_ROOT ist hier nicht immer definiert! Bei Webserver schon, aber in Konsole nicht?
TEMP_PATH = './tmp'

# Anzahl Seiten, welche als Vorschau für Dokumente generiert werden                    
MAX_PAGES_DOCUMENT_PREVIEW = 5

# Ort wo das soffice-binary von OpenOffice liegt
OOO_HOME='/Applications/office/OpenOffice.org.app/Contents'
                     
# Login nur via HTTPS
LOGIN_WITH_HTTPS_ONLY = false

# Exif-Tags, welche rausgefiltert werden. Auch regular expressions möglich!
UNWANTED_EXIF_TAGS = [
  'FileName',
  'FileSize',
  'FileType',
  'FilePermissions',
  'Directory',
  'ExifToolVersion',
  'MIMEType',
  'CRC',
  /^Apple.*/,
  'MatrixStructure',
  /.*Date$/,
  /.*Time$/,
  /GUID/,
  'NextTrackID'
  ]

# Projekt-Logo im Header  
LOGO_FILENAME = 'logo_small.png'

# Weitere Pfade für die PATH Variable. Auf OSX mit MacPorts z.B. ['/opt/local/bin']
ADDITIONAL_ENV_PATHS = []

# Default-Wert für die Rechte-Einstellung eines Mediums. Wählbar ist 'owner' oder 'all'
DEFAULT_PERMISSION_TYPE = 'all'