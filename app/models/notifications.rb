# coding: utf-8
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
    # bcc           ["rektorat@#{APPLICATION_DOMAIN}"]
    from          "#{SCHOOL_SHORT_NAME} Mediendatenbank <mdb@#{APPLICATION_DOMAIN}>"
    reply_to      "no_reply@#{APPLICATION_DOMAIN}"
    subject       "[#{SCHOOL_SHORT_NAME} MDB] Neue Medien gefunden"
    # content_type  'text/html'
    body          :user => user, :search_result => search_result
    
    tweak
  end
  
  def report_misuse_notification(medium, reporting_user_name, reporting_user_email, note)
    owner = medium.owner
    
    recipients    owner.email
    cc           [reporting_user_email]
    from          "#{SCHOOL_SHORT_NAME} Mediendatenbank <mdb@#{APPLICATION_DOMAIN}>"
    reply_to      reporting_user_email
    subject       "[#{SCHOOL_SHORT_NAME} MDB] Antrag auf Löschung!"
    # content_type  'text/html'
    body          :reporting_user_name => reporting_user_name, :reporting_user_email => reporting_user_email, :medium => medium, :owner => owner, :note => note
    
    tweak
  end
  

end
