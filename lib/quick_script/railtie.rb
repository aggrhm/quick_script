if defined?(Rails::Railtie)
  module QuickScript
    class Railtie < Rails::Railtie

      config.quick_script = QuickScript.config

      rake_tasks do
        #load "tasks/tiny_mce.rake"
      end

      initializer :quick_script, after: 'sprockets.environment' do |app|
				QuickScript.initialize

        Sprockets.register_mime_type 'text/html', '.html'
        Sprockets.register_engine '.jhaml', QuickScript::JstHamlProcessor
      end

    end
  end
end
