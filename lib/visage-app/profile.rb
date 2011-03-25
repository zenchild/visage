#!/usr/bin/env ruby

root = Pathname.new(File.dirname(__FILE__)).parent.parent
$: << root.join('lib')
require 'lib/visage-app/graph'
require 'lib/visage-app/patches'
require 'digest/md5'

module Visage
  class Profile
    attr_reader :options, :selected_hosts, :hosts, :selected_metrics, :metrics,
                :name, :errors, :backend

    def self.load
      Visage::Config::File.load('profiles.yaml', :create => true, :ignore_bundled => true) || {}
    end

    def self.get(id)
      url = id.downcase.gsub(/[^\w]+/, "+")
      profiles = self.load
      profiles[url] ? self.new(profiles[url]) : nil
    end

    def self.all(opts={})
      sort = opts[:sort]
      profiles = self.load
      profiles = sort == "name" ? profiles.sort.map {|i| i.last } : profiles.values
      profiles.map { |prof| self.new(prof) }
    end

    def initialize(opts={})
      @options = opts
      @options[:url] = @options[:profile_name] ? @options[:profile_name].downcase.gsub(/[^\w]+/, "+") : nil
      @errors = {}
      @selected_hosts   = []
      @selected_metrics = []

      if(@options[:backend])
        @backend = @options[:backend].to_sym
        backend = Visage::Backends::BACKENDS[@backend]
        @hosts = backend.send(:hosts)
        @metrics  = []

        unless @options[:hosts].blank?
          @selected_hosts = backend.send(:hosts,{:hosts => @options[:hosts]})
          @hosts -= @selected_hosts

          @metrics = backend.send(:metrics, @options)
          unless @options[:metrics].blank?
            @selected_metrics = backend.send(:metrics, @options)
            @metrics -= @selected_metrics
          end
        end
      else
        @hosts    = []
        @metrics  = []
        @backend  = nil
      end
    end

    # Hashed based access to @options.
    def method_missing(method)
      @options[method]
    end

    def save
      if valid?
        # Construct record.
        attrs = {
          :backend      => @options[:backend],
          :hosts        => @options[:hosts],
          :metrics      => @options[:metrics],
          :profile_name => @options[:profile_name],
          :url          => @options[:profile_name].downcase.gsub(/[^\w]+/, "+")
        }

        # Save it.
        profiles = self.class.load
        profiles[attrs[:url]] = attrs

        Visage::Config::File.open('profiles.yaml') do |file|
          file << profiles.to_yaml
        end

        true
      else
        false
      end
    end

    def valid?
      valid_profile_name?
    end

    def graphs
      graphs = []
      
      backend = Visage::Backends::BACKENDS[@backend]
      hosts = backend.send(:hosts,{:hosts => @options[:hosts]})
      metrics = @options[:metrics]
      hosts.each do |host|
        attrs = {}
        globs = backend.send(:metrics, {:host => host, :metrics => metrics})
        globs.each do |n|
          parts    = n.split('/')
          plugin   = parts[0]
          instance = parts[1]
          attrs[plugin] ||= []
          attrs[plugin] << instance
        end

        attrs.each_pair do |plugin, instances|
          graphs << Visage::Graph.new(:host => host,
                                      :plugin => plugin,
                                      :instances => instances)
        end
      end

      graphs
    end

    def private_id
      Digest::MD5.hexdigest("#{@options[:url]}\n")
    end

    private

    def valid_profile_name?
      if @options[:profile_name].blank?
        @errors[:profile_name] = "Profile name must not be blank."
        false
      else
        true
      end
    end

  end
end
