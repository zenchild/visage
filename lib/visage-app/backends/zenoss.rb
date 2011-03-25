require 'visage-app/backends/zenoss/rrds'
require 'visage-app/backends/zenoss/json'

module Visage
  module Backends
    LOADERS << Proc.new do |visage_conf, backend_conf|
      visage_conf['zenoss_server'] = backend_conf[:zenoss][:server]
      visage_conf['zenoss_user'] = backend_conf[:zenoss][:user]
      visage_conf['zenoss_pass'] = backend_conf[:zenoss][:pass]
    end

    BACKENDS[:zenoss] = Visage::Zenoss::RRDs
  end
end
