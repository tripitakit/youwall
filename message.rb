class Message
  
  $uid = 0
  $fonts = []
  $colors = []
  
  attr_reader :uid, :text, :votes, :user_socket
  
  def initialize(text, user_socket)
    @uid = $uid
    @text = sanitize(text)
    @user_socket = user_socket  
    @votes = 0  
    style = style_cycler()
    @font = style[:font]
    @color =  style[:color]
    $uid += 1
    puts "New message ##{uid}:#{@text}:#{@font}:#{@color} has been added."
  end
  
  def voted
    @votes += 1
    puts self.inspect + " has been voted."
  end
  
  def to_hash
    {"uid" => @uid, "text" =>  @text, "votes" => @votes, "font" => @font, "color" => @color}
  end
  
  private 
  
    def sanitize(text)
      text[0...59]  # limit to 60 chars
      text.gsub!("<","\<") if text[0] == "<" # strip eventual trailing "<"
      return text
    end
  
    def style_cycler
      $fonts = ["Cochin", "Marker Felt", "Papyrus", "Lithos Pro"].shuffle  if $fonts.empty?
      $colors = ["darkgrey",  "darkgreen", "darkblue", "darkred"].shuffle if $colors.empty?
      {:font => $fonts.pop, :color => $colors.pop}
    end
  
end
