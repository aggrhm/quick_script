require 'quick_script/base'
require 'quick_script/helpers'
require 'quick_script/interaction'
require 'quick_script/engine'

module QuickScript
  # Your code goes here...
  def self.initialize
    return if @intialized
    raise "ActionController is not available yet." unless defined?(ActionController)
    ActionController::Base.send(:include, QuickScript::Base)
    ActionController::Base.send(:helper, QuickScript::Helpers)
    #QuickScript.install_or_update(:js)
    #QuickScript.install_or_update(:css)
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
	
end

# Finally, lets include the TinyMCE base and helpers where
# they need to go (support for Rails 2 and Rails 3)
if defined?(Rails::Railtie)
  require 'quick_script/railtie'
else
  QuickScript.initialize
end

