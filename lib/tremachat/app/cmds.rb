
module Tremachat
  class App
    module Cmds

      module_function

      private
      def regist_cmds
        cmd :timeline do |v, opts|
          client.send_with_open
          client.bind
          Render.puts "Now Wating..."
          while true
            message, username = client.recv
            Render.puts message
          end
          exit 0
        end

        cmd :list do |v, opts|
          Render.puts "Room List"
          exit 0
        end

        cmd :version do |v, opts|
          Render.puts "tc version #{Tw::VERSION}"
          exit 0
        end
      end

      def cmd(name, &block)
        if block_given?
          cmds[name.to_sym] = block
        else
          return cmds[name.to_sym]
        end
      end

      def cmds
        @cmds ||= Hash.new
      end
    end
  end
end
