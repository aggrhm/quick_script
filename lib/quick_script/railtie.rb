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
          Sprockets.register_mime_type 'text/jhtml', extensions: ['.jhtml']
          Sprockets.register_mime_type 'text/qsc', extensions: ['.qsc']
          Sprockets.register_mime_type 'text/qsj', extensions: ['.qsj']
          Sprockets.register_transformer 'text/jhaml', 'application/javascript', QuickScript::JstHamlTransformer.new
          Sprockets.register_transformer 'text/jhtml', 'application/javascript', QuickScript::JstHamlTransformer.new(html: true)
          Sprockets.register_transformer 'text/qsc', 'application/javascript', QuickScript::QscTransformer.new({lang: 'coffee'})
          Sprockets.register_transformer 'text/qsj', 'application/javascript', QuickScript::QscTransformer.new({lang: 'es6'})
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

    def mount_api_endpoints(mount_path)
      mount = QuickScript::ApiEndpoints.mounts[mount_path]
      mount.endpoints.each do |key, val|
        method, path = key
        match path, to: "#{mount.controller}#handle_api_request", via: method, defaults: {qs_api_mount_path: mount.path}
      end
    end
  end

end
