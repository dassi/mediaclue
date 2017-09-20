
class PreviewGenerator

  OPENOFFICE_PORT = 8100

  # TODO: Hier nicht doppelspurig fahren mit dem openoffice_server Script
  # Und den Pfad variabel halten, in constants
  PIDFILE="tmp/pids/openoffice-headless.pid"
  LOGFILE="log/openoffice-headless.log"
                    
  attr_accessor :medium
  
  protected #######################################################################################
  
  def initialize(medium)
    
    @medium = medium
    
    @controller = DaemonController.new(
        :identifier => 'OpenOffice server',
        :start_command => './script/openoffice_server start',
        :stop_command => './script/openoffice_server stop',
        :start_timeout => 15,
        # :before_start => method(:before_start),
        :ping_command => './script/openoffice_server status',
        :ping_interval => 15,
        :pid_file => PIDFILE,
        :log_file => LOGFILE)
    
  end


  def source_file
    @medium.full_filename
  end

  
  def ensure_openoffice_ready
    if not @controller.running?
      @controller.start 
      # OPTIMIZE: Hier einfach x Sekunden warten ist nicht zuverlässig. Trotzdem braucht OO eine Zeit, bis es via Netzwerk verfügbar ist.
      # Wie kann man dies robust feststellen? Evt. Kommando via UNO senden?
      sleep(10)
    end
  end

  def random_tempfile_filename
    "#{rand Time.now.to_i}#{filename || 'attachment'}"
  end


  # Erstellt ein PDF via Background-Job bei Bedarf. Falls schon vorhanden, dann wird nicht erneut ein Background Job aufgesetzt.
  # Liefert den Namen des temporären PDF-Files
  def create_pdf_temp_file

    # Falls nicht schon gemacht, dann Job aufsetzen um PDF zu erzeugen
    if @pdf_temp_file.nil?
      
      # In Ruby 1.8.6 ist Tempfile nicht ganz so praktisch, weil es eine eigene File-Endung nimmt,
      # wir brauchen aber zwingend eine Endung .pdf
      if RUBY_VERSION == '1.8.6'
        # Dies hier ist evt. nicht ganz so sicher wie Tempfile, aber wir betrachten Ruby 1.8.6 als nicht empfohlen
        @pdf_temp_file = "#{TEMP_PATH}/temp_pdf_file_#{rand Time.now.to_i}.pdf"
      else
        @pdf_temp_file = Tempfile.new(['temp_pdf_file', '.pdf'], TEMP_PATH).path
      end
      Bj.submit(jodconverter_command(source_file, @pdf_temp_file))
    end
    
    @pdf_temp_file
  end

  
  def convert_document_to_flash_preview(preview_name)
    ensure_openoffice_ready

    filename = create_generated_filename(source_file, preview_name, 'swf')

    flash_preview = FlashPreview.new(:medium => @medium, :filename => filename, :name => preview_name.to_s)
    generated_file = flash_preview.full_filename
    FileUtils.mkdir_p(File.dirname(generated_file))
    
    temp_pdf_file = create_pdf_temp_file
    Bj.submit(pdf2swf_command(temp_pdf_file, generated_file))

    flash_preview.save!
  end


  def convert_document_cover_to_thumbnail(preview_name, max_dimension)
    ensure_openoffice_ready

    filename = create_generated_filename(source_file, preview_name, 'jpg')

    image_thumbnail = ImageThumbnail.new(:medium => @medium, :filename => filename, :name => preview_name.to_s, :height => max_dimension, :width => max_dimension)
    generated_file = image_thumbnail.full_filename
    FileUtils.mkdir_p(File.dirname(generated_file))
    
    temp_pdf_file = create_pdf_temp_file
    Bj.submit(image_resize_command(temp_pdf_file + '[0]', generated_file, max_dimension))

    image_thumbnail.save!
  end


  # Vereinfachte Variante von convert_document_cover_to_thumbnail für PDF
  def convert_pdf_cover_to_thumbnail(preview_name, max_dimension)

    filename = create_generated_filename(source_file, preview_name, 'jpg')

    image_thumbnail = ImageThumbnail.new(:medium => @medium, :filename => filename, :name => preview_name.to_s, :height => max_dimension, :width => max_dimension)
    generated_file = image_thumbnail.full_filename
    
    FileUtils.mkdir_p(File.dirname(generated_file))
    Bj.submit image_resize_command(source_file + '[0]', generated_file, max_dimension)

    image_thumbnail.save!
  end


  # Vereinfachte Variante von PDF zu Flash
  def convert_pdf_to_flash_preview(preview_name)

    filename = create_generated_filename(source_file, preview_name, 'swf')

    flash_preview = FlashPreview.new(:medium => @medium, :filename => filename, :name => preview_name.to_s)
    generated_file = flash_preview.full_filename
    
    FileUtils.mkdir_p(File.dirname(generated_file))
    Bj.submit pdf2swf_command(source_file, generated_file)

    flash_preview.save!
  end

  
  def convert_image_to_thumbnail(preview_name, max_dimension)

    filename = create_generated_filename(source_file, preview_name, 'jpg')
    image_thumbnail = ImageThumbnail.new(:medium => @medium, :filename => filename, :name => preview_name.to_s, :height => max_dimension, :width => max_dimension)
    generated_file = image_thumbnail.full_filename
    
    FileUtils.mkdir_p(File.dirname(generated_file))
    Bj.submit image_resize_command(source_file, generated_file, max_dimension)
    
    image_thumbnail.save!
    
  end


  def create_generated_filename(source_file, postfix, format_extension)
    File.basename(source_file) + '_' + postfix.to_s + '.' + format_extension.to_s
  end

  
  def image_resize_command(source_file, generated_file, max_dimension)
    size_string = "#{max_dimension}x#{max_dimension}>"

    "convert #{source_file} -resize \"#{size_string}\" -background white -flatten #{generated_file}"
  end


  def jodconverter_command(source_file, generated_file)
    # "cd lib/jodconverter-2.2.2/lib && java -jar jodconverter-cli-2.2.2.jar #{source_file} #{generated_file}"
    "java -jar lib/jodconverter-2.2.2/lib/jodconverter-cli-2.2.2.jar #{source_file} #{generated_file}"
  end

  
  def pdf2swf_command(pdf_file, generated_file, options = {})
    
    options[:pages] ||= "1-#{MAX_PAGES_DOCUMENT_PREVIEW}" if MAX_PAGES_DOCUMENT_PREVIEW
    options[:defaultviewer] = true if options[:defaultviewer].nil?
    options[:defaultloader] = true if options[:defaultloader].nil?
    
    command = 'pdf2swf '
    
    for key, value in options
      if value === true
        command << " --#{key}"
      elsif value === false
        # nichts tun
      else
        command << " --#{key} #{value}"
      end
    end
    
    command << " #{pdf_file} -o #{generated_file}"
    
    command
  end


  def cleanup
    if @pdf_temp_file
      Bj.submit "rm -f #{@pdf_temp_file}"
    end
  end

  
  public ##########################################################################################
  
  def generate(*preview_names)

    all = (preview_names.nil? or preview_names.empty?)

    @generated_previews = []
    
    case @medium
    when Image
      @generated_previews << convert_image_to_thumbnail('thumbnail', 85) if all or preview_names.include?('thumbnail')
      @generated_previews << convert_image_to_thumbnail('small', 150) if all or preview_names.include?('small')
      @generated_previews << convert_image_to_thumbnail('medium', 350) if all or preview_names.include?('medium')
      @generated_previews << convert_image_to_thumbnail('big', 800) if all or preview_names.include?('big')
      @generated_previews << convert_image_to_thumbnail('pdfslideshow', 1400) if all or preview_names.include?('pdfslideshow')
    when Document
      if @medium.pdf?
        @generated_previews << convert_pdf_to_flash_preview('normal')
        @generated_previews << convert_pdf_cover_to_thumbnail('thumbnail', 85) if all or preview_names.include?('thumbnail')
        @generated_previews << convert_pdf_cover_to_thumbnail('medium', 350) if all or preview_names.include?('medium')
      elsif not @medium.zip?
        @generated_previews << convert_document_to_flash_preview('flash_normal') if all or preview_names.include?('flash_normal')
        @generated_previews << convert_document_cover_to_thumbnail('thumbnail', 85) if all or preview_names.include?('thumbnail')
        @generated_previews << convert_document_cover_to_thumbnail('medium', 350) if all or preview_names.include?('medium')
      end
    end
    
    self.cleanup
    
    @generated_previews
  end
  
end