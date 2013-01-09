require 'socket'
require 'ipaddr'
require 'tremachat/ip_header'
require 'tremachat/app/render'

module Tremachat
  class Client
    include Socket::Constants
    TC_PROTOCOL = 134

    def initialize
      @socket = Socket.open(AF_INET, SOCK_RAW, TC_PROTOCOL)

      # off ip_header on userland
      @socket.setsockopt(IPPROTO_IP, IP_HDRINCL, 0)
    end

    def recv
      buff, ip_saddr = @socket.recvfrom(8041, MSG_WAITALL)
      ip = IPHeader.new buff
      ip.dump
      return ip.payload
    end

    def send(message)
      sockaddr = Socket.sockaddr_in("discard", "localhost")
      @socket.send(message, 0, sockaddr)
    end
  end
end
