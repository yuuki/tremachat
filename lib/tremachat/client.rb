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
      # off ip_header on userland
      @socket.setsockopt(IPPROTO_IP, IP_HDRINCL, 0)
    end

    def recv
      buff, ip_saddr = @socket.recvfrom(8041, MSG_WAITALL)
      puts buff, ip_saddr
    end

    def send(message)
      @socket.send(message, 0, '127.0.0.1')
    end
  end
end
