if defined?(Rails::Railtie)
  module QuickScript
    class Railtie < Rails::Railtie
      rake_tasks do
        #load "tasks/tiny_mce.rake"
      end

      initializer :quick_script do
				QuickScript.initialize
      end
    end
  end
end
