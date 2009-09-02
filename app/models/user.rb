require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :user_group_memberships
  has_many :user_groups, :through => :user_group_memberships

  # Dies ist der User-Model des Rollen-systems (plugin authorizable)
  acts_as_authorized_user
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login
#  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
#  validates_length_of       :email,    :within => 3..100
#  validates_uniqueness_of   :login, :email, :case_sensitive => false
  validates_uniqueness_of   :login, :case_sensitive => false
  before_save :encrypt_password

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)    
    user = find_by_login(login)

    if user
      # Lokales Passwort?
      if user.authenticated?(password)
        return user
      else
        return nil
      end
    else
      # Kein Username gefunden
      return nil
    end

    # Zur Sicherheit, wenn oben kein return erfolgen würde, dann sicher nicht authentifizieren
    return nil
    
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  
  
  def defined_media_sets
    media_sets_of_state :defined
  end

  def media_sets_to_define
    media_sets_of_state :defining
  end

  def uploading_media_set
    singleton_media_set :uploading, 'upload!', 'Aktuelle Hochlade-Kollektion'
  end

  def composing_media_set
    singleton_media_set :composing, 'compose!', 'Aktuelle Auswahl'
  end
  
  def search_result_media_set
    singleton_media_set :search_result, 'to_search_result!', 'Letztes Suchresultat'
  end
  
  # das MediaSet, das alle Medien des owners aufnimmt
  def owner_media_set
    singleton_media_set :owning, 'own!', 'Meine Medien'
  end

  
  # Eigene Implementation von has_role?. (has_role? aus dem authorization plugin wird aber noch verwendet)
  alias :original_has_role? :has_role?
  def has_role?(role, authorizable_object = nil)
    # Falls Rolle 'viewer', dann nicht auf User selbst nach dieser Rolle suchen, sondern in allen Gruppen, 
    # in der dieser User drin ist nach dieser Rolle suchen, denn ein User erhält die Viewer-Rolle von den 
    # Gruppen in den er drin ist "vererbt".
    if role == 'viewer'
      user_groups.each do |group|
        return true if group.has_role? role, authorizable_object
      end
      return false
    else
      original_has_role? role, authorizable_object
    end
  end


protected

  # Liefert die "Singleton-Instanz" eines MediaSets dieses Users mit einem bestimmten State
  def singleton_media_set(state, event, name = nil)
    media_sets = media_sets_of_state state
    
    # Erzeugen, falls inexistent
    if media_sets.empty?
      media_set = MediaSet.create!
      media_set.send event
      self.is_owner_of media_set
    else
      media_set = media_sets.first
    end    

    # Optional einen gewünschten Namen vergeben (nicht speichern!)
    media_set.name = name if name
    
    media_set
  end  
  
  
  # Liefert die MediaSets dieses Users eines bestimmten states
  def media_sets_of_state(state)
    self.is_owner_of_what MediaSet, :conditions => {:state => state.to_s}
  end
    
  # before filter
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
#    crypted_password.blank? || !password.blank?
    false
  end

end
