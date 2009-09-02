#require File.join('vendor', 'plugins', 'authorization', 'lib', 'publishare', 'exceptions' )

# Provides the appearance of dynamically generated methods on the roles database.
#
# Examples:
#   user.is_member?                     --> Returns true if user has any role of "member"
#   user.is_member_of? this_workshop    --> Returns true/false. Must have authorizable object after query.
#   user.is_eligible_for [this_award]   --> Gives user the role "eligible" for "this_award"
#   user.is_moderator                   --> Gives user the general role "moderator" (not tied to any class or object)
#   user.is_candidate_of_what           --> Returns array of objects for which this user is a "candidate"
#   NEW: user.is_candidate_of_what Book --> Returns array of Book-Objects for which this user is a "candidate"
#
#   model.has_members                   --> Returns array of users which have role "member" on that model
#   model.has_members?                  --> Returns true/false
#

# TODO: Dieses Patch-File ist unschön. Eliminieren, entweder direkt im Code des Plugins, oder Plugin updaten oder sonstwas


module Authorization
  module Identity
    
    module UserExtensions
      module InstanceMethods

        def method_missing( method_sym, *args )
          method_name = method_sym.to_s
          authorizable_object = args.empty? ? nil : args[0]
          options = args[1] ? args[1] : {}
        
          base_regex = "is_(\\w+)"
          fancy_regex = base_regex + "_(#{Authorization::Base::VALID_PREPOSITIONS_PATTERN})"
          is_either_regex = '^((' + fancy_regex + ')|(' + base_regex + '))'
          base_not_regex = "is_no[t]?_(\\w+)"
          fancy_not_regex = base_not_regex + "_(#{Authorization::Base::VALID_PREPOSITIONS_PATTERN})"      
          is_not_either_regex = '^((' + fancy_not_regex + ')|(' + base_not_regex + '))'
        
          if method_name =~ Regexp.new(is_either_regex + '_what$')
            role_name = $3 || $6
            has_role_for_objects(role_name, authorizable_object, options)
          elsif method_name =~ Regexp.new(is_not_either_regex + '\?$')
            role_name = $3 || $6
            not is_role?( role_name, authorizable_object )
          elsif method_name =~ Regexp.new(is_either_regex + '\?$')
            role_name = $3 || $6
            is_role?( role_name, authorizable_object )
          elsif method_name =~ Regexp.new(is_not_either_regex + '$')
            role_name = $3 || $6
            is_no_role( role_name, authorizable_object )
          elsif method_name =~ Regexp.new(is_either_regex + '$')
            role_name = $3 || $6
            is_role( role_name, authorizable_object )
          else
            super
          end
        end
      
        private
      
        def has_role_for_objects(role_name, authorizable_type = nil, options = {})          
          # Falls authorizable_type mitgegeben, dann nur Rollen für Objekte dieser Klasse suchen
          roles = authorizable_type.nil? ? 
            self.roles.find_all_by_name( role_name ) : 
            self.roles.find( :all, :conditions => {:name => role_name, :authorizable_type => authorizable_type.to_s} )            

          # Falls auch noch weitere Bedingungen für einen bestimmten authorizable_type angegeben wurden, 
          # dann auch diese berücksichtigen
          if authorizable_type and options[:conditions]
            authorizable_type.find :all, :conditions => {:id => roles.collect{ |r| r.authorizable_id}.compact}.merge(options[:conditions])
          else          
            roles.collect do |role|
              if role.authorizable_id.nil? 
                role.authorizable_type.nil? ?
                  nil : Module.const_get( role.authorizable_type )   # Returns class
              else
                role.authorizable
              end
            end           
          end
          
        end
      end
    end
    
    module ModelExtensions
      module InstanceMethods

        def method_missing( method_sym, *args )
          method_name = method_sym.to_s
          if method_name =~ /^has_(\w+)\?$/
            role_name = $1.singularize            
            self.accepted_roles.find_all_by_name(role_name).any? { |role| role.users }
          elsif method_name =~ /^has_(\w+)$/
            role_name = $1.singularize
            users = Array.new
            # Alle User-Models für die Suche nach Rollen einbeziehen
            Role::USER_MODELS.each do |user_model|
              users << self.accepted_roles.find_all_by_name(role_name).collect { |role| role.send user_model.to_s.tableize }
            end
            users.flatten.uniq if users
          else
            super
          end
        end
        
      end
    end    
      
  end
end
