#!/usr/bin/env ruby

$: << File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

require 'lib/visage-app/patches'
require 'zenoss'

module Visage
  module Zenoss
    class RRDs

      class << self

        def hosts(opts={})
          puts "-----------------> Called hosts for #{self.name}"
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

        def metrics(opts={})
          puts "-----------------> Called metrics for #{self.name}"
          server = Visage::Config.zenoss_server
          user   = Visage::Config.zenoss_user
          pass   = Visage::Config.zenoss_pass
          zenoss = ::Zenoss.connect server, user, pass

          if opts[:hosts].blank?
            []
          else
            host = zenoss.find_devices_by_name(opts[:hosts]).first
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
          end
        end

      end

    end
  end
end
