# Ruport Renderer, die eine Diashow der Medien des MediaSets als PDF erzeugt
class PdfSlideShowController < Ruport::Controller
  stage :slide_show
  required_option :filename, :media_set, :images
end  

class PdfSlideShowFormatter < Ruport::Formatter::PDF    
  renders :pdf, :for => PdfSlideShowController        
  proxy_to_pdf_writer

  build :slide_show do
    #options.paper_size = 'A4'
    options.paper_size = [21, 28]
    options.paper_orientation = :landscape      
    options.text_format = { :font_size => 12 }      
    catalog.page_mode = 'FullScreen'

    page_margin = 25
    page_inner_width = page_width - (2 * page_margin)
    page_inner_height = page_height - (2 * page_margin)

#        fill_color Color::RGB::Black
#        rectangle(0, 0, page_width, page_height).fill

    fill_color Color::RGB::Black
    select_font 'Helvetica'
    add_text options.media_set.caption.to_latin1, :font_size => 24 if options.media_set.caption
    add_text ' '
    add_text options.media_set.desc.to_latin1, :font_size => 12 if options.media_set.desc
    add_text ' '
    add_text "Schlagworte: #{options.media_set.tags.to_s.to_latin1}", :font_size => 12 if options.media_set.desc
    add_text ' '
    # add_text "Bilder:", :font_size => 12
    # add_text ' '

    # # Schwarzes Hintergrund-Rechteck
    # fill_color Color::RGB::Black
    # rectangle(0, 0, page_width, page_height).fill
    
    number_and_images = (1..options.images.size).zip(options.images)
    table_data = number_and_images.collect do |number, image|
      [number.to_s, image.name.to_latin1, image.original_filename.to_latin1, image.desc ? image.desc[0..80].to_latin1 : '', image.tags.to_s.to_latin1]
    end
    
    table = Ruport::Data::Table.new :data => table_data,
                                    :column_names => ['Nr.', 'Name', 'Dateiname', 'Beschreibung (Anriss)', 'Schlagworte']
    
    options.table_format = {:width => page_inner_width, :font_size => 8}
    draw_table table

    # Kontaktbogen
    y_index = 0
    image_margin = 5
    x_count = 12
    y_count = 10
    thumb_width = ((page_inner_width / x_count) - image_margin).to_i
    thumb_height = ((page_inner_height / y_count) - image_margin).to_i
    number_and_images.in_groups_of(x_count * y_count, false) do | image_page_group |
      
      start_new_page
      
      image_page_group.in_groups_of(x_count, false) do | image_line_group |
    
        y = (page_height - page_margin - thumb_height) - (y_index * (thumb_height + image_margin))
      
        x_index = 0
        for number, image in image_line_group
        
          x = page_margin + (x_index * (thumb_width + image_margin))
        
          # Bild platzieren
          fill_color(Color::RGB::Black)
          rectangle(x, y, thumb_width, thumb_height).fill
          center_image_in_box(image.full_filename(:small), :x => x, :y => y, :width => thumb_width, :height => thumb_height)
          fill_color(Color::RGB::White)
          pdf_writer.add_text(x, y, number.to_s)
          add_internal_link(number.to_s, x, y, x+thumb_width, y+thumb_height)

          x_index += 1
        end
        
        y_index += 1
      end
    end

    
    # Jedes Bild auf einer neue Seite platzieren
    for number, image in number_and_images

      # Neue Seite starten
      start_new_page

      # Schwarzes Hintergrund-Rechteck
      fill_color Color::RGB::Black
      rectangle(0, 0, page_width, page_height).fill
      
      # Bild platzieren
      begin
        center_image_in_box(image.full_filename(:pdfslideshow), :x => 0, :y => 0, :width => page_width, :height => page_height)
        add_destination(number.to_s, 'Fit')
      rescue TypeError
        # puts "Error adding image to PDF-slideshow: " + $!
        raise
      end
    end

    save_as options.filename
  end
end      
