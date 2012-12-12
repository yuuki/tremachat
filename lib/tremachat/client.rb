require 'socket'
require 'tremachat/ip_header'
require 'tremachat/app/render'

module Tremachat
  class Client
    include Socket::Constants
    ETH_P_ALL    = 0x0300

    def initialize
      if RbConfig::CONFIG['host_os'] =~ /darwin/
        @socket = Socket.open(AF_INET, SOCK_RAW, 0)
      else
        @socket = Socket.open(PF_PACKET, SOCK_DGRAM, ETH_P_IP)
      end
    end

    def recv
      buff = @socket.read(8192)
    end

    def send(message)
      @socket.send(message)
    end
  end
end
