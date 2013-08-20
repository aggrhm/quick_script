module QuickScript
	module Helpers
		def jsify(model)
			raw (model ? model.to_json : 'null')
		end

		def jqtpl(name, &block)
			raw "<script id='#{name}' type='text/html'>#{capture(&block)}</script>"
		end

		def include_view_box
			#raw "<div data-bind=\"template: {name : getViewBoxTemplate}, attr : {class : 'view-box view-box-' + transition.type}\"></div>"
			raw "<div data-bind=\"template : 'viewbox'\"></div>"
		end

		def include_quick_script_init(app_model='AppView')
			javascript_tag do
				"$(function() {
					window.App = QuickScript.initialize({
            view: '#{app_model}', 
            user: #{(defined?(current_user) && current_user) ? jsify(current_user.to_api(:me)) : 'null'}});
				});".html_safe
			end
		end

    def include_quick_script_views(path)
      dir = File.join(Rails.root, path)
      str = ""
      Dir.glob("#{dir}/**/*") do |file_path|
        unless File.directory? file_path
          rel_path = file_path.gsub(dir, "").gsub(/^\//, "")
          name = rel_path.gsub(/\.htm.*/, "").gsub("/", "-")
          contents = File.read(file_path)

          file_str = if file_path.end_with? ".haml"
            Haml::Engine.new(contents).render
          else
            contents
          end
          str += "<script type='text/html' id='view-#{name}'>\n#{file_str}\n</script>\n"
        end
      end
      raw str
    end

	end
end
