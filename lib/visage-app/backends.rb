# This is a module that is the foundation of support for multiple types of RRD Backends.
# To add a backend create a self-configuring proc to a <backendname>.rb file. See the
# collectd or zenoss backends for examples. The actual configuration parameters should
# go in 'lib/visage-app/config/backends.yaml'
module Visage
  module Backends
    # Each backend should load a Proc into this array that gets called when Visage is
    # loaded via the 'configure' block.
    LOADERS = []

    # This is a list of key/value pairs in the form :backend_name => backend_class.
    # For instance, :collectd => Visage::Collectd::RRDs
    # The class does not have to be in the Backends module, it's only requirement is
    # that is responds to the appropriate methods.
    BACKENDS = {}
  end # Backends
end # Visage

require 'visage-app/backends/collectd'
require 'visage-app/backends/zenoss'
