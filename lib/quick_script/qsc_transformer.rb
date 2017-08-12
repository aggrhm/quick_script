module QuickScript

  class QscTransformer

    def initialize(opts={})
      @lang = opts[:lang] || 'coffee'
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
        require 'haml'
        pc = Haml::Engine.new(content).render
      elsif lang == "sass" || lang == "scss"
        require 'sass'
        #puts QuickScript.config.sass_import_paths
        pc = Sass::Engine.new(content, syntax: lang,
                              load_paths: QuickScript.config.sass_import_paths).render
      elsif lang == "html" || lang == "css"
        pc = content
      else
        raise "This template language is unknown."
      end
      return {tag_name: tname, lang: lang, name: name, processed_content: pc}
    end

    def formatLine(line)
      if @lang == 'coffee'
        return line
      else
        return "#{line};"
      end
    end

    def call(input)
      if @lang == 'coffee'
        require 'coffee_script'
      else
        require 'babel/transpiler'
      end
      output = ""
      buffer = ""
      ib = false
      # parse template
      text = input[:data]
      text.each_line do |line|
        if line.start_with?("<") && !ib
          buffer = line
          ib = true
        elsif line.start_with?("</") && ib
          buffer << line
          # process buffer
          td = parse_tag(buffer)
          #puts td.inspect
          if td[:tag_name] == "template"
            pb = "QS.utils.registerTemplate(\"#{td[:name]}\", #{td[:processed_content].inspect})\n"
          elsif td[:tag_name] == "style"
            pb = "QS.utils.registerStyle(#{td[:processed_content].inspect})\n"
          else
            raise "This tag is unknown: #{td.inspect}"
          end
          output << formatLine(pb)
          ib = false
        else
          if ib
            buffer << line
          else
            output << line
          end
        end
      end
      # parse coffeescript
      #puts output
      if @lang == 'coffee'
        output = CoffeeScript.compile(output)
      else
        output = Babel::Transpiler.transform(output)["code"]
      end
      return {data: output}
    rescue => ex
      puts "QSC Transformer Error: Error processing file #{input[:name]}"
      raise ex
    end

  end

end
