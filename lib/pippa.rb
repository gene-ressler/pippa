require 'pippa/version'
require 'RMagick'
require 'csv'

module Pippa

  class Map
    include Magick

    attr_reader :width, :height
    attr_accessor :point_size, :fill, :stroke, :fill_opacity, :stroke_width

    ZipData = Struct.new(:zip, :city, :state, :lat, :lon)

    # Get global map and projection information from config file.
    def self.info
      @@info ||= info_from_file
    end

    # Initialize this map. Default is World map.  See maps/_info for all possible.
    def initialize(name = 'World')

      # Set up drawing standards.
      @point_size = 1
      @fill = 'DarkRed'
      @stroke = 'gray25'
      @fill_opacity = 0.85
      @stroke_width = 1

      # Look up global info or return if none.
      return unless @map_info = Map.info[:map][name]
      @image = Image.read("#{File.dirname(__FILE__)}/pippa/maps/#{@map_info[0]}").first
      @width, @height = @image.columns, @image.rows

      # Look up projection info, if any.
      @projection_info = Map.info[:projection][name]
    end

    # Add a dot on the map at given pixel coordinates with given area.
    def add_dot(x, y, area = 0)
      @gc ||= new_gc
      side = dot_side(area)
      if side <= 1
        @gc.line(x, y, x, y) # Use line, not point, to get stroke color
      else
        h = (0.5 * side).round
        x1 = x - h
        y1 = y - h
        @gc.rectangle(x1, y1, x1 + side, y1 + side)
      end
    end

    # Add a dot on the map at given latitude and longitude with given area.
    def add_at_lat_lon(lat, lon, area = 0)
      set_projection unless @lat_lon_to_xy
      add_dot(*@lat_lon_to_xy.call(lat, lon), area)
    end

    # Add a dot on the map at given 5-digit zip code.
    def add_at_zip(zip, area = 0)
      data = zips[zip]
      add_at_lat_lon(data.lat, data.lon, area) if data
    end

    def self.zips
      @@zips ||= zips_from_file
    end

    # Force rendering of all dots added so far onto the map.
    # Then forget them so they're never rendered again.
    def render
      return unless @gc && @image
      @gc.draw(@image)
      @gc = nil
    end

    # Return true iff we respond to given method. Takes care of to_???
    # converters to graphic formats.
    def respond_to? (sym, include_private = false)
      conversion_to_format(sym) ? true : super
    end

    # Implement to_??? methods where ??? is any valid Magick image
    # format that supports blob operations. Renders dots not already rendered.
    def method_missing(sym, *args, &block)
      fmt = conversion_to_format(sym)
      if fmt
        render
        @image.format = fmt
        @image.to_blob
      else
        super
      end
    end

    # Some tests.
    def self.run
      m = Map.new('USA')
      (1..10).each do |i|
        m.add_dot(i * 80, 300, i * 30)
      end
      m.add_at_lat_lon(41, -74, 300)
      m.add_at_lat_lon(38, -122, 300)
      p = m.to_png
      File.open('foo.png', 'wb') { |f| f.write(p) }
    end

    private

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

    def dot_side(size)
      (@point_size * Math.sqrt(size)).round
    end

    # Given a symbol like :to_png, :to_jpg,, :to_gif, return 'PNG', 'JPG', 'GIF' so
    # long as the part of the symbol after the underscore is a valid Magick blob format.
    def conversion_to_format(sym)
      return nil unless sym.to_s =~ /^to_(.*)$/
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

    # "Zipcode","ZipCodeType","City","State","LocationType","Lat","Long","Location","Decommisioned","TaxReturnsFiled","EstimatedPopulation","TotalWages"
    def self.zips_from_file
      zips = {}
      CSV.foreach("#{File.dirname(__FILE__)}/pippa/maps/_zipcodes.csv",
                  :headers => :first_row,
                  :converters => [nil, nil, nil, nil, nil, :float, :float, nil, nil, :integer, :integer, :integer]) do |row|
        zips[row[0]] = ZipData.new(row[0], row[2], row[3], row[5], row[6])
      end
      zips
    end
  end
end
