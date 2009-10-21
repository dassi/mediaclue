# The Tag model. This model is automatically generated and added to your app if you run the tagging generator included with has_many_polymorphs.
class Tag < ActiveRecord::Base

  PARSE_EXPRESSION_SPLITTER = /"(.+?)"|\s+|[,;]\s*/ # Controls how to split tagnames from strings. You may need to change the <tt>validates_format_of parameters</tt> if you change this.
  TAG_ERROR_TEXT = 
    "Das Schlagwort \"%s\" enthält ungültige Zeichen! <br/>" + 
    "Nur folgende Zeichen sind erlaubt: A-Z, a-z, 0-9, Ä, Ö, Ü, È, É, À, ä, ö, ü, è, é, à, ß, ç, \", _, -. <br/>" + 
    'Komma, Semicolon und Leerzeichen trennt Schlagworte voneinander.<br/>' + 
    'Mehrwort-Schlagworte durch doppelte Anführungszeichen begrenzen.'
   
  def validate
    errors.add(:name, TAG_ERROR_TEXT) unless tag_name_valid?
  end

  # If database speed becomes an issue, you could remove these validations and rescue the ActiveRecord database constraint errors instead.
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false

  # Set up the polymorphic relationship.
  has_many_polymorphs :taggables,
    :from => [:images, :documents, :audio_clips, :media_sets, :video_clips],
    :through => :taggings,
    :dependent => :destroy,
    :skip_duplicates => false,
    :parent_extend => proc {
      # Defined on the taggable models, not on Tag itself. Return the tagnames associated with this record as a string.
      def to_s
        self.map { |e| tag_name = e.name; tag_name.include?(" ")  ? "\"#{tag_name}\"" : tag_name}.sort.join(' ')
      end
    },
    :extend => proc {
      def for_user(user)
        find(:all, :conditions => {:owner_id => user})
      end
    }


  # Callback to strip extra spaces from the tagname before saving it. If you allow tags to be renamed later, you might want to use the <tt>before_save</tt> callback instead.
  def before_create
    self.name = name.strip.squeeze(" ")
  end

  # Tag::Error class. Raised by ActiveRecord::Base::TaggingExtensions if something goes wrong.
  class Error < StandardError
  end

  def tag_name_valid?
    not (name =~ /^[a-zäöüèéàßçA-ZÄÖÜÈÉÀ0-9\_\-" ]+$/).nil?
  end

end


