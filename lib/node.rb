# node can reference multiple nodes/phrases...
# use extend for that to compose behaviors on each node?
# or not - each node has only one style....

require 'slim'
require 'json'

require 'color-generator'
$colors = ColorGenerator.new\
  saturation: 1, lightness: 0.3
def acolor
  ('#%s' % $colors.create_hex).upcase.inspect
end

$bgcolors = ColorGenerator.new\
  saturation: 1, lightness: 0.7
def bgcolor
  ('#%s' % $bgcolors.create_hex).upcase.inspect
end

require 'unindent'

require 'erb'
require 'securerandom'
require 'yaml'

module Inspector
  refine String do
    def i; inspect end
  end
end
using Inspector


class Node
  attr_reader :name, :code

  def initialize name, code
    @name, @code = name, code
  end

  def self.build *a
    @@types.find { |x| x.is? *a }.new *a
  end

  @@types = []

  def render
    self.class::TEMPLATE.result binding
  end

  def self.nexts
    "
      <% for next_one in next_ones %>
        <%= name.i %> -> <%= next_one.i %>
      <% end %>
    ".strip.unindent
  end

  class DialogNode < Node
    @@types << self

    def self.is? name, code
      code =~ /say_reply/ && code =~ /_option/
    end

    TEMPLATE = ERB.new <<-erb.unindent, nil, '%'
      <%= name.i %> [style=filled color=<%= bgcolor %> peripheries=1 label=<%= question.i %>]
      % for option, msg in options
      <%= name.i %> -> <%= option.i %> [label=<%= msg.i %>,color=<%= x = acolor %> fontcolor=<%= x %>]
      % end
      #{nexts}
    erb

    def question
      id = Integer code[/reply[(]\d+, (\d+)/, 1]
      $msg[id]
    end

    def options
      code.scan(/option[(].*?,.*?, (\d+), (.*?),/).map {|x|
        id = Integer x.first
        node = x[1]
        [ node, $msg[id] ]
      }
    end
  end

  class FloatNode < Node
    @@types << self

    def self.is? name, code
      code =~ /say_message/
    end

    TEMPLATE = ERB.new <<-erb.unindent
      <%= name.i %> [shape=box style=filled color=<%= bgcolor %>]
      <%= name.i %> [ label= <%= say.i %> ]
      //<%= say.i %>[label=<%= say.i %>]
      #{nexts}
    erb
    #<%= say.i %>[shape=ellipse]

    #def uuid
    #  @uuid ||= SecureRandom.hex
    #end

    def say
      id = code[/say_message[(]\d+, (\d+)/, 1]
      id = Integer id
      $msg[id]
    end
  end

  class MidNode < Node
    @@types << self

    def self.is? name, code
      code =~ /call .*;/
    end

    TEMPLATE = ERB.new <<-erb.unindent
      <%= name.i %> //[label=<%= (name+"\\n"+code).i %>]
      #{nexts}
    erb
  end


  class LeafNode < Node
    @@types << self

    def self.is?(*)  true  end

    TEMPLATE = ERB.new <<-erb.unindent
      <%= name.i %>[shape=cds]
      #{nexts}
    erb
    
  end

  def next all
    name = code.scan(/call (.*?);/).last.first
    all.find { |x| x.name == name }
  end

  def next_ones
    #code[/call (.*?);/, 1]
    code.scan(/call (.*?);/).map &:first
  end
end


SLIM = <<slim
doctype 5
html
  head
    title dialog struct
    meta charset='utf-8'

  body

    == self

  script src='./jquery.js'
  script src='./underscore.js'

  coffee:
    $('svg').attr('unselectable','on').css(
      '-moz-user-select': '-moz-none'
      '-moz-user-select': 'none'
      '-o-user-select': 'none'
      '-khtml-user-select': 'none'
      '-webkit-user-select': 'none'
      '-ms-user-select': 'none'
      'user-select': 'none'
    ).bind 'selectstart', -> return false

    $('<div/>', id: 'thecode').
      appendTo 'body'

    $('#thecode').css
      'pointer-events': 'none'
      background: 'white'
      padding: '1em'
      outline: 'solid gray 1px'
      'white-space': 'pre'
      position: 'fixed'
      left: 0
      top: 0

    
    showCode = (code, x, y)->
      #console.log $('#thecode').is(':visible')
      $('#thecode').show()
      #console.log $('#thecode').is(':visible')
      $('#thecode').text code
      positionCode x, y
    hideCode = ->
      $('#thecode').hide()

    positionCode = (x, y) ->
      $('#thecode').css left: x, top: y

    # $('#thecode').mousemove (e)->
    #    positionCode e.clientX, e.clientY

    nodes = $('.node')
    _.each nodes, (node) ->
      # $(node).mouseover (e)->
      #  nodeName = $(node).find('title').text()
      #  showCode Codes[nodeName], e.clientX, e.clientY
      
      nodeName = $(node).find('title').text()
      # $(node).find('title').remove()
      $(node).mousemove (e)->
        showCode Codes[nodeName], e.clientX, e.clientY
      $(node).mouseleave ->
        hideCode()
    $('svg title').remove() # no tooltips

    downAt = null
    $('svg').mousedown (e)->
      x = e.pageX
      y = e.pageY
      downAt =
        x: x
        y: y

    $('svg').mousemove (e)->
      return unless downAt
      x = e.pageX
      y = e.pageY
      delta = 
        x: x - downAt.x
        y: y - downAt.y
      window.scrollBy -delta.x, -delta.y
      false

    $('svg').mouseup (e)->
      downAt = null
    $('svg').mouseleave (e)->
      downAt = null

    # $('svg .node').css cursor: 'pointer'
    #svg = $('svg')[0]
    ##svg.setAttribute 'style', 'cursor: pointer'
slim


if __FILE__ == $0
  nodes_file = 'gizmo_nodes.yml'

  $msg = YAML.load_file 'gizmo.yml'

  hash = YAML.load_file nodes_file

  nodes = hash.map { |name, code|
    Node.build name, code
  }

  result = nodes.each_with_object('') { |node, result|
    result << node.render
  }
  result = "digraph dialogue {\n%s}" % result
  puts result

  File.write 'gizmo.dot', result
  system 'dot gizmo.dot -Tpng -o gizmo.png'
  system 'dot gizmo.dot -Tsvg -o gizmo.svg'

  #data = { 'Gizmo13_1' => '--code--' }
  data = nodes.map { |x| { x.name => "__"+x.name+"__\n\n"+x.code.unindent }}.
    reduce(:merge)

  svg = File.read 'gizmo.svg'
  svg = svg[/<svg.*/m]
  svg += "<script>window.Codes = #{JSON.dump data}</script>"

  html = Slim::Template.new { SLIM }.render svg

  File.write 'gizmo.html', html
  # -Goverlap=scale -Gsplines=true -Estyle=bold'
  #system 'dot gizmo.dot -Tpng -o gizmo.png'
  #p nodes.first 
  #p nodes.first.next nodes
end
