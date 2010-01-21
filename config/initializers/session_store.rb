# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => "#{PROJECT_NAME.gsub(' ', '_')}_mediaclue_session",
  
  # Ändere dies für Dein Projekt!
  :secret      => '8973459dwfhu3498weifuhasdfuh4t98zer98745zejhsuigfdtrsr56uitdr77eughr9gisudfgh3iuwergiuzd7uh4g0olop',

  # Wow! Das hat mich einen halben Tag gekostet, um rauszufinden, warum es bei allen Browsern ausser Safari mit dem JumpLoader ein Problem gibt,
  # weil er die Session verliert (nicht eingeloggt ist). Man muss dem JavaApplet die Möglichkeit erlauben, das Session-Cookie zu lesen und zu senden.
  # Das geht etwas auf Kosten der Sicherheit, aber wie sonst soll das gehen? (Es gibt kompliziertere Möglichkeiten, die via Rack-Middleware ein Cookie-Wert via
  # GET senden und in die HTTP_COOKIE Variable umwandeln bevor es an Rails geht, aber das ist für uns viel zu aufwändig)
  # Siehe: http://jumploader.com/forum/viewtopic.php?t=537&highlight=httponly
  :httponly => false 
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store
