#!/Users/patrick/.rvm/rubies/ruby-1.9.2-p180/bin/ruby

# =================================================================================================
# youWall server.rb
# =================================================================================================

require 'em-websocket'
require 'sinatra/base'
require 'thin'
require 'json'
require './message'
require './ywall'

#
# Variables
# =================================================================================================
  @wall_capacity = 10
  @user_sockets = []
  @user_messages = []
  @admin_socket = nil
  @admin_messages = []
  @wall_socket = nil
  
  # admin_messages_log = "logs/admin_messages.log"
  # user_messages_log = "logs/user_messages.log"
  #    
  #  to do : msg logs + splash msgs
  #
     
#
# Message functions
# =================================================================================================

  def add_to_user_messages(text, user_socket)
    @user_messages << Message.new(text, user_socket)
  end

  def add_to_admin_messages(text)
    @admin_messages << Message.new(text)
    puts @admin_messages.inspect
  end

  def vote(uid, voting_user_socket)
    @user_messages.each do |msg|
      msg.voted if (msg.uid == uid.to_i && msg.user_socket != voting_user_socket)
    end
  end
  
  def delete(uid)
    @user_messages.each do |msg|
      @user_messages.delete(msg) if msg.uid == uid.to_i
    end
  end

  def broadcast(data)
  # sends data to all connected sockets
    @admin_socket.send data if @admin_socket
    @wall_socket.send data if @wall_socket
    @user_sockets.each do |socket|
      socket.send data
    end
  end

  def json_messages_list 
    m_list=[]
    @user_messages.last(@wall_capacity).each do |msg|
      m_list << msg.to_hash.to_json
    end
    m_list.to_json
  end  


#
# Event driven I/O server
# =================================================================================================

  EventMachine.run do
  
    #
    # Client websocket
    # ===============================================================================================
    EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |user_socket|
   
      user_socket.onopen do
        puts "New client connected (#{@user_sockets.size + 1}) ..."
        @user_sockets << user_socket
        broadcast json_messages_list
      end
    
      user_socket.onmessage do |data|
        puts "SocketMessage received from #{user_socket}.."
        message = JSON.parse(data)
        case message["type"]
          when "message"
            text = message["text"]
            puts ".. it's a text: #{text}"
            add_to_user_messages(text, user_socket)
            broadcast json_messages_list
          when "vote"
            puts ".. it is a vote for #{message['uid']}"
            vote(message["uid"], user_socket)
            @admin_socket.send json_messages_list if @admin_socket  
            @wall_socket.send json_messages_list if @wall_socket      
                
        end
      end 
      
      user_socket.onclose do
        puts "#{user_socket} closed"
        @user_sockets.delete user_socket
      end
    end
     
    #
    # Admin websocket
    # ===============================================================================================
    EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8081) do |admin_socket|
     
      admin_socket.onopen do
        puts "Admin socket connected!"
        admin_socket.send json_messages_list
        @admin_socket = admin_socket
      end
      
      admin_socket.onmessage do |data|
        puts "Admin message received for #{admin_socket}"
          message = JSON.parse(data)
          case message["type"]
            when "admin_message"
              text = message["text"]
              puts ".. it's admin text: #{text}"
              add_to_admin_messages(text)
            when "delete"
              puts ".. it is delete command for #{message['uid']}"
              delete(message["uid"])
              broadcast json_messages_list
            when "erase_all"
              puts ".. it is an erase_all command."
              @user_messages = []
              broadcast json_messages_list      
          end
        end
        
        admin_socket.onclose do
          puts "Admin socket closed."
          @admin_socket = nil 
        end
    end
  
    #
    # Wall websocket
    # ===============================================================================================
    EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8082) do |wall_socket|
      wall_socket.onopen do
        puts "Wall socket connected"
        wall_socket.send json_messages_list
        @wall_socket = wall_socket
      end
       
      wall_socket.onclose do
        puts "Wall socket closed."
        @wall_socket = nil
      end
    end
  
    #
    # Sinatra app
    # ===============================================================================================
    Ywall.run!({:port => 4567})
  
  end