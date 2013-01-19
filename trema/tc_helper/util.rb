# coding: utf-8

module TCHelper

  def flavor_tc_packet(packetin)

    class << packetin
      TC_PORT = 20000

      attr_reader :tc_body, :tc_state, :tc_switchno, :tc_segment

      def tc_packet?
        if self.udp? and self.udp_dst_port == TC_PORT
          parse_header
          return true
        end
        false
      end

      # STATE:OPEN
      # STATE:BPDY
      # STATE:CLOSE
      # ROOMNO: datapath_id
      def tc_openstate?
        self.tc_state == :OPEN
      end

      def tc_bodystate?
        self.tc_state == :BODY
      end

      def tc_closestate?
        self.tc_state == :CLOSE
      end

      def message_dump
        puts "macsa: #{self.macsa}"
        puts "macda:  #{self.macda}"
        puts "in_port: #{self.in_port}"
        puts "arp" if self.arp?
        puts "icmpv4" if self.icmpv4?
        if self.ipv4?
          puts "ipv4"
          puts "ipv4_saddr: #{self.ipv4_saddr}"
          puts "ipv4_daddr: #{self.ipv4_daddr}"
        end
        if self.udp?
          puts "udp"
          puts "udp_src_port: #{self.udp_src_port}"
          puts "udp_dst_port: #{self.udp_dst_port}"
          puts "udp_payload: #{self.udp_payload}"
        end
        puts "tcp" if self.tcp?
      end

      private

      def parse_header
        puts self.udp_payload
        self.udp_payload =~ /^STATE:(OPEN|BODY|CLOSE)$/
        raise "Header with no STATE field" unless $1
        @tc_state = $1.to_sym
        puts @tc_state

        self.udp_payload =~ /^ROOMNO:(\d+)^/
        @tc_switchno = $1.to_i if $1
      end
    end

  end
end
