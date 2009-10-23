
class DocumentPreviewGenerator

  OPENOFFICE_PORT = 8100

  # TODO: Hier nicht doppelspurig fahren mit dem openoffice_server Script
  # Und den Pfad variabel halten, in constants
  OOO_HOME='/Applications/office/OpenOffice.org.app/Contents'
  PIDFILE="#{OOO_HOME}/openoffice-headless.pid"
  LOGFILE="#{OOO_HOME}/openoffice-headless.log"
  
  def initialize
    
    # log_file = 'log/openoffice.log'
    # pid_file = 'tmp/pids/openoffice.pid'
    
    @controller = DaemonController.new(
        :identifier => 'OpenOffice server',
        :start_command => './script/openoffice_server start',
        :stop_command => './script/openoffice_server stop',
        # :before_start => method(:before_start),
        :ping_command => './script/openoffice_server status',
        :ping_interval => 5,
        :pid_file => PIDFILE,
        :log_file => LOGFILE)
    
  end
  
  def ensure_openoffice_ready
    if not @controller.running?
      @controller.start 
      sleep(3)
    end
  end
  
  def convert(source_file, target_format_extension = 'pdf')
    ensure_openoffice_ready
    target_file = RAILS_ROOT + '/' + File.basename(source_file) + '.' + target_format_extension
    
    # TODO: Sourcefile kopieren? Sonst schnappt das jemand weg in Zwischenzeit?
    Bj.submit "cd lib/jodconverter-2.2.2/lib && java -jar jodconverter-cli-2.2.2.jar #{source_file} #{target_file}"
  end
end