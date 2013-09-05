class Subscription < ActiveRecord::Base
  attr_accessible :active, :last_payment_at, :paymill_id, :email, :plan_id, :user_id, :paymill_card_token

  belongs_to :plan
  belongs_to :user
  validates_presence_of :plan_id
  
  attr_accessor :paymill_card_token


  def next_charge_date
    if self.paymill_id
      subscription = Paymill::Subscription.find(self.paymill_id)
      Rails.logger.info("Next charge date #{subscription.next_capture_at}")
      subscription.next_capture_at.strftime("%d %B %Y")
    end
  end

  def cancel_current_subscription(current_subscription)
    Rails.logger.info("Cancel current subscription #{current_subscription} #{current_subscription.paymill_id}")
    if current_subscription.paymill_id
      Paymill::Subscription.delete(current_subscription.paymill_id)
      current_subscription.paymill_id = nil
      current_subscription.save(:validate=>false)
    end
  end

  def save_with_payment(user,current_subscription)
    if valid?
      if user.paymill_id
        client = Paymill::Client.find(user.paymill_id)
      else
        client = Paymill::Client.create email: user.email, description: user.login
        user.paymill_id = client.id
        user.save(:validate=>false)
      end
      payment = Paymill::Payment.create token: paymill_card_token, client: client.id
      cancel_current_subscription(current_subscription)
      subscription = Paymill::Subscription.create offer: plan.paymill_offer_id, client: client.id, payment: payment.id
      self.user=user
      self.paymill_id = subscription.id
      save!
      offer = Paymill::Offer.find(plan.paymill_offer_id)
      UserMailer.thank_you_for_payment(user,"#{offer.currency} #{offer.amount/100.0}",plan,subscription.next_capture_at.strftime("%d %B %Y")).deliver
    end
  rescue Paymill::PaymillError => e
    Rails.logger.error "Paymill error while creating customer: #{e.message} #{Paymill.api_key}"
    errors.add :base, tr("There was a problem with your credit card - Please try again.","here")
    false
  end
end
