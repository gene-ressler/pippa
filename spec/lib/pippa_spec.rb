require 'spec_helper'

describe Pippa do

  it 'should report version' do
    Pippa::VERSION.should_not be_nil
  end

  it 'should return map names' do
    Pippa.map_names.size.should be == 30
  end

end
