module Technoweenie # :nodoc:
  module AttachmentFu # :nodoc:
    module InstanceMethods
      def ext
        ext = File.extname(self.filename)
        ext[1..ext.length - 1]
      end
    end
  end
end

require 'ruby_extensions'
require 'authorization_identity_patch'

WillPaginate::ViewHelpers.pagination_options[:prev_label] = '&laquo; zurück'
WillPaginate::ViewHelpers.pagination_options[:next_label] = 'vor &raquo;'