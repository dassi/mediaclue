# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  include AuthenticatedSystem
  before_filter :login_required

  # Hack, damit die Klasse Tag sicher geladen wird um das Klassen-lade-problem zu lösen. Siehe auch:
  # http://rubyforge.org/forum/message.php?msg_id=26687
  # http://rubyforge.org/forum/message.php?msg_id=27982
  # TODO: Ist das wirklich noch nötig als before_filter?! Siehe auch environment.rb
  before_filter { require_dependency 'tag' }

  protect_from_forgery
 

end
