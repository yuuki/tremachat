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
    unless port
      puts "flooding port #{port}"
      flood(message)
      return
    end

    flavor_tc_packet(message)

    unless message.tc_packet?
      add_noise_flow_and_send_packet(message, port)
      return
    end

    if message.tc_openstate?
      puts "open!!"
      if @clients.include?(client)
        add_client_flow_and_send_packet(message, port, @clients)
        client = Node.new(message.macsa, message.ipv4_saddr)
        @clients << client
      end
    elsif message.tc_closestate?
      puts "close"
      @clients.keep_if {|c| c.ip.to_s != message.ipv4_saddr }
      modify_client_flow(message, port, @clients)
    else
      return_error_packet()
    end
  end

  private

  def flood(message)
    send_packet_out(
      message.datapath_id,
      :packet_in => message,
      :actions   => SendOutPort.new(OFPP_FLOOD)
    )
  end

  def add_flow_and_send_packet(message, options)
    send_flow_mod_add(message.datapath_id,
                      {
      :buffer_id     => message.buffer_id,
      :send_flow_rem => false,
      :check_overlap => true,
    }.merge!(options)
                     )
  end

  def add_client_flow_and_send_packet(message, port, clients)
    clients.empty? and return
    add_flow(message,
      :hard_timeout => 30,
      :match        => Match.new(:nw_src => message.ipv4_saddr, :tp_dst_port => message.udp_dst_port),
      :actions      => actions_for_copy(clients)
    )
  end

  def modify_client_flow(message, port, clients)
    clients.empty? and return
    send_flow_mod_modify(message,
      :hard_timeout  => 30,
      :buffer_id     => message.buffer_id,
      :send_flow_rem => false,
      :check_overlap => true,
      :match         => Match.new(:nw_src => message.ipv4_saddr, :tp_dst_port => message.udp_dst_port),
      :actions       => actions_for_copy(clients)
    )
  end

  def add_noise_flow_and_send_packet(message, port)
    add_flow_and_send_packet(message,
      :match     => Match.new(
          :dl_src => message.macsa,      :dl_dst => message.macda,
          :nw_src => message.ipv4_saddr, :nw_dst => message.ipv4_daddr
      ),
      :actions   => SendOutPort.new(port),
      :priority  => 0xeeee
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
