module Visage
  module Backends
    BACKENDS << Proc.new do |visage_conf, backend_conf|
      visage_conf['zenoss_server'] = backend_conf[:zenoss][:server]
      visage_conf['zenoss_user'] = backend_conf[:zenoss][:user]
      visage_conf['zenoss_pass'] = backend_conf[:zenoss][:pass]
    end
  end
end
