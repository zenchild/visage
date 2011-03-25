module Visage
  module Backends
    class Zenoss

      def self.hosts(opts={})
        server = Visage::Config.zenoss_server
        user   = Visage::Config.zenoss_user
        pass   = Visage::Config.zenoss_pass
        zenoss = ::Zenoss.connect server, user, pass

        if opts[:hosts].blank?
          hosts = zenoss.get_devices.map {|dev| dev.name}
        else
          hosts = []
          opts[:hosts].strip.split(/\s*,\s*/).each do |host|
            zenoss.find_devices_by_name(host).each do |dev|
              hosts << dev.name
            end
          end
        end

        hosts
      end

      def self.metrics(opts={})
        server = Visage::Config.zenoss_server
        user   = Visage::Config.zenoss_user
        pass   = Visage::Config.zenoss_pass
        zenoss = ::Zenoss.connect server, user, pass

        if opts[:host] || opts[:hosts]
          if opts[:host]
            key = :host
          else
            key = :hosts
          end
          host = zenoss.find_devices_by_name(opts[key]).first
          datapoints  = host.get_rrd_data_points.map {|dp| dp.name}
          case
          when opts[:metrics].blank?
            datapoints
          when opts[:metrics] =~ /,/
            selection = opts[:metrics].split(/\s*,\s*/)
            selection & datapoints
          else
            [opts[:metrics]] & datapoints
          end
        else
          []
        end
      end

      def self.json_encoder(opts={})
        Visage::Backends::ZenossJSON.new(opts)
      end

    end # Zenoss
  end # Backends
end # Visage
