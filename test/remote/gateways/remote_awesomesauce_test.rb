require 'test_helper'

class RemoteAwesomesauceTest < Test::Unit::TestCase
  def setup
    @gateway = AwesomesauceGateway.new(fixtures(:awesomesauce))
    @amount = 100
    @credit_card = credit_card('4111111111111111')
    @options = {}
  end

  def test_successful_purchase
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
  end

  def test_failed_purchase
    response = @gateway.purchase(101, @credit_card, @options)
    assert_failure response
    assert_equal "card_declined", response.message
  end

  def test_failed_capture
    response = @gateway.capture("")
    assert_equal "processing_error", response.message
  end

end
