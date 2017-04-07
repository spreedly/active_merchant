module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class AwesomesauceGateway < Gateway
      self.test_url = 'https://awesomesauce-staging.herokuapp.com'
      self.live_url = 'https://awesomesauce-prod.herokuapp.com'

      self.money_format = :dollars

      self.homepage_url = 'https://awesomesauce-prod.herokuapp.com'
      self.display_name = 'Awesomesauce Gateway'

      STANDARD_ERROR_CODE_MAPPING = {
        '01' => STANDARD_ERROR_CODE[:card_declined],
        '02' => STANDARD_ERROR_CODE[:invalid_number],
        '03' => STANDARD_ERROR_CODE[:expired_card],
        '10' => STANDARD_ERROR_CODE[:processing_error]
      }

      def initialize(options={})
        requires!(options, :merchant, :secret)
        super
      end

      def purchase(money, creditcard, options={})
        post = {}
        add_invoice(post, money, options)
        add_payment(post, creditcard)
        add_customer_data(post, options)

        commit('purchase', post, options)
      end

      def capture(authorization, options={})
        post = {}
        add_ref(post, authorization)

        commit('capture', post, options)
      end

      def supports_scrubbing?
        true
      end

      private

      def add_customer_data(post, options)
        post[:name] = options[:name]
      end

      def add_invoice(post, money, options)
        post[:amount] = amount(money)
        post[:currency] = (options[:currency] || currency(money))
      end

      def add_payment(post, payment)
        post[:number] = payment.number
        post[:cv2] = payment.verification_value
        post[:exp] = payment.month.to_s + payment.year.to_s
      end

      def add_ref(post, authorization)
        post[:ref] = authorization
      end

      def add_authentication(post)
        post[:merchant] = options[:merchant]
        post[:secret] = options[:secret]
      end

      def parse(body)
        JSON.parse(body)
      end

      def commit(action, post, options)
        add_authentication(post)
        url = "#{(test? ? test_url : live_url)}/api/#{action}.json"
        response = parse(ssl_post(url, post_data(post)))
        Response.new(
          success_from(response),
          message_from(response),
          response,
          authorization: authorization_from(response),
          test: test?,
          error_code: error_code_from(response)
        )
      end

      def success_from(response)
        response["succeeded"]
      end

      def authorization_from(response)
        response["id"]
      end

      def message_from(response)
        STANDARD_ERROR_CODE_MAPPING[response["error"]]
      end

      def post_data(post)
        post.to_json
      end

      def error_code_from(response)
        unless success_from(response)
          response["error"]
        end
      end
    end
  end
end
