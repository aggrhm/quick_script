require 'quick_script/base'
require 'quick_script/helpers'

module QuickScript
  # Your code goes here...
  def self.initialize
    return if @intialized
    raise "ActionController is not available yet." unless defined?(ActionController)
    ActionController::Base.send(:include, QuickScript::Base)
    ActionController::Base.send(:helper, QuickScript::Helpers)
    QuickScript.install_or_update
    @intialized = true
  end

  def self.install_or_update
    require 'fileutils'
    orig = File.join(File.dirname(__FILE__), 'quick_script', 'assets', 'quick_script')
    dest = File.join(Rails.root.to_s, 'vendor', 'assets', 'javascripts', 'quick_script')
    main_js = File.join(dest, 'quick_script.js')

    unless File.exists?(main_js) && FileUtils.identical?(File.join(orig, 'quick_script.js'), main_js)
      if File.exists?(main_js)
        # upgrade
        begin
          puts "Removing directory #{dest}..."
          FileUtils.rm_rf dest
          puts "Creating directory #{dest}..."
          FileUtils.mkdir_p dest
          puts "Copying QuickScript to #{dest}..."
          FileUtils.cp_r "#{orig}/.", dest
          puts "Successfully updated QuickScript."
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
          puts "Copying QuickScript to #{dest}..."
          FileUtils.cp_r "#{orig}/.", dest
          puts "Successfully installed QuickScript."
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

