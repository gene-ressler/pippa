# Pippa - a Ruby gem for producing simple map graphics overlain with
# geocoded dots of given area. The geocoding is by lat/lon or US zipcode.
#
# Author::    Gene Ressler  (mailto:gene.ressler@gmail.com)
# Copyright:: Copyright (c) 2013 Gene Ressler
# License::   See LICENSE.TXT
#
require 'pippa/version'
require 'RMagick'
require 'csv'

module Pippa

  # Return a list of the valid map names
  def map_names
    Map.info[:map].keys
  end

  # An image-based map class that can be overlain with dots
  # of given area and location given by pixel coordinates, lat/lon,
  # or zipcode (courtesy of http://federalgovernmentzipcodes.us).
  class Map
    include Magick

    # Width of the map image in pixels
    attr_reader :width

    # Height of the map image in pixels
    attr_reader :height

    # Base size of dot edges in pixels; defaults to 1
    attr_reader :point_size

    ##
    # :attr_writer: point_size

    # Dot fill color
    attr_reader :fill

    ##
    # :attr_writer: fill

    # Dot fill opacity
    attr_reader :fill_opacity

    ##
    # :attr_writer: fill_opacity

    # Dot border stroke color name
    attr_reader :stroke

    ##
    # :attr_writer: stroke

    # Dot border stroke width
    attr_reader :stroke_width

    ##
    # :attr_writer: stroke_width

    # RMagick image for direct manipulation, e.g. labeling
    attr_reader :image

    # Return global map and projection information from config file.
    # See +maps/_info+ for format. For extending functionality.
    def self.info
      @@info ||= info_from_file
    end

    # Make a new map with given name.  Default is World.
    # See +maps/_info+ or call +Pippa.map_names+ for all possible.
    def initialize(name = 'World')

      # Set up drawing standards.
      @point_size = 1
      @fill = 'DarkRed'
      @stroke = 'gray25'
      @fill_opacity = 0.85
      @stroke_width = 1
      @dots = []

      # Look up global info or return if none.
      return unless @map_info = Map.info[:map][name]
      @image = Image.read("#{File.dirname(__FILE__)}/pippa/maps/#{@map_info[0]}").first
      @width, @height = @image.columns, @image.rows

      # Look up projection info, if any.
      @projection_info = Map.info[:projection][name]
    end

    # Add a dot of given area at the given pixel coordinates.
    #
    # ==== Attributes
    #
    # * +x+ - Dot x-pixel coordinate
    # * +y+ - Dot y-pixel coordinate
    # * +area+ - Optional area, defaults to single pixel
    #
    # ==== Examples
    #
    # Make a map and put a dot in the middle.
    #
    # map = Map.new('USA')
    # map.add_dot(map.width/2, map.height/2, 100)
    # map.write_png('map.png')
    def add_dot(x, y, area = 0)
      @dots << [x, y, area]
    end

    # Add a dot on the map at given latitude and longitude with given area.
    #
    # ==== Attributes
    #
    # * +lat+ - Dot latitude
    # * +lon+ - Dot longitude
    # * +area+ - Optional area, defaults to single pixel
    #
    # ==== Examples
    #
    # Make a map and put a dot at West Point, NY.
    #
    # map = Map.new('USA')
    # map.add_at_lat_lon(41, -74, 100)
    # map.write_png('map.png')
    def add_at_lat_lon(lat, lon, area = 0)
      set_projection unless @lat_lon_to_xy
      add_dot(*@lat_lon_to_xy.call(lat, lon), area)
    end

    # Add a dot on the map at given 5-digit zip code.
    #
    # ==== Attributes
    #
    # * +zip+ - Zipcode
    # * +area+ - Optional area, defaults to single pixel
    #
    # ==== Examples
    #
    # Make a map and put a dot at West Point, NY.
    #
    #    map = Map.new('USA')
    #    map.add_at_zip('10996', 100)
    #    map.write_png('map.png')
    def add_at_zip(zip, area = 0)
      data = Map.zips[zip]
      add_at_lat_lon(data[:lat], data[:long], area) if data
    end

    # Return a hash mapping zip codes to CSV records of zip code data.
    # NB: The file is big, so this takes a while to return the first time called.
    #
    # CSV::Row struct format (see also http://ruby-doc.org/stdlib-1.9.2/libdoc/csv/rdoc/CSV/Row.html:
    #
    #     #<CSV::Row
    #       zipcode:"97475"
    #       zip_code_type:"PO BOX"
    #       city:"SPRINGFIELD"
    #       state:"OR"
    #       location_type:"PRIMARY"
    #       lat:44.05
    #       long:-123.02
    #       location:"NA-US-OR-SPRINGFIELD"
    #       decommisioned:"false"
    #       tax_returns_filed:nil
    #       estimated_population:nil
    #       total_wages:nil>
    #
    # See http://federalgovernmentzipcodes.us for more information.
    def self.zips
      @@zips ||= zips_from_file
    end

    # Force rendering of all dots added so far onto the map.
    # Then forget them so they're never rendered again.
    def render
      return if @image.nil? || @dots.empty?
      @dots.sort! {|a, b| b[2] <=> a[2] } # by area, smallest last
      gc = new_gc
      @dots.each do |x, y, area|
        side = dot_side(area)
        if side <= 1
          gc.point(x, y)
        else
          h = (0.5 * side).round
          x1 = x - h
          y1 = y - h
          gc.rectangle(x1, y1, x1 + side, y1 + side)
        end
      end
      gc.draw(@image)
      @dots = []
    end

    # Return true iff we respond to given method. Takes care of to_???
    # and write_???? converters and writers of graphic formats.
    def respond_to? (sym, include_private = false)
      conversion_to_format('to', sym) || conversion_to_format('write', sym) ? true : super
    end

    # Implement to_??? methods where ??? is any valid Magick image
    # format that supports blob operations. Renders dots not already rendered.

    ##
    # :method: to_xxx
    # Return map as a blob with Magick format +xxx+.
    # Get a full list of formats with
    #    Magick.formats.each {|k,v| puts k if v.include?('*') }

    ##
    # :method: write_xxx(filename)
    # Write map as graphic file in Magick format xxx.
    # File suffix is *not* added automatically.
    # Get a full list of formats with
    #    Magick.formats.each {|k,v| puts k if v.include?('*') }

    def method_missing(sym, *args, &block)

      # Handle graphic attribute setters. flushing with render first.
      if GRAPHIC_ATTRIBUTE_SETTERS.include?(sym)
        render
        return instance_variable_set("@#{sym.to_s[0..-2]}", args[0])
      end

      # Handle to_??? format converters, again flushing with render.
      fmt = conversion_to_format('to', sym)
      if fmt
        render
        @image.format = fmt
        return @image.to_blob
      end

      # Handle write_??? file writers, again flushing with render
      fmt = conversion_to_format('write', sym)
      if fmt
        render
        @image.format = fmt
        return @image.write(args[0])
      end

      # Punt on everything else.
      super
    end

    # Make a map showing all the zip codes in the USA with
    # dots of random size. Also a couple of additional dots.
    def self.zipcode_map
      @generator ||= Random.new
      m = Map.new('USA')
      zips.each_key.each do |zip|
        m.add_at_zip(zip, @generator.rand(8) ** 2)
      end
      m.fill = 'red'
      m.fill_opacity = 1
      m.add_at_lat_lon(41, -74, 300) # West Point, NY
      m.add_at_lat_lon(38, -122, 300) # Berkeley, CA
      m
    end

    # Write the test map produced by +zipcode_map+ in two different formats.
    def self.write_zipcode_maps
      m = zipcode_map
      File.open('zipcodes.png', 'wb') { |f| f.write(m.to_png) }
      m.write_jpg('zipcodes.jpg')
    end

    private

    #:nodoc:
    GRAPHIC_ATTRIBUTE_SETTERS = [:point_size=, :fill=, :stroke=, :fill_opacity=, :stroke_width=]

    # Build a new graphics context for rendering.
    def new_gc
      gc = Magick::Draw.new
      gc.fill(@fill)
      gc.stroke(@stroke)
      gc.fill_opacity(@fill_opacity)
      gc.stroke_width(@stroke_width)
      gc
    end

    # Set the projection from the configuration projection information.
    def set_projection
      if @projection_info
        case @projection_info[0]
          when 'ALBER'
            r = Float(@projection_info[1])
            false_easting = Float(@projection_info[6])
            false_northing = Float(@projection_info[7])
            phi_1, phi_2, phi_0, lmd_0 = @projection_info[2..5].map {|s| Float(s) * Math::PI / 180.0 };
            n = 0.5 * (Math.sin(phi_1) + Math.sin(phi_2))
            c = Math.cos(phi_1) ** 2 + 2.0 * n * Math.sin(phi_1)
            @lat_lon_to_xy = lambda do |lat, lon|
              phi = lat * Math::PI / 180.0
              lmd = lon * Math::PI / 180.0
              p   = r * Math.sqrt(c - 2.0 * n * Math.sin(phi)) / n
              p_0 = r * Math.sqrt(c - 2.0 * n * Math.sin(phi_0)) / n
              theta = n * (lmd - lmd_0)
              x = false_easting + p * Math.sin(theta)
              y = false_northing - (p_0 - p * Math.cos(theta))
              [x, y]
            end
          else
            fail "Unknown projection #{@projection_info[0]}"
        end
      else
        top_lat, top_lon, bot_lat, bot_lon = @map_info[1..4].map {|s| Float(s) }
        lat_scale = @height / (top_lat - bot_lat)
        lon_scale = @width  / (bot_lon - top_lon)
        @lat_lon_to_xy = lambda do |lat, lon|
          [(lon - top_lon) * lon_scale, (top_lat - lat) * lat_scale]
        end
      end
    end

    # Return the integer size of the side of a dot of given area.
    def dot_side(area)
      (@point_size * Math.sqrt(area)).round
    end

    # For given string +prefix+ and a symbol like +:<prefix>_png+ or +:<prefix>_jpg+,
    # return 'PNG' or 'JPG' so long as the part of the symbol after the underscore
    # is a valid Magick image format.  Otherwise return +nil+.
    def conversion_to_format(prefix, sym)
      return nil unless sym.to_s =~ /^#{prefix}_(.*)$/
      format_name = $1.upcase
      return nil unless format = Magick.formats[format_name]
      format.include?('*') && format_name
    end

    # Format:
    # MAP World World100.png 90 -170 -90 190
    # PROJECTION  USA50 ALBER  704.0 30.8 45.5 21.86 -99.9 232 388
    def self.info_from_file
      File.open("#{File.dirname(__FILE__)}/pippa/maps/_info", 'r') do |f|
        data = {}
        while (line = f.gets)
          tag, name, *vec = line.split
          tag = tag.downcase.to_sym
          data[tag] ||= {}
          data[tag][name] = vec
        end
        data
      end
    end

    # Read CSV file of zipcode data.  Much more than we need.
    # TODO: Develop quicker-loading version of the data file.
    # Format:
    #     "Zipcode","ZipCodeType","City","State","LocationType","Lat","Long",
    #     "Location","Decommisioned","TaxReturnsFiled","EstimatedPopulation","TotalWages"
    def self.zips_from_file
      CSV::HeaderConverters[:underscore_symbol] = lambda do |s|
        t = s.gsub(/::/, '/')
        t.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        t.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        t.tr!("-", "_")
        t.downcase!
        t.to_sym
      end
      CSV::Converters[:custom] = lambda do |s, info|
        begin
          [:lat, :long].include?(info.header) ? Float(s) : s
        rescue
          s
        end
      end
      zips = {}
      CSV.foreach("#{File.dirname(__FILE__)}/pippa/maps/_zipcodes.csv",
                  :headers => :first_row,
                  :header_converters => :underscore_symbol,
                  :converters => :custom) do |row|
        zips[row[:zipcode]] = row if row[:lat] && row[:long]
      end
      zips
    end
  end
end
