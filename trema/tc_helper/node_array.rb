# coding: utf-8
#
require 'tc_helper/util'

module TCHelper
  class NodeArray < Array
    def find_by_mac(mac)
      self.find {|s| s.mac.to_s == mac.to_s}
    end
  end

  class ServerArray < NodeArray
    def choice_for_num(num)
      arr = self.clone
      tmp = (1..num).map do
        a = arr.choice
        arr.delete a
      end
      ServerArray.new(tmp)
    end

    def select_live_nodes
      self.select {|s| s.hp > 0}
    end
  end

  class ClientArray < NodeArray
  end
end
