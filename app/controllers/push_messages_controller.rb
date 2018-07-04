require 'line/bot'
class PushMessagesController < ApplicationController
    before_action :authenticate_user!

    #GET / push_messages/new
    def new
    end

    # POST /push_messages
    def create
        text = params[:text]
        Channel.all.each do |channel|
            push_to_line(channel.channel_id, text)
        end
        redirect_to '/push_messages/new'
    end

    # 傳送訊息到 line
    def push_to_line(channel_id, text)
        return nil if channel_id.nil? or text.nil?

        # 設定回覆訊息
        message = {
            type: 'text',
            text: text
        }

        # 傳送訊息
        line.push_messages(channel_id, message)
    end

    # Line Bot API初始化物件
    def line        
        return @line unless @line.nil?
        @line = Line::Bot::Client.new { |config|
        config.channel_secret = '3b4829231d6b2f234316683d1dca79fc'
        config.channel_token = 'Mjuod9qwt2oSVms1uuFrk0Y4RW4B3sqRge+AnCKzyHAjjfGEUBxbBWO2Rc9xPYkmrhVjHlekKL+dmZZi1rYmasAevDtG9JtNmzbbPYZCzB56TjAzpimlLFIziVXoSSDT4udc0XvTJur5F+1+MN7cqgdB04t89/1O/w1cDnyilFU='
    }
    end
end
