class IPHeader
  attr_accessor :version
  attr_accessor :ip_hl
  attr_accessor :ip_tos
  attr_accessor :ip_len
  attr_accessor :ip_id
  attr_accessor :ip_off
  attr_accessor :ip_ttl
  attr_accessor :ip_p
  attr_accessor :ip_sum
  attr_accessor :ip_src
  attr_accessor :ip_dst
  attr_accessor :payload

  def initialize(packet=nil, index=nil)
    if packet and index
      @version = (packet[index] >> 4) & 0xF
      @ip_hl = packet[index] & 0xF
      @ip_tos = packet[index + 1]
      @ip_len = (packet[index + 2] << 8) + packet[index + 3]
      @ip_id = (packet[index + 4] << 8) + packet[index + 5]
      @ip_off = (packet[index + 6] << 8) + packet[index + 7]
      @ip_ttl = packet[index + 8]
      @ip_p = packet[index + 9]
      @ip_sum = (packet[index + 10] << 8) + packet[index + 11]
      @ip_src = ip_tos(packet, index + 12)
      @ip_dst = ip_tos(packet, index + 16)
      @payload = packet.slice((index + 20)..-1)
    end
  end

  def ip_tos(packet, index)
    return sprintf("%d.%d.%d.%d", packet[index], packet[index + 1], packet[index + 2], packet[index + 3])
  end

  def to_buf
  end
end
