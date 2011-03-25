module Visage::Backends

  # This class exposes Zenoss datasources as JSON data that is compatible with
  # what Visage expects to render graphs with.
  class ZenossJSON

    def initialize(opts={})
      server = Visage::Config.zenoss_server
      user   = Visage::Config.zenoss_user
      pass   = Visage::Config.zenoss_pass
      @zenoss = ::Zenoss.connect server, user, pass
    end

    # Entry point.
    def json(opts={})
      host             = opts[:host]
      plugin           = opts[:plugin]
      plugin_instances = opts[:plugin_instances][/\w.*/]

      zhost = @zenoss.find_devices_by_name(host).first

      data = []

      if(plugin_instances.blank?)
        rrd = zhost.fetch_rrd_value(plugin, (Time.now - 3600).to_datetime)
        data << {
          :host   => host,
          :plugin => plugin,
          :start  => rrd[:start],
          :finish => rrd[:end],
          :data   => rrd[:rrdvalues],
        }
      else
        plugin_instances.split(/\s*,\s*/).each do |instance_name|
          rrd = zhost.fetch_rrd_value(instance_name, (Time.now - 3600).to_datetime)
          data << {
            :host   => host,
            :plugin => plugin,
            :instance => instance_name,
            :start  => rrd[:start],
            :finish => rrd[:end],
            :data   => rrd[:rrdvalues],
          }
        end
      end

      encode(data)
    end

    private
    # Attempt to structure the JSON reasonably sanely, so the consumer (i.e. a
    # browser) doesn't have to do a lot of computationally expensive work.
    def encode(datas)

      structure = {}
      datas.each do |data|
        rrd_data = data[:data]

        host     = data[:host]
        plugin   = data[:plugin]
        instance = data[:instance]
        start    = data[:start].to_i
        finish   = data[:finish].to_i
        source   = 'ds0'

        structure[host] ||= {}
        structure[host][plugin] ||= {}
        structure[host][plugin][instance] ||= {}
        structure[host][plugin][instance][source] ||= {}
        structure[host][plugin][instance][source][:start]  ||= start
        structure[host][plugin][instance][source][:finish] ||= finish
        structure[host][plugin][instance][source][:data]   ||= rrd_data

      end

      encoder = Yajl::Encoder.new
      encoder.encode(structure)
    end

  end
end # Visage::Backends
