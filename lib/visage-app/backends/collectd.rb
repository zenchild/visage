require 'visage-app/backends/collectd/rrds'
require 'visage-app/backends/collectd/json'

module Visage
  module Backends
    LOADERS << Proc.new do |visage_conf, backend_conf|
      visage_conf['collectd_rrddir'] = backend_conf[:collectd][:rrddir]
    end

    BACKENDS[:collectd] = Visage::Collectd::RRDs
  end
end
