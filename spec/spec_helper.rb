require 'pippa'
require 'digest/md5'

module Utilities

  def get_test_map(fmt)
    File.open("#{File.dirname(__FILE__)}/data/zipcodes.#{fmt}", 'rb') { |f| f.read }
  end

  def diff_count(a, b)
    return nil unless a.length == b.length
    n, b_iterator = 0, b.bytes
    a.bytes {|ia| n += 1 unless ia == b_iterator.next }
    n
  end

end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  # config.filter_run :focus
  config.order = 'random'

  config.include(Utilities)
end