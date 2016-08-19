require 'tilt'
require 'haml'

module QuickScript

  class JstHamlProcessor < Tilt::Template
    self.default_mime_type = "application/javascript"

    def prepare
      @namespace = "this.JST"
    end

    def evaluate(scope, locals, &block)
      lp = scope.logical_path
      res = QuickScript.config.jst_name_processor.call(lp)
      if res.is_a?(String)
        name = res
        p_alias = nil
      else
        name = res[:name]
        p_alias = res[:alias]
      end

      # convert haml to html
      content = Haml::Engine.new(data).render

      alias_s = p_alias ? "#{@namespace}['#{p_alias}'] = #{@namespace}['#{name}'];" : ""

      <<-JST
(function() { #{@namespace} || (#{@namespace} = {}); #{@namespace}['#{name}'] = function() { return #{content.inspect}; }; #{alias_s}
}).call(this);
      JST

    end

  end

  class JstHamlTransformer

    def self.call(input)
      @namespace = "this.JST"
      lp = input[:name]
      res = QuickScript.config.jst_name_processor.call(lp)
      if res.is_a?(String)
        name = res
        p_alias = nil
      else
        name = res[:name]
        p_alias = res[:alias]
      end

      # convert haml to html
      content = Haml::Engine.new(input[:data]).render

      alias_s = p_alias ? "#{@namespace}['#{p_alias}'] = #{@namespace}['#{name}'];" : ""

      tpl = <<-JST
(function() { #{@namespace} || (#{@namespace} = {}); #{@namespace}['#{name}'] = function() { return #{content.inspect}; }; #{alias_s}
}).call(this);
      JST
      return {data: tpl}
    end

  end

end
