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
      add_noise_flow_and_send_packet(message, port)
      return
    end

    message.dump
    pp @clients.map(&:ip)

    if message.tc_openstate?
      puts "open!!"
      client = Node.new(message.macsa, message.ipv4_saddr)
      if @clients.empty? or not @clients.include?(client)
        @clients << client
      end
      add_client_flow_and_send_packet(message, port, @clients)
    elsif message.tc_closestate?
      puts "close!"
      @clients.delete_if {|c| c.ip.to_s == message.ipv4_saddr }
      modify_client_flow(message, port, @clients)
    else
      puts "body!"
      # TODO
      # return_error_packet
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
      :hard_timeout => 60,
      :match        => Match.new(:nw_src => message.ipv4_saddr, :tp_dst => message.udp_dst_port),
      :actions      => actions_for_copy(clients)
    )
  end

  def modify_client_flow(message, port, clients)
    clients.empty? and return
    send_flow_mod_modify(message,
      :hard_timeout  => 30,
      :buffer_id     => message.buffer_id,
      :send_flow_rem => false,
      :match         => Match.new(:nw_src => message.ipv4_saddr, :tp_dst => message.udp_dst_port),
      :actions       => actions_for_copy(clients)
    )
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
