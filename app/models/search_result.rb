class SearchResult
  
  attr_accessor :search_query, :media_set
  attr_reader :media, :media_sets_and_media
  
  def initialize(search_query)
    
    @search_query = search_query
    @media = []
    @media_sets_and_media = {}
    
  end
  
  def add_media(media)
    @media.concat(media.compact)
  end
  
  def add_media_sets_and_media(media_sets_and_media)
    for media_set, media in media_sets_and_media
      @media_sets_and_media[media_set] ||= []
      @media_sets_and_media[media_set].concat(media.compact)
    end
  end

  def empty?
    media.empty? && media_sets_and_media.empty?
  end
  
end