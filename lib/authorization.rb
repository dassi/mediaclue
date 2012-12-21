module Authorization
  module ControllerMethods
    module ClassMethods
    
    end
  
    module InstanceMethods
      def permit(action, object, &block)
        permitted = object.permit?(current_user, action)
        if block_given?
          if permitted
            yield
          else
            flash[:error] = 'Zugriff nicht erlaubt'
            redirect_to root_url, :status => :forbidden
          end
        end
        permitted
      end
      alias_method :permit?, :permit
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.send :helper_method, :permit, :permit?
    end
  end


  #################################################################################################
  module ModelMethods
    module ClassMethods
    
    end
  
    module InstanceMethods
      def permit?(user, action)
        case action
        when :view
          can_view?(user)
        when :edit
          can_edit?(user)
        end
      end

      def can_view?(user)
        raise NotImplementedError
      end
      
      def can_edit?(user)
        raise NotImplementedError
      end
      
      def is_public?
        self.permission_type == 'public'
      end
      
      
    end
  
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end


  #################################################################################################
  module GroupPermissions
    module ClassMethods
      
    end
    
    module InstanceMethods

      def can_view?(user)
        case self.permission_type
        when 'public'
          true
        when 'all'
          user.is_a?(User)
        when 'owner'
          (self.owner == user)
        when 'groups'
          (self.owner == user) || (self.read_permitted_user_groups.any? { |g| g.member?(user) })
        else
          false
        end
      end

      def can_edit?(user)
        (self.owner == user) or (self.write_permitted_user_groups.any? { |g| g.member?(user) })
      end

      # Gibt in lesbarer Form die Leserechte zurück
      def read_permissions_description
        case self.permission_type
        when 'public'
          'Schulangehörige & öffentlich'
        when 'all'
          'Schulangehörige'
        when 'owner'
          'Nur Besitzer'
        when 'groups'
          'Gruppen: ' + self.read_permitted_user_groups.collect(&:full_name).join(', ')
        end
      end

      # Spezialisierter Setter
      def read_permitted_user_group_ids=(ids)

        # TODO! Wenn einmal auch write-Permissions tatsächlich verwendet werden, dann ist diese Funktion nicht mehr korrekt
        # Dann müsste man statt blanko löschen, jeden einzelnen Eintrag suchen updaten, und restliche löschen, oder so ähnlich
        
        if ids && ids.any?
          # Sicherstellen, dass die ID Nummern sind und keine Strings
          ids = ids.collect { |id| id.to_i }

          # Nichts tun, wenn die ids noch die gleichen sind
          return if ids.to_set == read_permitted_user_group_ids.to_set
          
          # Bestehende löschen...
          self.user_group_permissions.clear
                                 
          # ...und neu geltende wieder aufbauen
          for group_id in ids
            self.user_group_permissions.create(:user_group_id => group_id.to_i, :read => true)
          end
        end
      end

      def read_permitted_user_groups
        permitted_user_groups.readers
      end

      def read_permitted_user_group_ids
        read_permitted_user_groups.collect(&:id)
      end

      def write_permitted_user_groups
        permitted_user_groups.writers
      end
      
    end
    
    def self.included(receiver)
      receiver.has_many :user_group_permissions, :as => 'object', :dependent => :destroy, :autosave => true
      receiver.has_many :permitted_user_groups, :through => :user_group_permissions, :source => :user_group do
        def readers
          find(:all, :conditions => {:user_group_permissions => {:read => true}})
        end

        def writers
          find(:all, :conditions => {:user_group_permissions => {:write => true}})
        end
      end
      
      # Diese folgenden has_many dürfen wir nicht mehr verwenden, weil das Konflikte gab mit dem überschreiben
      # des setters read_permitted_user_group_ids. Das hat Rails nicht hingekriegt, und immer den eigenen Setter genommen.
      # receiver.has_many :read_permitted_user_groups, :through => :user_group_permissions, :source => :user_group, :conditions => {:user_group_permissions => {:read => true}}
      # receiver.has_many :write_permitted_user_groups, :through => :user_group_permissions, :source => :user_group, :conditions => {:user_group_permissions => {:write => true}}

      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
                                                                                                   

  #################################################################################################
  module UserMethods
    module ClassMethods
    
    end
  
    module InstanceMethods
      def can_view?(object)
        object.can_view?(self)
      end

      def can_edit?(object)
        object.can_edit?(self)
      end
    end
  
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end


# Wir erweitern Object um Authorization-Funktionalitäten, so dass wir ganz generell damit umgehen können
class Object
  
  # Filtert eine objects collection und liefert diejenigen Objekte zurück, bei welchen die action erlaubt ist
  def permitted_only(user, action)
    self.to_a.select { |item| item.permit?(user, action) }
  end
  
  def viewable_only(user)
    self.permitted_only(user, :view)
  end
  
  def editable_only(user)
    self.permitted_only(user, :edit)
  end

  # Default-Implementation, welche alle Rechte verneint
  def permit?(user, action)
    false
  end
  
end