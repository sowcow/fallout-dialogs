require_relative 'lib/msg'
require_relative 'lib/nodes'

require 'pathname'
require 'yaml'

module Paths
  module_function

  def messages_file
    Pathname 'yaml/messages.yml'
  end
  def codes_file
    Pathname 'yaml/codes.yml'
  end
  def nodes_file
    Pathname 'yaml/nodes.yml'
  end

  def input_files
    Pathname.glob 'input/*'
  end

  def input_msg_files
    input_files.select { |x| x.extname == '.MSG' }
  end
  def input_ssl_files
    input_files.select { |x| x.extname == '.ssl' }
  end

  refine Pathname do
    def msg?
      extname == '.MSG'
    end
    def ssl?
      extname == '.ssl'
    end
    def buddy
      case
      when ssl? then Pathname to_s.sub('.ssl', '.MSG')
      when msg? then Pathname to_s.sub('.MSG', '.ssl')
      else
        raise
      end
    end
    #def read
    #  p self
    #  File.read self.to_s, encoding: 'windows-1251'
    #  super #(encoding: 'windows-1251').encode 'utf-8'
    #end
    #def write text
    #  File.write self, text
    #end
    def to_name
      basename.to_s.sub extname, ''
    end
  end
end
include Paths
using Paths


# defensive a little bit
# but some confidence may feel good though
# kinda input invariants,
# that aslo freeze/simpify data format
#
task :files do

  by_ext = input_files.group_by { |x| x.extname }

  odds = by_ext.keys - ['.MSG','.ssl']
  odds.empty? or raise "by ext check failed: #{odds}"


  by_name = input_files.
    group_by { |x| x.to_name }

  non_paired = by_name.values.select { |a|
    a.count != 2
  }
  raise "pairedness check failed: #{non_paired}" \
  if non_paired.any?

  p input_ssl_files.count

  raise unless\
  input_ssl_files.all? { |file|
    p file
    File.read(file, encoding: 'windows-1251') =~
    /^procedure [Ss]tart\r\n/
  }

  puts 'input files looks good'
end


task :yaml => [:files, :messages_yml, :nodes_yml]

task :messages_yml do
  hash = {}

  input_msg_files.each { |msg_file|
    puts "processing: #{msg_file}"

    content = msg_file.read encoding: 'windows-1251'
    content.gsub! "\r", "\n"
    content.gsub! "\n\n", "\n" # cuz focking inconsistant
                               # input

    name = msg_file.to_name
    raise 'impossible' if hash[name]
    hash[name] = MSG.to_h content
    p :ok
  }

  data = YAML.dump hash
  File.write messages_file, data
end

task :codes_yml do
  hash = {}
  input_ssl_files.each { |file|
    puts "processing: #{file}"

    content = file.read encoding: 'windows-1251'
    content.gsub! "\r", ""

    found = 
    content.lines.each_with_index.find { |line, index|
      line == "begin\n"
    }
    raise content.inspect unless found
    content = content.lines.drop(found[1]-1).join
    #p '============================'
    #puts content
    #p '============================'

    data = Nodes.to_h content

    name = file.to_name
    raise 'impossible' if hash[name]
    hash[name] = data
  }

  data = YAML.dump hash
  File.write codes_file, data
end



desc 'do it before yaml task'
task :delete_empty_inputs do
  by_ext = input_files. #select { |x| x.msg? }.
    select { |x|
      x.read(encoding: 'windows-1251') =~ /\A\s*\z/
    }.each { |empty|
      puts "deleteing #{empty}"
      File.delete empty
      puts "deleteing #{empty.buddy}"
      File.delete empty.buddy
    }
end

desc 'and this (destructive too)'
#task :delete_definitions_from_ssl_files do
task :preprocess_ssl_files do
  input_ssl_files.each { |file|
    content = file.read encoding: 'windows-1251'
    content.gsub! "\r", ""

    found = 
    content.lines.each_with_index.find { |line, index|
      line == "begin\n"
    }
    raise content.inspect unless found
    content = content.lines.drop(found[1]-1).join
    content = content.encode 'utf-8'

    File.write file, content
  }
