
class TCHeader < Hash

  def initialize
    self[:USERNAME] = `whoami`.chomp!
    super
  end

  def to_s
    self.map {|k,v| "#{k.to_s.upcase}:#{v.to_s}"}.join("\n") + "\n"
  end

end
