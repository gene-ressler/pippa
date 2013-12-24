require "pippa/version"

module Pippa

  class Map

    def self.map_data
      @@data ||= map_info_from_file
    end

    def self.map_info_from_file
      File.open("#{File.dirname(__FILE__)}/maps/_info", 'r') do |f|
        data = Hash.new({})
        while (line = f.gets)
          tag, name, *vec = line.split
          data[tag][name] = vec
        end
        data
      end
    end

    # Format:
    # MAP World World100.png 90 -170 -90 190
    # PROJECTION  USA50 ALBER  704.0 30.8 45.5 21.86 -99.9 232 388
    def initialize(name = 'World')

    end

  end
end
