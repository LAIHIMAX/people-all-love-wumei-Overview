require 'line/bot'
class KamigoController < ApplicationController
    protect_from_forgery with: :null_session

    def webhook
        # Line Bot API初始化物件
        client = Line::Bot::Client.new { |config|
            config.channel_secret = '3b4829231d6b2f234316683d1dca79fc'
            config.channel_token = 'Mjuod9qwt2oSVms1uuFrk0Y4RW4B3sqRge+AnCKzyHAjjfGEUBxbBWO2Rc9xPYkmrhVjHlekKL+dmZZi1rYmasAevDtG9JtNmzbbPYZCzB56TjAzpimlLFIziVXoSSDT4udc0XvTJur5F+1+MN7cqgdB04t89/1O/w1cDnyilFU='
        }
  
        # 取得 reply token
        reply_token = params['events'][0]['replyToken']
        p "==這裡是replay_token==="
        p reply_token
        p "======================"

        # 設定回覆訊息
        message = {
            type: 'text',
            text: '好哦～好哦～'
        }

        # 傳送訊息
        response = client.reply_message(reply_token, message)
    
        # 回應 200
        head :ok
    end
end
