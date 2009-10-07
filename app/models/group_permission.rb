class GroupPermission < ActiveRecord::Base
  belongs_to :group
  belongs_to :medium
end
