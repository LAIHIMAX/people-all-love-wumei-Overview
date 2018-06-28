require 'net/http'
require 'line/bot'
class KamigoController < ApplicationController
    protect_from_forgery with: :null_session

    def webhook
        render plain: params
    end

    def sent_request
        uri = URI('http://localhost:3000/kamigo/response_body')
        response = Net::HTTP.get(uri).force_encoding("UTF-8")
        render plain: translate_to_korean(response)
    end

    def translate_to_korean(message)
        "#{message}油~"
    end
end
