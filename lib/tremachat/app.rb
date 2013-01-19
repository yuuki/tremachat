require 'tremachat/app/cmds'
require 'tremachat/app/render'

require 'args_parser'

module Tremachat
  class App
    include Cmds

    def initialize
    end

    def client
      @client ||= Tremachat::Client.new
    end

    def run(argv)
      @parser = ArgsParser.parse argv, :style => :equal do
        arg :timeline, 'show timeline', :alias => :tl
        arg :list, 'show room list', :alias => :l
        arg :dport, 'specify destination port', :alias => :dp
        arg :version, 'show version', :alias => :v
        arg :help, 'show help', :alias => :h
      end

      if @parser.has_option? :help
        STDERR.puts "TremaChat - Trema Chat client in Ruby v#{Tremachat::VERSION}"
        STDERR.puts
        STDERR.puts @parser.help
        STDERR.puts
        STDERR.puts "e.g."
        STDERR.puts "send   tc hello world"
        STDERR.puts "recv   tc --timeline"
        exit 0
      end

      regist_cmds

      cmds.each do |name, cmd|
        next unless @parser[name]
        cmd.call @parser[name], @parser
      end

      if @parser.argv.size < 1
        STDERR.puts @parser.help
      else
        message = @parser.argv.join(' ')
        Render.puts(message)
        begin
          client.send "STATE:BODY\n\n"+message, nil, @parser[:dport]
        rescue => e
          STDERR.puts e.message
        end
      end

      client.close
    end
  end
end
