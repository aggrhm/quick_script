module QuickScript
	module Helpers
		def jsify model
			raw (model ? model.to_api.to_json : 'null')
		end

		def jqtpl(name, &block)
			raw "<script id='#{name}' type='text/html'>#{capture(&block)}</script>"
		end
	end
end
