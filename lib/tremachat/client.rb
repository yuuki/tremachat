require 'socket'
require 'ipaddr'
require 'tremachat/app/render'

module Tremachat
  class Client
    include Socket::Constants
    TC_PROTOCOL = 134
    TC_PORT = 20000
    TC_ADDR = "192.168.200.202"
    BUFSIZE = 10000

    def initialize
      @ssock = UDPSocket.new
      @rsock = UDPSocket.new
    end

    def bind
      @rsock.bind("0.0.0.0", TC_PORT)
    end

    def recv
      buff, inetaddr = @rsock.recvfrom(BUFSIZE)
      return buff
    end

    def send(message, daddr=nil, dport=nil)
      @ssock.send(message, 0, daddr || TC_ADDR, TC_PORT || dport)
    end

    def close
      @ssock.close
      @rsock.close
    end
  end
end
