# coding: utf-8

module TCHelper
  class Node
    attr_accessor :mac, :ip

    def initialize(mac, ip)
      @mac = mac.class == String ? Mac.new(mac) : mac
      @ip  = ip.class  == String ? IP.new(ip)   : ip
    end

  end

  class Sendor < Node
    # def initialize(mac, ip, hp_file)
    #   super(mac, ip)
    #   @hp_file = hp_file
    # end
  end

  class Receiver < Node
  end
end
