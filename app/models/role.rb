# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  USER_MODELS = [User, UserGroup]
  USER_MODELS.each {|m| has_and_belongs_to_many m.to_s.tableize.to_sym }  
  belongs_to :authorizable, :polymorphic => true
end
