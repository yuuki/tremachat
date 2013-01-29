require 'socket'
require 'ipaddr'

require 'tremachat/app/render'
require 'tremachat/tc_header'


module Tremachat
  class Client
    include Socket::Constants
    TC_PROTOCOL = 134
    TC_PORT = 20000
    TC_ADDR = "192.168.200.200"
    TC_CLOSE_ADDR = "192.168.200.199"
    BUFSIZE = 10000

    def initialize
      @ssock = UDPSocket.new
      @rsock = UDPSocket.new
    end

    def select
      ret = IO::select([@rsock, $stdin])
      ret.first
    end

    def bind
      @rsock.bind("0.0.0.0", TC_PORT)
    end

    def recv
      buff, inetaddr = @rsock.recvfrom_nonblock(BUFSIZE)
      buff
    end

    def send(buff, daddr=nil, dport=nil)
      @ssock.send(buff, 0, daddr || TC_ADDR, TC_PORT || dport)
    end

    def send_with_open(message="")
      h = TCHeader.new
      h[:STATE] = :OPEN
      send(h.to_s + message)
    end

    def send_with_body(message)
      h = TCHeader.new
      h[:STATE] = :BODY
      send(h.to_s + message)
    end

    def send_with_close(message="")
      h = TCHeader.new
      h[:STATE] = :CLOSE
      send(h.to_s + message, TC_CLOSE_ADDR)
    end

    def close
      send_with_close
      @ssock.close
      @rsock.close
    end
  end
end
