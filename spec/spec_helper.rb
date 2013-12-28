require 'pippa'

module Utilities

  def self.get_test_map(fmt)
    File.open("#{File.dirname(__FILE__)}/data/zipcodes.#{fmt}", 'rb') { |f| f.read }
  end

end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  config.include(Utilities)
end