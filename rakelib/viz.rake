require 'yaml'
require 'ostruct'

### colors
require 'color-generator'
$fg = ColorGenerator.new\
  saturation: 1, lightness: 0.3
def fg
  ('#%s' % $fg.create_hex).upcase.inspect
end    
$bg = ColorGenerator.new\
  saturation: 1, lightness: 0.7
def bg
  ('#%s' % $bg.create_hex).upcase.inspect
end
### colors



mkpath 'viz' unless Dir.exist? 'viz'

task :viz do
  dialogs = YAML.load File.read nodes_file
  #dialogs = dialogs.take 5

  dialogs.each { |dialog, nodes|
    dot = "digraph #{dialog} {\n"
    nodes.each { |node|
      node = OpenStruct.new node
      name = node.name

      dot << "  #{+name} [style=filled \
      fillcolor=\"#FFFFFF\" \
      color=\"#000000\"]\n"

      (node.calls || []).each { |other|
        dot << "  #{+name} -> #{+other} [style=dotted color=\"#555555\"]\n"
      }

      used = []
      used << node.replies if node.replies
      used << node.used if node.used
      used << node.messages if node.messages
      if used
        label = used.join "\n---\n"
        dot << "  #{+name} [label=#{+label}]\n"
      #else
      #  label = node.name
      end

      (node.options || []).each { |hash|
        raise unless hash.size == 1
        other, text = hash.first.to_a
        dot << "  #{+name} -> #{+other} [label=#{+text} color=#{x = fg} fontcolor=#{x}]\n"
      }

      # styling?
      #if (node.replies || []).any?
      #  dot << "  #{+name} [style=filled color=#{bg}]\n"
      #end
    }
    dot << '}'
    File.write "viz/#{dialog}.dot", dot
  }

  dialogs.each { |dialog, _|
    system "dot viz/#{dialog}.dot -Tpng \
              -o viz/#{dialog}.png"
    system "dot viz/#{dialog}.dot -Tsvg \
              -o viz/#{dialog}.svg"
  }
end


class String
  def +@
    chars.each_slice(20).map(&:join).join(?\n).inspect
    #inspect
  end
end
