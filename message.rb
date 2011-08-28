class Message
  $uid = 0
  attr_reader :uid, :text, :votes, :user_socket
  
  def initialize(text, user_socket)
    @uid = $uid
    @text = text
    @user_socket = user_socket  
    @votes = 0  
    $uid += 1
    puts "New message added."
  end
  
  def voted
    @votes += 1
    puts self.inspect + " has been voted."
  end
  
  def to_hash
    {"uid" => @uid, "text" =>  @text, "votes" => @votes}
  end
  
end
