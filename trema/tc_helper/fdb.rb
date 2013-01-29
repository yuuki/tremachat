# coding: utf-8

module TCHelper
  class FDB

    def initialize
      @fdb = {}
    end

    def lookup_port(mac)
      @fdb[mac.to_s]
    end

    def learn(mac, port)
      @fdb[mac.to_s] = port
    end

    def port_by_node(node)
      self.lookup_port(node.mac.to_s)
    end

  end
end
