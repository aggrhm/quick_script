#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'haml'

class PageBuilder

  def build(path, to)
    html = self.render(path)
    File.open(to, 'w') {|to_f| to_f.write(html)}
  end

  def render(path)
    path = "#{path}.html.haml" unless path.end_with?(".html.haml")
    html = Haml::Engine.new(File.read(path)).render(self)
  end

  def link(text, cls)
    "<a class='#{cls}' href='##{text}'>#{text}</a>"
  end

  def ul_links(section_name, anchors)
    anchors.collect { |anchor|
      "<li><a href='##{section_name}-#{anchor}'>#{anchor}</a></li>"
    }.join("\n")
  end

  def header(section_name)
    "<h2 id='#{section_name}'>#{section_name}</h2>"
  end

end

builder = PageBuilder.new
builder.build('./index.html.haml', './index.html')
