
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
          begin
            while true
              fd_list = client.select
              fd_list.each do |sock|
                if sock == $stdin
                  line = $stdin.gets
                  Render.puts_cmd line
                  client.send_with_body(line)
                else
                  message, username = client.recv
                  Render.puts message
                end
              end
            end
          rescue Interrupt
            client.close
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
