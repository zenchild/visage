module Visage
  module Backends
    BACKENDS << Proc.new do |visage_conf, backend_conf|
      visage_conf['collectd_rrddir'] = backend_conf[:collectd][:rrddir]
    end
  end
end

require 'visage-app/backends/collectd/rrds'
require 'visage-app/backends/collectd/json'
