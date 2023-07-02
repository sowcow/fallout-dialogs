desc 'TODO: description'
task :default => [:viz, :output]

WHICH = ENV['WHICH']  # to work within generated/<section>

MSG_EXT = /\.MSG$/i

require_relative 'lib/msg'
require_relative 'lib/nodes'

require 'pathname'
require 'yaml'

module Paths
  module_function

  def messages_file
    section_path + 'yaml/messages.yml'
  end
  def codes_file
    section_path + 'yaml/codes.yml'
  end
  def section_path
    path = Pathname ?.
    path += 'generated' if WHICH
    path += WHICH if WHICH
    path
  end
  def nodes_file
    section_path + 'yaml/nodes.yml'
  end

  def viz_dir
    section_path + 'viz'
  end
  def output_dir
    section_path + 'output'
  end

  def input_dir
    section_path + 'input'
  end
  def input_files
    Pathname.glob (input_dir + '*.*')
  end

  def input_msg_files
    input_files.select { |x| x.extname =~ /\.MSG$/i }
  end
  def input_ssl_files
    input_files.select { |x| x.extname == '.ssl' }
  end

  def irrelevant_dir
    input_dir + '0_irrelevant'
  end
  def no_pair_dir
    input_dir + '1_no_pair'
  end
  def bad_ssl_dir
    input_dir + '2_bad_ssl'
  end
  def empty_msg_dir
    input_dir + '3_empty_msg'
  end

  refine Pathname do
    def msg?
      !!(extname =~ MSG_EXT)
    end
    def ssl?
      extname == '.ssl'
    end
    def buddy
      case
      when ssl?
        candidates = []
        candidates.push Pathname to_s.sub('.ssl', '.msg')
        candidates.push Pathname to_s.sub('.ssl', '.MSG')
        found = candidates.find { |x| x.exist? }
        if found
          found
        else
          candidates.first
        end
      when msg? then Pathname to_s.sub(MSG_EXT, '.ssl')
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
#desc 'check that input files are in expected format and that all MSG/ssl files are paired together'
#task :files do
#  raise "expecting some .msg files but found none" if input_msg_files.count == 0
#
#  missing_ssl = input_msg_files.select { |x| !x.buddy.exist? }
#  raise "missing .ssl files for: #{missing_ssl.map(&:to_s) * ' '}" unless missing_ssl.empty?
#
#
#  ssl_files = input_msg_files.map(&:buddy)
#
#  #if non_paired.any?
#
#  #by_ext = input_files.group_by { |x| x.extname }
#  #odds = by_ext.keys - ['.msg', '.MSG','.ssl']
#  #odds.empty? or raise "by ext check failed: #{odds}"
#
#  #by_name = input_files.
#  #  group_by { |x| x.to_name }
#
#  #non_paired = by_name.values.select { |a|
#  #  a.count != 2
#  #}
#  #raise "pairedness check failed: #{non_paired}" \
#  #if non_paired.any?
#
#  raise unless\
#  ssl_files.all? { |file|
#    p file
#    File.read(file, encoding: 'windows-1251') =~
#    /^procedure [Ss]tart\r\n/
#  }
#
#  puts 'input files looks good'
#end

desc 'move not conforming files in separate directories inside inputs'
task :segregate do
  irrelevant = input_files.reject { |x| x.msg? || x.ssl? }
  irrelevant_dir.mkpath
  irrelevant.each { |x|
    File.rename x, (irrelevant_dir + x.basename)
  }
  puts "Moved #{irrelevant.count} irrelevant files"

  msg_missing_ssl = input_msg_files.select { |x| !x.buddy.exist? }
  no_pair_dir.mkpath
  msg_missing_ssl.each { |x|
    File.rename x, (no_pair_dir + x.basename)
  }
  puts "Moved #{msg_missing_ssl.count} .msg files with missing .ssl file"

  ssl_missing_msg = input_ssl_files.select { |x| !x.buddy.exist? } # naming endend up being not perfect
  no_pair_dir.mkpath
  ssl_missing_msg.each { |x|
    File.rename x, (no_pair_dir + x.basename)
  }
  puts "Moved #{ssl_missing_msg.count} .ssl files with missing .msg file"

  ssl_files = input_msg_files.map(&:buddy)
  bad_ssl = ssl_files.reject { |file|
    if file.to_s =~ /glow4/
      p File.read(file, encoding: 'windows-1251')
      p File.read(file, encoding: 'windows-1251') =~ /^procedure [Ss]tart\r\n/
      p file.to_s
    end
    File.read(file, encoding: 'windows-1251') =~ /^procedure [Ss]tart\r\n/
  }

  bad_ssl_dir.mkpath
  bad_ssl.each { |x|
    File.rename x.buddy, (bad_ssl_dir + x.buddy.basename)
    File.rename x, (bad_ssl_dir + x.basename)
  }
  puts "Moved #{bad_ssl.count} pairs of files because .ssl file is empty or unconforming"

  empty_msg = input_msg_files.select { |x| x.read(encoding: 'windows-1251').strip == '' }
  empty_msg_dir.mkpath
  empty_msg.each { |x|
    File.rename x.buddy, (empty_msg_dir + x.buddy.basename)
    File.rename x, (empty_msg_dir + x.basename)
  }
  puts "Moved #{empty_msg.count} pairs of files because .msg file is empty"

  remaining = input_files.reject { |x| x.msg? }
  puts "Remaining are #{remaining.count} pairs of files for visualization"
end



#desc 'TODO: description'
#task :yaml => [:files, :messages_yml, :nodes_yml]

desc 'TODO: description'
task :messages_yml do
  hash = {}
  Pathname('yaml').mkpath

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

desc 'TODO: description'
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



#desc 'do it before yaml task'
#task :delete_empty_inputs do
#  by_ext = input_files. #select { |x| x.msg? }.
#    select { |x|
#      x.read(encoding: 'windows-1251') =~ /\A\s*\z/
#    }.each { |empty|
#      puts "deleteing #{empty}"
#      File.delete empty
#      puts "deleteing #{empty.buddy}"
#      File.delete empty.buddy
#    }
#end

#desc 'and this (destructive too)'
##task :delete_definitions_from_ssl_files do
#task :preprocess_ssl_files do
#  input_ssl_files.each { |file|
#    content = file.read encoding: 'windows-1251'
#    content.gsub! "\r", ""
#
#    found = 
#    content.lines.each_with_index.find { |line, index|
#      line == "begin\n"
#    }
#    raise content.inspect unless found
#    content = content.lines.drop(found[1]-1).join
#    content = content.encode 'utf-8'
#
#    File.write file, content
#  }
#end



desc 'TODO: description'
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
