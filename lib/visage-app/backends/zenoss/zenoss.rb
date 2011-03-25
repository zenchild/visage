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

          if opts[:metrics].blank?
            datapoints
          else
            # This is a bit confusing at first glance, but what it does is lets us pass
            # a plugin name to the Zenoss backend even though nothing like that really exists
            # in the Zenoss world. It allows us to group stats based on the arbitrary plugin
            # name. For instance: myloads/laLoadInt* might group laLoadInt1_laLoadInt1 and
            # laLoadInt5_laLoadInt5 under myloads.
            opts[:metrics].split(/\s*,\s*/).inject([]) do |acc,si|
              plugin, inst = si.split(/\//)
              if inst.nil?
                re = Regexp.new plugin
                datapoints.select {|dp| re.match(dp)}.each do |dp|
                  acc << dp
                end
              else
                re = Regexp.new inst
                datapoints.select {|dp| re.match(dp)}.each do |dp|
                  acc << "#{plugin}/#{dp}"
                end
              end
              acc
            end
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
