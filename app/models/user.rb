require 'digest/sha1'

class User < ActiveRecord::Base

  include Authorization::UserMethods

  has_many :media_sets, :foreign_key => 'owner_id' # Kein dependent destroy, zu gefährlich, Medien gehen verloren
  has_many :media, :foreign_key => 'owner_id'      # Kein dependent destroy, zu gefährlich, Medien gehen verloren
  
  has_many :user_group_memberships, :dependent => :destroy
  has_many :user_groups, :through => :user_group_memberships
  
  has_many :search_queries, :order => 'position ASC', :dependent => :destroy
  
  belongs_to :last_search_query, :class_name => "SearchQuery", :foreign_key => "last_search_query_id", :dependent => :destroy

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
    singleton_media_set :uploading, 'upload!'
  end

  def composing_media_set
    singleton_media_set :composing, 'compose!'
  end
  
  def search_result_media_set
    singleton_media_set :search_result, 'to_search_result!'
  end
  
  # das MediaSet, das alle Medien des owners aufnimmt
  def owner_media_set
    singleton_media_set :owning, 'own!'
  end

  def is_owner_of?(object)
    object.owner == self
  end

  def get_or_create_last_search_query
    if self.last_search_query.nil?
      self.create_last_search_query
      self.save!
    end
    
    self.last_search_query
    
  end
  
  protected #######################################################################################

  # Liefert die "Singleton-Instanz" eines MediaSets dieses Users mit einem bestimmten State
  def singleton_media_set(state, event)
    media_sets = media_sets_of_state state
    
    # Erzeugen, falls inexistent
    if media_sets.empty?
      media_set = MediaSet.create!(:owner => self)
      media_set.send event
    else
      media_set = media_sets.first
    end    

    media_set
  end  
  
  
  # Liefert die MediaSets dieses Users eines bestimmten states
  def media_sets_of_state(state)
    self.media_sets.find(:all, :conditions => {:state => state.to_s})
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
