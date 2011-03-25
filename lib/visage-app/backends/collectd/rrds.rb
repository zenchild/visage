#!/usr/bin/env ruby

$: << File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

require 'lib/visage-app/patches'

module Visage
  module Collectd
    class RRDs

      class << self
        def rrddir
          @rrddir ||= Visage::Config.collectd_rrddir
        end

        def hosts(opts={})
          case
          when opts[:hosts].blank?
            glob = "*"
          when opts[:hosts] =~ /,/
            glob = "{#{opts[:hosts].strip.gsub(/\s*/, '').gsub(/,$/, '')}}"
          else
            glob = opts[:hosts]
          end

          Dir.glob("#{rrddir}/#{glob}").map {|e| e.split('/').last }.sort.uniq
        end

        def metrics(opts={})
          case
          when opts[:metrics].blank?
            glob = "*/*"
          when opts[:metrics] =~ /,/
            puts "\n" * 4
            glob = "{" + opts[:metrics].split(/\s*,\s*/).map { |m|
              m =~ /\// ? m : ["*/#{m}", "#{m}/*"]
            }.join(',').gsub(/,$/, '') + "}"
          when opts[:metrics] !~ /\//
            glob = "#{opts[:metrics]}/#{opts[:metrics]}"
          else
            glob = opts[:metrics]
          end

          host_glob = (opts[:host] || "*")

          Dir.glob("#{rrddir}/#{host_glob}/#{glob}.rrd").map {|e| e.split('/')[-2..-1].join('/').gsub(/\.rrd$/, '')}.sort.uniq
        end

        def json_encoder(opts = {})
          CollectdJSON.new(opts)
        end

      end # class << self

    end # RRDs
  end # Collectd
end # Visage
