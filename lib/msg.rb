require 'parslet'
require 'ostruct'

class MSG < Parslet::Parser

  rule :newline do str(' ').repeat(0) >> str("\n") end
  rule :number do  match('[0-9]').repeat 1 end
  rule :bracket_opened do  str '{' end
  rule :bracket_closed do  str '}' end
  rule(:eof) { any.absent? }


  rule :body do
    letter =  match('[^}]') | str("\n")
    message = letter.repeat(0).as :message
    in_brackets message
  end

  rule :sound do
    in_brackets match('[A-Za-z_0-9\)]').repeat 0
  end

  rule :id do
    in_brackets number.as(:id)
  end

  rule :comment do
    hashy = str('#') >> match('[^\n]').repeat >> newline
    sishy = str('//') >> match('[^\n]').repeat >> newline
    hr = str('=').repeat(1) >> newline
    hashy | sishy | hr
  end

  rule :entry do
    str(' ').maybe >> id >> sound >> body >> newline
  end
  rule :odd_last_entry do
    id >> sound >> body >> eof
  end

  rule :list do
    (entry | odd_last_entry | comment | newline ).repeat
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

      warn "ids collision #{id}" if hash[id]
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

  str =
    "{257}{}{If you don't have authorization you can not get
 replacement parts.}"
  x = MSG.to_h str
  #raise x.inspect unless\
  #  x == { 21 => "blah\nblah", 2 => ?y }


  p :OK

  #hash = MSG.to_h File.read 'gizmo.msg'
  ##p hash
  ##puts '---'
  ##p hash[1106]

  #require 'yaml'
  #File.write 'gizmo.yml', YAML.dump(hash)
end
