
require 'line/bot'
class KamigoController < ApplicationController
    protect_from_forgery with: :null_session

    def webhook
        # 學說話
        reply_text = learn(received_text)

        # 關鍵字回覆
        reply_text = keyword_reply(received_text) if reply_text.nil?

        # 傳送訊息到 line
        response = reply_to_line(reply_text)
     
         # 回應 200
         head :ok
    end

    # 學說話
    def learn(received_text)
        # 如果開頭不是 烏梅學說話; 就跳出
        return nil unless received_text[0..5] == '烏梅學說話;'

        received_text = received_text[6..-1]
        semicolon_index = received_text.index(';')

        # 找不到分號就跳出
        return nil if semicolon_index.nil?

        keyword = received_text[0..semicolon_index-1]
        message = received_text[semicolon_index+1..-1]

        keywordMapping.create(keyword: keyword, message:message)
        '好喔~好喔~'
    end
    
    #關鍵字回覆
    def keyword_reply(received_text)
        mapping = keywordMapping.where(keyword: received_text).last
        if mapping.nil?
            nil
        else
            mapping.message
        end        
    end

    #取得對方說的話
    def received_text
        message = params['events'][0]['message']
        message['text'] unless message.nil?
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
        return nil if reply_text.nil?

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
end
