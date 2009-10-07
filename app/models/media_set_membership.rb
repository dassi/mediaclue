class MediaSetMembership < ActiveRecord::Base
  belongs_to :media_set
  belongs_to :medium
  
  acts_as_list :scope => :media_set
end
