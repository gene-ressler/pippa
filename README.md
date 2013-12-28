# Pippa

Pippa - a Ruby gem for producing simple map graphics overlain with
geocoded dots of given area. Dot coordinates are in screen pixels,
latitude/longitude, or US zipcode.

## Installation

Add this line to your application's Gemfile:

    gem 'pippa'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pippa

## Usage

    require 'pippa'

    # Get available map names.
    puts Pippa.map_names

    # Make a new, clean map.
    map = Pippa::Map.new('USA') # or 29 other maps (default == 'World')

    # Change default dark red fill to dark green.
    # Changes cause dots entered so far to be rendered to graphic.
    # Several other parameters also control dot appearance.
    map.fill = 'DarkGreen'

    # Add a dot in the middle of the map using pixel coordinates.
    map.add_dot(map.width/2, map.height/2, 100)

    # Add a single green pixel dot at West Point, NY.
    # Between calls to render, dots are drawn biggest first, so
    # overlaps are generally okay.
    map.add_at_lat_lon(41.5, -74.1)

    # Flush buffered dots to the map.
    map.render

    # Add a dot with an area of 86 at a given zip code in Pennsylvania.
    # This will be drawn on top of all previous dots regardless of
    # size due to render above.
    map.add_at_zip('18088', 86)

    # Make a blob of the map e.g. suitable for Rails send_data.
    # Any RMagick blob format will work in lieu of 'png'
    blob = map.to_png

    # Write the map directly to a file using RMagick write.
    # Any RMagick writable format will work.
    map.write_jpg('mymap.jpg')

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
