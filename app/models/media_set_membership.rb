class MediaSetMembership < ActiveRecord::Base
  belongs_to :media_set
  belongs_to :medium
end
