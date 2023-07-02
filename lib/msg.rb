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
  rule :final_comment do
    hashy = str('#') >> match('[^\n]').repeat >> eof
    sishy = str('//') >> match('[^\n]').repeat >> eof
    hr = str('=').repeat(1) >> eof
    hashy | sishy | hr
  end

  rule :padded_comment do
    str(' ').repeat(0) >> comment
  end

  rule :inline_comment do
    str(' ').repeat(0) >> str('#') >> match('[^\n]').repeat(0)
  end

  rule :garbage do
    match('[^\n]').repeat
  end

  rule :entry do
    str(' ').maybe >> id >> sound >> body >> garbage.maybe >> newline #(inline_comment.maybe | garbage.maybe) >> newline
  end
  rule :odd_last_entry do
    id >> sound >> body >> garbage.maybe >> eof #(inline_comment.maybe | garbage.maybe) >> eof
  end

  rule :non_entry_final do
    match('[^{]') >> match('[^\n]').repeat >> eof
  end
  rule :non_entry_middle do
    match('[^{]') >> match('[^\n]').repeat >> newline
  end
  rule :non_entry do
    non_entry_middle | non_entry_final # not trying (eof|newline) jik...
  end

  rule :list do
    (entry | odd_last_entry | padded_comment | final_comment | newline | non_entry ).repeat
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
    puts "Parsing failed for:"
    puts text
    p failure
    exit 0
    #puts failure.cause .ascii_tree
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

  str =
    "{257}{}{hey}#a"
  x = MSG.to_h str

  p :OK

  p MSG.to_h "{1}{}{a}"
  p MSG.to_h "{1}{}{a}\n{3}{}{a}"
  p MSG.to_h "{1}{}{a}#\n{3}{}{a}"
  p MSG.to_h "{1}{}{a}# oeu\n"
  p MSG.to_h '{1}{}{a} # '
  p MSG.to_h '{1}{}{a} #:'
  p MSG.to_h '{1}{}{#} # oeu'
  p MSG.to_h "{1}{}{abc}\n5. hello"

  p MSG.to_h "{1}{}{abc}garbage"

  #p MSG.to_h DATA.read.strip
  #p MSG.parse DATA.read

  #content = File.read 'omg.msg', encoding: 'windows-1251'
  #content.encode! 'utf-8'
  ##puts content
  #content.gsub! "\r", "\n"
  #while content =~ /\n\n/ # darker magics (gsub is misbehaving, possibly some mix of encodings)
  #  content.gsub! /\n\n/, "\n" # cuz focking inconsistant
  #                             # input
  #end
  #p content.chars.count #1899
  #p content =~ /\n\n/
  ##content.gsub! /\n\n/, "\n" # cuz focking inconsistant
  ##p content =~ /\n\n/
  ##exit 0
  ###p content
  ##p content =~ /# changed/
  ##p content[1825]
  ##p content[1824]
  ##p content[1823]
  #p MSG.to_h content

  #hash = MSG.to_h File.read 'gizmo.msg'
  ##p hash
  ##puts '---'
  ##p hash[1106]

  #require 'yaml'
  #File.write 'gizmo.yml', YAML.dump(hash)
end