end



task :nodes_yml do
  messages = YAML.load File.read messages_file
  codes = YAML.load File.read codes_file

  dialogs_data = {}
  messages.map { |dialog, messages|
    code = codes.fetch dialog #] or raise 

    nodes = code.map { |name,code|
      data = extract_data code, messages
      { 'name' => name, 'code' => code }.merge data
    }#.reduce(:merge)# || {} # no run use of hash

    raise :impossible if dialogs_data[dialog]
    dialogs_data[dialog] = nodes
  }

  content = YAML.dump dialogs_data
  File.write nodes_file, content
end

# todo?
# message_str + random...

def extract_data code, messages
  hash = {}
  code.scan(/say_reply\(\d+, (\d+)/).each { |(id)|
    id = Integer id
    next unless messages.has_key? id
    text = messages.fetch id
    (hash['replies'] ||= []) << text
  }
  code.scan(/message_str\(\d+, (\d+)/).each { |(id)|
    id = Integer id
    next unless messages.has_key? id
    text = messages.fetch id
    (hash['used'] ||= []) << text
  }
  code.scan(/option[(].*?,.*?, (\d+), (.*?),/).
    each {|(id,node)|
      id = Integer id
      next unless messages.has_key? id
      text = messages.fetch id
      (hash['options'] ||= []) << {node => text}
    }
  code.scan(/say_message\(\d+, (\d+)/).each { |(id)|
    id = Integer id
    next unless messages.has_key? id
    text = messages.fetch id
    (hash['messages'] ||= []) << text
  }
  code.scan(/call (.*);/).each { |(name)|
    (hash['calls'] ||= []) << name
  }
  hash
rescue
  p code
  p messages
  raise
end

__END__
task :yaml => :files do

  DataStruct = Struct.new :ssl, :msg, :name
  data = Dir['dialog_data/got/*.ssl'].map { |ssl|
    name = File.basename(ssl).sub /[.][^\.]+/, ''
    msg = ssl.sub /[.]ssl/, '.MSG'
    raise unless File.exist? msg

    p msg
    [ssl, msg, name]
  }.map { |a| p DataStruct.new *a }

  list = data.each { |pair|
    puts '==='
    p pair
    messages = MSG.to_h File.read pair.msg
    nodes = []

    { name: {
        messages: messages, nodes: nodes
      }
    }
  }

  hash = list.reduce :merge
  raise if hash.count != list.count

  File.write 'data.yml', hash
end

__END__

require_relative 'lib/msg'
require_relative 'lib/node'


task :default => :data_to_yaml


task :data_to_yaml do

  DataStruct = Struct.new :ssl, :msg, :name
  data = Dir['dialog_data/got/*.ssl'].map { |ssl|
    name = File.basename(ssl).sub /[.][^\.]+/, ''
    msg = ssl.sub /[.]ssl/, '.MSG'
    raise unless File.exist? msg

    p msg
    [ssl, msg, name]
  }.map { |a| p DataStruct.new *a }

  list = data.each { |pair|
    puts '==='
    p pair
    messages = MSG.to_h File.read pair.msg
    nodes = []

    { name: {
        messages: messages, nodes: nodes
      }
    }
  }

  hash = list.reduce :merge
  raise if hash.count != list.count

  File.write 'data.yml', hash
end





__END__
task :default => :site

task :site do
  rm_rf 'site'
  mkpath 'site/assets/'
  mkpath 'site/pages/'

  make_pages
  File.write 'site/index.html', main_page
end

def make_pages
  inputs.each { |ssl, msg|
    Dialog.new(ssl, msg).to_html
  }
end

def main_page
  Slim::Template.new { MAIN_PAGE }.render data
end

def data
  binding
end

def pages
  [?a, ?b, ?c]
end

MAIN_PAGE = <<end
doctype 5
html
  head
    title
    meta charset='utf-8'
  body
    - for page in pages
      a href="./pages/\#{page}/"
end
