# -*- coding: utf-8 -*-

require "pp"
require "tc_helper"

class TCController < Controller
  include TCHelper

  TC_PROTOCOL = 134
  TC_PORT = 20000

  def start
    @fdb = FDB.new
    @clients = []
  end

  def packet_in(dpid, message)
    @dpid ||= dpid

    @fdb.learn(message.macsa, message.in_port)
    port = @fdb.lookup_port(message.macda)

    flavor_tc_packet(message)

    unless port
      puts "flooding: #{message.macsa} => #{message.macda}"
      puts "tc_packet" if message.tc_packet?
      flood(message)
      return
    end

    unless message.tc_packet?
      # add_noise_flow_and_send_packet(message, port)
      send_out_by_port(message.datapath_id, message, port)
      return
    end

    message.dump

    if message.tc_openstate?
      puts "open!!"
      @clients << Node.new(message.macsa, message.ipv4_saddr)
      @clients.uniq!(&:ip)
      modify_client_flow(message, port, @clients)
    elsif message.tc_closestate?
      puts "close!"
      @clients.delete_if {|c| c.ip.to_s == message.ipv4_saddr}
      modify_client_flow(message, port, @clients)
    else
      puts "body!"
      @clients << Node.new(message.macsa, message.ipv4_saddr)
      @clients.uniq!(&:ip)
      add_client_flow_and_send_packet(message, port, @clients)
    end
    puts @clients.map(&:ip).join(" ")
  end

  private

  def flood(message)
    send_packet_out(
      message.datapath_id,
      :packet_in => message,
      :actions   => SendOutPort.new(OFPP_FLOOD)
    )
  end

  def add_flow_and_send_packet(dpid, buffer_id, options)
    send_flow_mod_add(dpid,
      {
        :buffer_id     => buffer_id,
        :send_flow_rem => false,
      }.merge!(options)
    )
  end

  def add_client_flow_and_send_packet(message, port, clients)
    clients.empty? and return
    add_flow_and_send_packet(message.datapath_id, message.buffer_id,
      :match        => Match.new(
        :dl_src => message.macsa,      :dl_dst => message.macda,
        :nw_src => message.ipv4_saddr, :nw_dst => message.ipv4_daddr,
        :tp_dst => message.udp_dst_port
      ),
      :actions      => actions_for_copy(clients)
    )
  end

  def modify_client_flow(message, port, clients)
    clients.empty? and return
    clients.each do |client|
      puts client.mac
      send_flow_mod_modify(message.datapath_id,
        :buffer_id     => message.buffer_id,
        :send_flow_rem => false,
        :match         => Match.new(
          :dl_src => client.mac.to_s, :dl_dst => message.macda,
          :nw_src => client.ip.to_s,  :nw_dst => message.ipv4_daddr,
          :tp_dst => message.udp_dst_port
        ),
        :actions       => actions_for_copy(clients)
      )
    end
  end

  def add_noise_flow_and_send_packet(message, port)
    add_flow_and_send_packet(message.datapath_id, message.buffer_id,
      :match     => Match.new(
          :dl_src => message.macsa,      :dl_dst => message.macda,
          :dl_type => message.eth_type
      ),
      :actions   => SendOutPort.new(port),
      :priority  => 0x1111
    )
  end

  def send_out_by_port(datapath_id, message, port)
    send_packet_out(
      datapath_id,
      :packet_in => message,
      :actions   => SendOutPort.new(port)
    )
  end

  def actions_for_copy(nodes)
    actions = nodes.map do |node|
      port = @fdb.port_by_node(node)
      [
        SetEthDstAddr.new(node.mac.to_s),
        SetIpDstAddr.new(node.ip.to_s),
        SendOutPort.new(port)
      ]
    end.flatten!
  end

end
