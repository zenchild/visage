#!/usr/bin/env ruby

require 'pathname'
@root = Pathname.new(File.dirname(__FILE__)).parent.expand_path
$: << @root.to_s

require 'sinatra/base'
require 'haml'
require 'lib/visage-app/profile'
require 'lib/visage-app/helpers'
require 'lib/visage-app/config'
require 'lib/visage-app/config/file'
require 'lib/visage-app/backends'
require 'yajl/json_gem'

module Visage
  class Application < Sinatra::Base
    @root = Pathname.new(File.dirname(__FILE__)).parent.expand_path
    set :public, @root.join('lib/visage-app/public')
    set :views,  @root.join('lib/visage-app/views')

    helpers Sinatra::LinkToHelper
    helpers Sinatra::PageTitleHelper

    configure do
      Visage::Config.use do |c|
        backends = Visage::Config::File.load('backends.yaml')
        Visage::Backends::LOADERS.each do |be|
          be.call(c, backends)
        end
      end
    end
  end

  class Profiles < Application
    get '/' do
      redirect '/profiles'
    end

    get '/profiles/:url' do
      @profile = Visage::Profile.get(params[:url])
      raise Sinatra::NotFound unless @profile
      @start  = params[:start]
      @finish = params[:finish]
      haml :profile
    end

    get '/profiles' do
      @profiles = Visage::Profile.all(:sort => params[:sort])
      haml :profiles
    end
  end


  class Builder < Application

    get "/builder" do
      @profile = Visage::Profile.new(params)
      @backends = Visage::Backends::BACKENDS.keys
      case params[:submit]
      when /create/
        if @profile.save
          redirect "/profiles/#{@profile.url}"
        else
          haml :builder
        end
      else
        haml :builder
      end
    end

    # infrastructure for embedding
    get '/javascripts/visage.js' do
      javascript = ""
      %w{raphael-min g.raphael g.line mootools-1.2.3-core mootools-1.2.3.1-more graph}.each do |js|
        javascript += File.read(@root.join('lib/visage-app/public/javascripts', "#{js}.js"))
      end
      javascript
    end

  end

  class JSON < Application

    # JSON data backend

    # /data/:host/:plugin/:optional_plugin_instance
    get %r{/data/([^/]+)/([^/]+)/([^/]+)((/[^/]+)*)} do
      backend = params[:captures][0].gsub("\0", "")
      host = params[:captures][1].gsub("\0", "")
      plugin = params[:captures][2].gsub("\0", "")
      plugin_instances = params[:captures][3].gsub("\0", "")

      json_enc = Visage::Backends::BACKENDS[backend.to_sym].json_encoder

      collectd = CollectdJSON.new(:rrddir => Visage::Config.collectd_rrddir)
      json = collectd.json(:host => host,
                           :plugin => plugin,
                           :plugin_instances => plugin_instances,
                           :start => params[:start],
                           :finish => params[:finish])
      # if the request is cross-domain, we need to serve JSONP
      maybe_wrap_with_callback(json)
    end

    get %r{/data/([^/]+)} do
      host = params[:captures][0].gsub("\0", "")
      metrics = Visage::Collectd::RRDs.metrics(:host => host)

      json = { host => metrics }.to_json
      maybe_wrap_with_callback(json)
    end

    get %r{/data(/)*} do
      hosts = []
      Visage::Backends::BACKENDS.each_pair do |be_id,be_class|
        puts "=========> Loading Hosts from #{be_id}"
        hosts += be_class.send(:hosts)
      end
      json = { :hosts => hosts }.to_json
      maybe_wrap_with_callback(json)
    end

    # wraps json with a callback method that JSONP clients can call
    def maybe_wrap_with_callback(json)
      params[:callback] ? params[:callback] + '(' + json + ')' : json
    end

  end
end
