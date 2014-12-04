unless SUPRESS_EARLY_DB_CONNECTION

  if ENV['FERRET_USE_LOCAL_INDEX'].blank?
    ferret_config = YAML.load_file("#{RAILS_ROOT}/config/ferret_server.yml")[RAILS_ENV]

    if ferret_config
      ferret_controller = DaemonController.new(
         :identifier    => 'Ferret Server',
         :start_command => "cd #{RAILS_ROOT}; #{RAILS_ROOT}/script/ferret_server start -e #{RAILS_ENV}",
         :stop_command  => "cd #{RAILS_ROOT}; #{RAILS_ROOT}/script/ferret_server stop -e #{RAILS_ENV}",
         :ping_command  => lambda { TCPSocket.new(ferret_config['host'], ferret_config['port']) },
         :pid_file      => ferret_config['pid_file'],
         :log_file      => ferret_config['log_file'],
         :timeout       => 25
      )

      if not ferret_controller.running?
        ferret_controller.start
      end
    end
  end
end