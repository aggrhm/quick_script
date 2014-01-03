#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'haml'
require 'haml-coderay'

class PageBuilder
  include Haml::Helpers

  def build(path, to)
    html = self.render(path)
    File.open(to, 'w') {|to_f| to_f.write(html)}
  end

  def render(path)
    puts "Rendering #{path}."
    path = "#{path}.html.haml" unless path.end_with?(".html.haml")
    html = Haml::Engine.new(File.read(path)).render(self)
  end

  def link(text, cls, ref=nil)
    ref = text if ref.nil?
    "<a class='#{cls}' href='##{ref}'>#{text}</a>"
  end

  def ul_links(section_name, anchors)
    anchors.collect { |anchor|
      "<li><a href='##{section_name}-#{anchor}'>#{anchor}</a></li>"
    }.join("\n")
  end

  def header(section_name)
    "<h2 id='#{section_name.gsub(/\s/, '')}'>#{section_name}</h2>"
  end

  def subheader(name, code="")
    ret = "<b class='header'>#{name}</b>"
    ret << "<code class='header'>#{code}</code><br/>" unless code.empty?
    ret
  end

end

module Haml::Filters::Code
  include Haml::Filters::Base
  def render(text)
    text = Haml::Helpers.html_escape(text) 
    text = Haml::Helpers.preserve(text) 
    text = "<pre>#{text}</pre>"
    text.gsub!(/\t/, '    ')
    text
  end
end

Haml::Filters::CodeRay.encoder_options = {:tab_width => 4}

builder = PageBuilder.new
builder.build('./index.html.haml', './index.html')
