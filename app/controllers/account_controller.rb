class AccountController < ApplicationController

  # If you want "remember me" functionality, add this before_filter to Application Controller
  # before_filter :login_from_cookie
  before_filter :login_required, :except => [:login]
  
  filter_parameter_logging(:password)

  def login
    # Sicherstellen, dass das Login via https geht
    
    if LOGIN_WITH_HTTPS_ONLY and (not request.ssl?) and (not LOCAL_DEVELOPMENT)
      redirect_to url_for(:action => 'login', :protocol => 'https://')
    end

    return unless request.post?
    
    # "Hans Meier" und "hans.meier" als "hans_meier" behandeln
    username = params[:login].strip.downcase
    password = params[:password]
    self.current_user = User.authenticate(username, password)
    
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      flash[:notice] = "Anmeldung erfolgreich."
      
      redirect_to(root_url)
    else
      flash[:error] = "Login/Passwort falsch!"      
    end
  end


  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "Sie wurden abgemeldet."
    redirect_to(:controller => 'account', :action => 'login')
  end
end
