if defined?(Rails::Railtie)

  module QuickScript
    class Railtie < Rails::Railtie

      config.quick_script = QuickScript.config

      rake_tasks do
        #load "tasks/tiny_mce.rake"
      end

      initializer :quick_script, after: 'sprockets.environment' do |app|
				QuickScript.initialize

        if Sprockets.respond_to?(:register_transformer)
          Sprockets.register_mime_type 'text/jhaml', extensions: ['.jhaml']
          Sprockets.register_transformer 'text/jhaml', 'application/javascript', QuickScript::JstHamlTransformer
        else
          Sprockets.register_mime_type 'text/html', '.html'
          Sprockets.register_engine '.jhaml', QuickScript::JstHamlProcessor
        end
      end

    end
  end

  class ActionDispatch::Routing::Mapper
    def api_resources(res, &block)
      rp = res.to_s
      rs = rp.singularize
      #puts "Adding route for #{rp}"
      match "#{rp}" => "#{rp}#index", :via => :get
      match "#{rs}" => "#{rp}#save", :via => :post
      match "#{rs}" => "#{rp}#delete", :via => :delete
      block.call if block
    end
  end

end
