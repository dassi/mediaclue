# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails23_blank_session',
  :secret      => 'fa6de9a667d0d0a0de93ff2440911d91da1894b344bf7dc63295534621561cd2972b949c495a8e3a06624ef896ff1dd2cd27d0c116968c432941d9c3ecb29ef3'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
