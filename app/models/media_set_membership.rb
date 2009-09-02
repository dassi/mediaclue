class MediaSetMembership < ActiveRecord::Base
  belongs_to :media_set
  belongs_to :collectable, :polymorphic => true
end
