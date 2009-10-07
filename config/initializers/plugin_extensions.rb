module Technoweenie # :nodoc:
  module AttachmentFu # :nodoc:
    module InstanceMethods
      def ext
        ext = File.extname(self.filename)
        ext[1..-1] # Punkt an erster Stelle entfernen
      end
    end
  end
end

require 'ruby_extensions'

WillPaginate::ViewHelpers.pagination_options[:prev_label] = '&laquo; zurück'
WillPaginate::ViewHelpers.pagination_options[:next_label] = 'vor &raquo;'