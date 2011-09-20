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
  

end
