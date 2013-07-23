class Subscription < ActiveRecord::Base
  attr_accessible :active, :last_payment_at, :paymill_id, :email, :plan_id, :user_id, :paymill_card_token

  belongs_to :plan
  belongs_to :user
  validates_presence_of :plan_id
  
  attr_accessor :paymill_card_token
  
  def save_with_payment(user)
    if valid?
      client = Paymill::Client.create email: user.email, description: user.login
      payment = Paymill::Payment.create token: paymill_card_token, client: client.id
      #subscription = Paymill::Subscription.create offer: "offer_01bcc57ee6dd3616797a", client: client.id, payment: payment.id
      offer = Paymill::Offer.find("offer_028a8d70490779bff668")
      subscription = Paymill::Subscription.create offer: "offer_028a8d70490779bff668", client: client.id, payment: payment.id
      self.user=user
      self.paymill_id = subscription.id
      save!
    end
  rescue Paymill::PaymillError => e
    Rails.logger.error "Paymill error while creating customer: #{e.message} #{Paymill.api_key}"
    errors.add :base, "There was a problem with your credit card. Please try again. #{e.message}"
    false
  end
end
