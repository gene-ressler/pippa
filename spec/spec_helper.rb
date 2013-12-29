require 'pippa'
require 'digest/md5'

# Utility functions for use in specs
module Utilities

  # Return contents of the zip code map exemplars.
  def get_test_map(fmt)
    File.open("#{File.dirname(__FILE__)}/data/zipcodes.#{fmt}", 'rb') { |f| f.read }
  end

  # Return a count of byte differences between two strings.
  def diff_count(a, b)
    return nil unless a.length == b.length
    n, b_iterator = 0, b.bytes
    a.bytes {|ia| n += 1 unless ia == b_iterator.next }
    n
  end

end

# Set configuration parameters of RSpec.
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  # config.filter_run :focus
  config.order = 'random'

  # Make the module above available in tests.
  config.include(Utilities)
end