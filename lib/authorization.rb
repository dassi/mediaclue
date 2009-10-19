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
    end
  
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end



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