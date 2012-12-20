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
					window.App = QuickScript.initialize({view: '#{app_model}', user: #{current_user ? jsify(current_user.to_api(:me)) : 'null'}});
				});".html_safe
			end
		end
	end
end
