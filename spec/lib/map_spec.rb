require 'spec_helper'

# Test functions of the Pippa::Map API lightly.  Much more possible here.
describe Pippa::Map do

  let(:map) { Pippa::Map.zipcode_map }

  it 'should be correct width' do
    map.width.should == 1046
  end

  it 'should be correct width' do
    map.height.should == 710
  end

  it 'should have correct number of info records' do
    i = Pippa::Map.info
    i.size.should == 2
    i[:map].size.should == 30
    i[:projection].size.should == 4
  end

  # Here I'm assuming timestamp metadata chunk always has same size.
  # PNG docs are encouraging on this:
  # http://www.libpng.org/pub/png/book/chapter11.html#png.ch11.div.2
  it 'should have matching PNG format' do
    test_map = get_test_map('png')
    new_map = map.to_png
    test_map.size.should == new_map.size
    # A minor difference will occur in header due to timestamp, etc.
    diff_count(test_map, new_map).should be < 100
  end

  it 'should have matching JPG format' do
    test_map = get_test_map('jpg')
    new_map = map.to_jpg
    test_map.size.should == new_map.size
    diff_count(test_map, new_map).should be == 0
  end
end