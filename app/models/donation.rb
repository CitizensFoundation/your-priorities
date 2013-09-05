class Donation < ActiveRecord::Base
  attr_accessible :amount, :cardholder_name, :currency, :email, :paymill_client_id, :paymill_transaction_id, :paymill_card_token

  attr_accessor :paymill_card_token

end
