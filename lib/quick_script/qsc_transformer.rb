require 'haml'
require 'sass'
require 'coffee_script'

module QuickScript

  class QscTransformer

    def initialize(opts={})

    end

    def parse_tag_attr(tag, attr)
      return nil if !tag.include?("#{attr}=")
      return tag.split("#{attr}=\"").last.split("\"").first
    end

    def parse_tag(str)
      lines = str.lines
      tl = lines[0]
      tname = if tl.start_with?("<template")
               "template"
             elsif tl.start_with?("<style")
               "style"
             end
      lang = tl.split("lang=\"").last.split("\"").first
      name = nil
      if tname == "template"
        name = parse_tag_attr(tl, "name")
      end
      content = lines[1..-2].join("\n")
      if lang == "haml"
        pc = Haml::Engine.new(content).render
      elsif lang == "sass" || lang == "scss"
        pc = Sass::Engine.new(content, syntax: lang).render
      elsif lang == "html" || lang == "css"
        pc = content
      else
        raise "This template language is unknown."
      end
      return {tag_name: name, lang: lang, name: name, processed_content: pc}
    end

    def call(input)
      # parse template
      text = input[:data]
      text = text.gsub(/<template\s.*lang=.*>.*<\/template>/m) do |match|
        td = parse_tag(match)
        ret = "QS.utils.registerTemplate(\"#{td[:name]}\", #{td[:processed_content].inspect})\n"
      end
      text = text.gsub(/<style\s.*lang=.*>.*<\/style>/m) do |match|
        td = parse_tag(match)
        ret = "QS.utils.registerStyle(#{td[:processed_content].inspect})\n"
      end
      # parse coffeescript
      #puts text
      text = CoffeeScript.compile(text)
      return {data: text}
    end

  end

end
