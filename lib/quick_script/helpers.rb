module QuickScript
	module Helpers
		def jsify model
			raw (model ? model.to_api.to_json : 'null')
		end

		def jqtpl(name, &block)
			raw "<script id='#{name}' type='text/html'>#{capture(&block)}</script>"
		end

		def include_quick_script_init(app_model)
			javascript_tag do
				"CURRENT_USER = null;
				appViewModel = null;
				overlay = null;

				$(function() {
					CURRENT_USER = (<%= jsify current_user %>);
					appViewModel = new #{app_model}();
					overlay = new Overlay();
					initApp();
					console.log('Initialized...');
				});"
			end
		end
	end
end
