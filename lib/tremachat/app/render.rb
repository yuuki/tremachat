module Tremachat
  class App
    module Render

      def self.silent=(bool)
        @@silent = bool ? true : false
      end

      def self.silent
        @@silent ||= false
      end

      def self.puts(s)
        STDOUT.puts s unless silent
      end

      def self.color_code(str)
        colors = Sickill::Rainbow::TERM_COLORS.keys - [:default, :black, :white]
        n = str.each_byte.map{|c| c.to_i}.inject{|a,b|a+b}
        return colors[n%colors.size]
      end

      def self.display(arr, format)
        STDOUT.puts s unless silent
      end
    end
  end
end
