class UserGroup < ActiveRecord::Base

  has_many :user_group_memberships, :dependent => :destroy
  has_many :users, :through => :user_group_memberships

  has_many :user_group_permissions, :dependent => :destroy

  def member?(user)
    self.users.exists?(user.id)
  end
end
