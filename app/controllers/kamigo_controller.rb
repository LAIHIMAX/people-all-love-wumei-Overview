
require 'line/bot'
class KamigoController < ApplicationController
    protect_from_forgery with: :null_session

    def webhook
        # 簽名驗證
        body = request.body.read
        signature = request.env['HTTP_X_LINE_SIGNATURE']
        unless line.validate_signature(body, signature)
            render plain: 'Bad Request', status: 400
            return
        end

        # 查天氣
        reply_image = get_weather(received_text)

        # 有查到的話 後面的事情就不作了
        unless reply_image.nil?
            # 傳送訊息到 line
            response = reply_image_to_line(reply_image)
            # 回應 200
            nead:ok
            return
        end        

        # 紀錄頻道
        Channel.find_or_create_by(channel_id: channel_id)

        # 學說話
        reply_text = learn(channel_id, received_text)

        # 覆寫說話
        reply_text = overwrite(channel_id, received_text) if reply_text.nil?   
        # 忘記說話
        reply_text = deleteKeyWord(channel_id, received_text) if reply_text.nil?       
        # 查詢關鍵字
        reply_text = searchKeyWord(channel_id, received_text) if reply_text.nil?       
        # 關鍵字回覆
        reply_text = keyword_reply(channel_id, received_text) if reply_text.nil?

        # 推齊
        reply_text = echo2(channel_id, received_text) if reply_text.nil?
        # 紀錄對話
        save_to_received(channel_id, received_text)
        save_to_reply(channel_id, reply_text)

        # 傳送訊息到 line
        response = reply_to_line(reply_text)
     
         # 回應 200
         head :ok
    end

    def get_weather(received_text)
        return nil unless received_text.include? '天氣'
        upload_to_imgur(get_weather_from_cwb)
    end

    # 取得最新雷達回波圖
    def get_weather_from_cwb
        uri = URI('https://www.cwb.gov.tw/V7/js/HDRadar_1000_n_val.js')
        response = Net::HTTP.get(uri)
        start_index = response.index('","') + 3
        end_index = response.index('"),') - 1
        "https://www.cwb.gov.tw" + response[start_index..end_index]
    end

    # 上傳圖片到 imgur 
    def upload_to_imgur(image_url)
        url = URI("https://api.imgur.com/3/image")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(url)
        request["authorization"] = 'Client-ID 632fbbed25e2e91'

        request.set_form_data({"image" => image_url})
        response = http.request(request)
        json = JSON.parse(response.read_body)
        begin
            json['data']['link'].gsub("http:","https:")
        rescue 
            nil
        end
    end

    # 傳送圖片到 line
    def reply_image_to_line(reply_image)
        return nil if reply_image.nil?
        
        # 取得 reply token
        reply_token = params['events'][0]['replyToken']

        # 設定回覆訊息
        message = {
            type: "image",
            originalContentUrl: reply_image,
            previewImageUrl: reply_image
        }

        # 傳送訊息
        line.reply_message(reply_token, message)
    end

    # 頻道ID
    def channel_id
        source = params['events'][0]['source']
        return source['groupId'] unless source['groupId'].nil?
        return source['roomId'] unless source['roomId'].nil?
        source['userId']
    end

    # 儲存對話
    def save_to_received(channel_id, received_text)
        return if received_text.nil?
        Received.create(channel_id: channel_id, text: received_text)    
    end

    # 儲存回應
    def save_to_reply(channel_id, reply_text)
        return if reply_text.nil?
        Reply.create(channel_id: channel_id, text: reply_text)
    end

    def echo2(channel_id, received_text)
        # 如果在channel_id最近沒有人講過received_text 烏梅就不回應
        recent_received_texts = Received.where(channel_id: channel_id).last(5)&.pluck(:text)
        return nil unless received_text.in? recent_received_texts

        # 如果在channel_id 烏梅上一句回應是received_text 烏梅就不回應
        last_reply_text = Reply.where(channel_id: channel_id).last&.text
        return nil if last_reply_text == received_text
        received_text
    end

    # 學說話
    def learn(channel_id, received_text)
        # 如果開頭不是 烏梅學說話; 就跳出
        return nil unless received_text[0..5] == '烏梅學說話 '

        received_text = received_text[6..-1]
        semicolon_index = received_text.index('=')

        # 找不到等號就跳出
        return nil if semicolon_index.nil?

        keyword = received_text[0..semicolon_index-1]
        message = received_text[semicolon_index+1..-1]

        KeywordMapping.create(channel_id: channel_id, keyword: keyword, message:message)
        '好喔~好喔~'
    end

     # 覆寫學說話
    def overwrite(channel_id, received_text)
        return nil unless received_text[0..4] == '烏梅覆寫 '
        received_text = received_text[5..-1]
        semicolon_index = received_text.index('=')
        # 找不到等號就跳出
        return nil if semicolon_index.nil?
        keyword = received_text[0..semicolon_index-1]
        message = received_text[semicolon_index+1..-1]
        keyword = KeywordMapping.find_by(channel_id:channel_id, keyword:keyword)
        keyword.message = message
        keyword.save   
        '好喔~好喔~'     
    end

    # 忘記學說話
    def deleteKeyWord(channel_id, received_text)
        return nil unless received_text[0..4] == '烏梅忘記 '
        received_text = received_text[5..-1]
        semicolon_index = received_text.index('=')
        # 找不到等號就跳出
        return nil if semicolon_index.nil?
        keyword = received_text[0..semicolon_index-1]
        message = received_text[semicolon_index+1..-1]
        keyword = KeywordMapping.find_by(channel_id:channel_id, keyword:keyword)        
        keyword.destroy
        '好喔~好喔~' 
    end

    # 查詢關鍵字
    def searchKeyWord(channel_id, received_text)
        return nil unless received_text[0..4] == '烏梅查詢 '
        keyword = received_text[5..-1]
        # 找不到等號就跳出
        return nil if keyword.nil?
        keyword = KeywordMapping.find_by(channel_id:channel_id, keyword:keyword)          
        "#{keyword.keyword} == #{keyword.message}"
    end
    
    #關鍵字回覆
    def keyword_reply(channel_id, received_text)
        mapping = KeywordMapping.where(channel_id: channel_id, keyword: received_text).last
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
