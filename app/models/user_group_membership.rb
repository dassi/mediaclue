class UserGroupMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_group
end
