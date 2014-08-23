require 'parslet'
require 'unindent'
require 'ostruct'

class Nodes < Parslet::Parser

  rule :step do
    match('\s') >> match('[^\n]').repeat(1) >> newline
    #match('[^;]').repeat(1) >> str(';') >> newline
  end
  rule :steps do step.repeat 0 end

  #rule :line do
  #  match('[^\n]').repeat(1) >> newline
  #  #>> match('[^\n]').repeat(1) >> newline
  #  #match('[^;]').repeat(1) >> str(';') >> newline
  #end
  #rule :lines do line.repeat 1 end
  #rule :steps do lines end

  rule :name do match('\w').repeat 1 end

  rule :procedure do
    str('procedure ') >> name.as(:name) >> newline >> \
      str('begin') >> newline >> steps.as(:raw) >> \
      str('end') >> newline
  end

  rule :procedures do
    (procedure | newline).repeat 1
  end
  root :procedures


  def self.parse text
    new.parse text
  rescue Parslet::ParseFailed => failure
    puts failure.cause.ascii_tree
  end

  def self.to_h text
    new.to_h text
  rescue Parslet::ParseFailed => failure
    puts failure.cause.ascii_tree
  end

  def to_h text
    array = parse text
    array.each_with_object({}) { |node, hash|
      name = String node[:name]
      body = String node[:raw]
      #body = body.lines.map(&:strip).join ?\n #strip!
      body.gsub! "\t", '  '
      body.unindent!

      raise if hash[name]
      hash[name] = body
    }
  end

  # simple atoms
  rule :newline do  str "\n" end
end

if __FILE__ == $0
#  p Nodes.parse <<text
#procedure Gizmo01
#begin
#  gsay_reply(44, 101);
#  giq_option(5, 44, 102, Gizmo01_1, 49);
#  giq_option(7, 44, 103, Gizmo04, 50);
#  giq_option(4, 44, 104, Gizmo04, 50);
#  giq_option(-3, 44, 105, Gizmo01b, 51);
#end
#
#text
#  exit 0



  text = File.read 'extracts'
  hash = Nodes.to_h text

  require 'yaml'
  File.write 'gizmo_nodes.yml', YAML.dump(hash)
  #p Nodes.parse text
end
__END__
  rule :newline do  str "\n" end
  rule :number do  match('[0-9]').repeat 1 end
  rule :bracket_opened do  str '{' end
  rule :bracket_closed do  str '}' end


  rule :body do
    message = ( match('[^}]').repeat 1 ).as :message
    in_brackets message
  end

  rule :sound do
    in_brackets match('[A-Za-z_0-9]').repeat 0
  end

  rule :id do
    in_brackets number.as(:id)
  end

  rule :comment do
    str('#') >> match('[^\n]').repeat >> newline
  end

  rule :entry do
    id >> sound >> body >> newline
  end

  rule :list do
    (entry | comment | newline ).repeat
  end

  root :list

  def self.parse text
    new.parse text
  rescue Parslet::ParseFailed => failure
    puts failure.cause.ascii_tree
  end

  def self.to_h text
    new.to_h text
  rescue Parslet::ParseFailed => failure
    puts failure.cause.ascii_tree
  end

  def to_h text
    array = parse text
    array.each_with_object({}) { |entry, hash|
      entry = OpenStruct.new entry
      id = Integer entry.id
      message = String entry.message

      raise "ids collision #{id}" if hash[id]
      hash[id] = message
    }
  end

  private
  def in_brackets thing
    bracket_opened >> thing >> bracket_closed
  end
end


if __FILE__ == $0

  x = MSG.to_h "{1}{}{blah\nblah}\n{2}{x}{y}\n"
  raise x.inspect unless\
    x == { 1 => "blah\nblah", 2 => ?y }

  hash = MSG.to_h File.read 'gizmo.msg'
  #p hash
  #puts '---'
  #p hash[1106]

  require 'yaml'
  File.write 'gizmo.yml', YAML.dump(hash)
end
