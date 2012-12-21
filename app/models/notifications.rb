class Notifications < ActionMailer::Base

  protected #######################################################################################
  
  def tweak
    if LOCAL_DEVELOPMENT
      recipients ADMIN_EMAIL
      bcc.clear if bcc
    end
  end
  
  public ##########################################################################################
  
  def new_search_result_notification(user, search_result)
    recipients    user.email
    # bcc           ['rektorat@kshp.ch']
    from          'KSHP Mediendatenbank <mdb@kshp.ch>'
    reply_to      'no_reply@kshp.ch'
    subject       "[KSHP MDB] Neue Medien gefunden"
    # content_type  'text/html'
    body          :user => user, :search_result => search_result
    
    tweak
  end
  
  def report_misuse_notification(medium, reporting_user, note)
    owner = medium.owner
    
    recipients    owner.email
    cc           [reporting_user.email]
    from          'KSHP Mediendatenbank <mdb@kshp.ch>'
    reply_to      reporting_user.email
    subject       "[KSHP MDB] Antrag auf Löschung!"
    # content_type  'text/html'
    body          :reporting_user => reporting_user, :medium => medium, :owner => owner, :note => note
    
    tweak
  end
  

end
