require 'bundler'
Bundler::GemHelper.install_tasks

require "logger"
require "fileutils"
require "pathname"
require "sprockets"
require "sprockets-sass"
require "compass"
require "uglifier"

ROOT        = Pathname(File.dirname(__FILE__))
LOGGER      = Logger.new(STDOUT)
BUNDLES     = %w( quick_script.css quick_script.js )
BUILD_DIR   = ROOT.join("build")
SOURCE_DIR  = ROOT.join("vendor/assets")

desc 'Compile assets.'
task :compile do
  sprockets = Sprockets::Environment.new(ROOT) do |env|
    env.logger = LOGGER
  end

  sprockets.append_path(SOURCE_DIR.join('javascripts').to_s)
  sprockets.append_path(SOURCE_DIR.join('stylesheets').to_s)

	# javascript
	full_js = sprockets.find_asset('quick_script.js').to_s
	#compressed_js = Uglifier.compile(full_js)
	File.open(BUILD_DIR.join('javascripts', 'quick_script.js'), 'w') do |f|
		f.write(full_js)
	end
	
	# stylesheets
	full_css = sprockets.find_asset('quick_script.css')
	full_css.write_to(BUILD_DIR.join('stylesheets', 'quick_script.css'))

  # images
  images_src = SOURCE_DIR.join('images')
  images_dst = BUILD_DIR.join('images')
  FileUtils.cp_r(Dir["#{images_src}/*"], images_dst)
end


