
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
         p '========='
         p response
         p response.body
         p '========='
     
         # 回應 200
         head :ok
    end

    def eat
        render plain: "吃土啦"
      end 
    
      def request_headers
        render plain: request.headers.to_h.reject{ |key, value|
          key.include? '.'
        }.map{ |key, value|
          "#{key}: #{value}"
        }.sort.join("\n")
      end
    
      def response_headers
        response.headers['5566'] = 'QQ'
        render plain: response.headers.to_h.map{ |key, value|
          "#{key}: #{value}"
        }.sort.join("\n")
      end
    
      def request_body
        render plain: request.body
      end
    
      def show_response_body
        puts "===這是設定前的response.body:#{response.body}==="
        render plain: "虎哇花哈哈哈"
        puts "===這是設定後的response.body:#{response.body}==="
      end
end
