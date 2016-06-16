require 'quick_script/base'
require 'quick_script/helpers'
require 'quick_script/interaction'
require 'quick_script/model'
require 'quick_script/model_endpoints'
require 'quick_script/engine'
require 'quick_script/jst_haml_processor'
require 'quick_script/elastic_search_query'

module QuickScript

  DEFAULT_ROUTING_RULE = lambda{|req| !req.env['REQUEST_URI'].include?('/api/') && !req.env['REQUEST_URI'].include?('/assets/')}

  class Configuration

    def initialize
      self.jst_path_separator = "-"
      self.jst_name_prefix = "view-"
      self.jst_name_processor = lambda {|logical_path|
        QuickScript.jst_path_to_name(logical_path)
      }
    end

    attr_accessor :jst_path_separator
    attr_accessor :jst_name_prefix
    attr_accessor :jst_name_processor

  end

  module Errors
    class APIError < StandardError
        def initialize(opts={})
          super
          if opts.is_a?(String)
            @message = opts
            @resp = {}
          else
            opts ||= {}
            @resp = opts
            @message = opts[:message]
          end
        end
        def message
          @message ||= "An error occurred at the server."
        end
        def code
          1000
        end
        def type
          "APIError"
        end
        def resp
          @resp[:success] = false
          @resp[:meta] = self.code
          @resp[:data] ||= nil
          @resp[:error] = self.message
          @resp[:error_type] = self.type
          return @resp
        end
    end
    class ResourceNotFoundError < APIError
      def message
        @message ||= "The resource you are trying to load or update could not be found."
      end
      def code
        1003
      end
      def type
        "ResourceNotFoundError"
      end
    end
    class InvalidParamError < APIError
      def message
        @message ||= "A parameter you specified was invalid."
      end
      def code
        1004
      end
      def type
        "InvalidParamError"
      end
    end
  end
  include Errors
  

  def self.initialize
    return if @intialized
    raise "ActionController is not available yet." unless defined?(ActionController)
    ActionController::Base.send(:include, QuickScript::Base)
    ActionController::Base.send(:helper, QuickScript::Helpers)
    @intialized = true
  end

  def self.install_or_update(asset)
    case asset
    when :js
      dest_sub = "javascripts"
    when :css
      dest_sub = "stylesheets"
    end
    asset_s = asset.to_s
    require 'fileutils'
    orig = File.join(File.dirname(__FILE__), 'quick_script', 'assets', asset_s)
    dest = File.join(Rails.root.to_s, 'vendor', 'assets', dest_sub, 'quick_script')
    main_file = File.join(dest, "quick_script.#{asset_s}")

    unless File.exists?(main_file) && FileUtils.identical?(File.join(orig, "quick_script.#{asset_s}"), main_file)
      if File.exists?(main_file)
        # upgrade
        begin
          puts "Removing directory #{dest}..."
          FileUtils.rm_rf dest
          puts "Creating directory #{dest}..."
          FileUtils.mkdir_p dest
          puts "Copying QuickScript #{dest_sub} to #{dest}..."
          FileUtils.cp_r "#{orig}/.", dest
          puts "Successfully updated QuickScript #{dest_sub}."
        rescue
          puts 'ERROR: Problem updating QuickScript. Please manually copy '
          puts orig
          puts 'to'
          puts dest
        end
      else
        # install
        begin
          puts "Creating directory #{dest}..."
          FileUtils.mkdir_p dest
          puts "Copying QuickScript #{dest_sub} to #{dest}..."
          FileUtils.cp_r "#{orig}/.", dest
          puts "Successfully installed QuickScript #{dest_sub}."
        rescue
          puts "ERROR: Problem installing QuickScript. Please manually copy "
          puts orig
          puts "to"
          puts dest
        end
      end
    end

  end

  def self.config
    @config ||= QuickScript::Configuration.new
  end

  def self.parse_bool(val)
    if val == true || val == "true" || val == 1
      return true
    else
      return false
    end
  end

  def self.parse_opts(opts)
    return nil if opts.nil?
    new_opts = opts
    if opts.is_a?(String) && !opts.blank?
      new_opts = JSON.parse(opts)
    end
    if new_opts.is_a?(Hash)
      return new_opts.with_indifferent_access
    else
      return new_opts
    end
  end

  def self.parse_template(name, vars, opts={})
    opts[:path] ||= "mail"
    fp = File.join Rails.root, 'app', 'views', opts[:path], name
    fp += ".html.erb" unless fp.ends_with?(".html.erb")
    tpl = File.read(fp)
    html = QuickScript::DynamicErb.new(vars).render(tpl)
    return html
  end

  def self.prepare_api_param(val)
    if val.respond_to?(:to_api)
      val.to_api
    elsif val.is_a?(Array)
      val.collect{|d| QuickScript.prepare_api_param(d) }
    else
      val
    end
  end

  def self.convert_to_js_string(string)
    string.gsub(/[\n\t]/, "").gsub(/\"/, "\\\"").strip
  end

  def self.jst_path_to_name(path, opts={})
    prefix = opts[:prefix] || QuickScript.config.jst_name_prefix
    sep = opts[:separator] || QuickScript.config.jst_path_separator
    "#{prefix}#{path.gsub("/", sep)}"
  end

  class DynamicErb

    def initialize(vars)
      vars.each {|k,v|
        self.instance_variable_set("@#{k}".to_sym, v)
      }
    end

    def render(template)
      ERB.new(template).result(binding)
    end

  end
  
end

# Finally, lets include the TinyMCE base and helpers where
# they need to go (support for Rails 2 and Rails 3)
if defined?(Rails::Railtie)
  require 'quick_script/railtie'
else
  QuickScript.initialize
end

