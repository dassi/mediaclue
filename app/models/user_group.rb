class UserGroup < ActiveRecord::Base
  has_many :user_group_memberships
  has_many :users, :through => :user_group_memberships
  
  # Dies ist der User-Model des Rollen-systems (plugin authorizable)
  acts_as_authorized_user
  
end
