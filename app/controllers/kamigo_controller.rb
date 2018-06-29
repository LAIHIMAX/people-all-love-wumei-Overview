
require 'line/bot'
class KamigoController < ApplicationController
    protect_from_forgery with: :null_session

    def webhook
        # 設定回覆文字
        reply_text = keyword_reply(received_text)

         # 傳送訊息到 line
         response = reply_to_line(reply_text)
     
         # 回應 200
         head :ok
    end

    # Line Bot API初始化物件
    def line        
        return @line unless @line.nil?
        @line = Line::Bot::Client.new { |config|
           config.channel_secret = '3b4829231d6b2f234316683d1dca79fc'
           config.channel_token = 'Mjuod9qwt2oSVms1uuFrk0Y4RW4B3sqRge+AnCKzyHAjjfGEUBxbBWO2Rc9xPYkmrhVjHlekKL+dmZZi1rYmasAevDtG9JtNmzbbPYZCzB56TjAzpimlLFIziVXoSSDT4udc0XvTJur5F+1+MN7cqgdB04t89/1O/w1cDnyilFU='
       }
    end

    #傳送訊息到line
    def reply_to_line(reply_text)
        # 取得 reply token
        reply_token = params['events'][0]['replyToken']

        # 設定回覆訊息
        message = {
            type: 'text',
            text: reply_text
        }
        
        # 傳送訊息
        line.reply_message(reply_token, message)        
    end

    #取得對方說的話
    def received_text
        params['events'][0]['message']['text']
    end

    #關鍵字回覆
    def keyword_reply(received_text)
        received_text
    end
end
