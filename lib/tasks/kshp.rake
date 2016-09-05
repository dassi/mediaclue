namespace :kshp do
  desc 'Erstellt für jeden Benutzer einen Suchauftrag nach Stichwort Schulanlass'
  task :create_schulanlass_query_for_all => :environment do

    now = DateTime.now
    query_name = 'Schulanlässe'
    
    for user in User.all
      query = user.search_queries.find_by_name(query_name)
      
      if query.nil?

        query = user.search_queries.build
        query.name = 'Schulanlässe'
        query.ferret_query = 'Schulanlass'
        query.images = true
        query.audio_clips = true
        query.video_clips = true
        query.documents = true
        query.my_media_only = false
        query.notifications_enabled = true
        query.last_notification_datetime = now

        query.save!
        puts 'Erstellt Schulanlass Query für ' + user.full_name
      else
        puts 'Bereits vorhanden für ' + user.full_name
      end
    end
  end
end
