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
          datapoints = []
          if opts[:host]
            host = zenoss.find_devices_by_name(opts[:host]).first
            datapoints += (host.get_rrd_data_points.map {|dp| dp.name})
          else
            opts[:hosts].strip.split(/\s*,\s*/).each do |host|
              host = zenoss.find_devices_by_name(host).first
              datapoints |= (host.get_rrd_data_points.map {|dp| dp.name})
            end
          end
          case
          when opts[:metrics].blank?
            datapoints
          when opts[:metrics] =~ /,/
            selection = opts[:metrics].split(/\s*,\s*/)
            selection & datapoints
          when opts[:metrics] =~ /\*/
            re = Regexp.new opts[:metrics]
            datapoints.select {|dp| re.match(dp)}
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
