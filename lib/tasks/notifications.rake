namespace :mediaclue do
  namespace :notifications do

    desc "Checks all search queries with notifications and sends emails"
    task :check_all => :environment do

      now = DateTime.now

      # Alle Search Queries holen, welche Email Notifikation aktiviert haben
      search_queries = SearchQuery.with_notifications_enabled
      
      # Für jede Search Query
      for search_query in search_queries
      
        next if search_query.user.email.nil?
        
        # Nur machen, sofern ein Datum des letzten Durchgangs bekannt ist. Dies verhindert, dass
        # bei erstmaligem Durchlauf, gleich sämtliche Suchresultate gemeldet werden.
        if search_query.last_notification_datetime
          # Ausführen mit dem Zusatz younger_than, genommen von search_query.last_notification_datetime
          search_query.younger_than = search_query.last_notification_datetime
          search_result = search_query.execute
        
          # Falls Resultate vorhanden, dann eine Mail senden, mit diesen Angaben und einem Link auf jedes einzelne Medium
          # und ein Link auf die gespeicherte Suchabfrage
          if not search_result.empty?
            Notifications.deliver_new_search_result_notification(search_query.user, search_result)
          end
        end
        
        search_query.last_notification_datetime = now
        search_query.save!
      end
        
    end
    
    
    task :create_schulanlass_search_for_all => :environment do
      
      
    end
  end
end
