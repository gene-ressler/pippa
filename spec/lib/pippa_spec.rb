require 'spec_helper'

# Test the Pippa API. Much more work possible here.
describe Pippa do

  it 'should report version' do
    Pippa::VERSION.should_not be_nil
  end

  it 'should return map names' do
    Pippa.map_names.size.should be == 30
  end

  it 'should have right number of zipcodes' do
    Pippa.zips.size.should == 41874
  end

end
