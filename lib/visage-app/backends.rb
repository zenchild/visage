# This is a module that is the foundation of support for multiple types of RRD Backends.
# To add a backend create a self-configuring proc to a <backendname>.rb file. See the
# collectd or zenoss backends for examples. The actual configuration parameters should
# go in 'lib/visage-app/config/backends.yaml'
module Visage
  module Backends
    BACKENDS = []
  end # Backends
end # Visage

require 'visage-app/backends/collectd'
require 'visage-app/backends/zenoss'
