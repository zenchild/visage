# Exposes RRDs as JSON.
#
# A loose shim onto RRDtool, with some extra logic to normalise the data.
#
module Visage::Backends
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

      zhost = @zenoss.find_devices_by_name(host).first
      rrd = zhost.fetch_rrd_value(plugin, (Time.now - 3600).to_datetime)

      data = []

      data << {
        :host   => host,
        :plugin => plugin,
        :start  => rrd[:start],
        :finish => rrd[:end],
        :data   => rrd[:rrdvalues],
      }

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
        instance = data[:plugin]
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
