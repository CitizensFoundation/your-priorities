class DonationsController < ApplicationController

  def get_layout
    return Instance.current.layout_for_subscriptions
  end

  def new
    unless Instance.current.domain_name.include?("yrpri")
      redirect_to "/"
    end

    @donation = Donation.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    unless Instance.current.domain_name.include?("yrpri")
      redirect_to "/"
    end

    @donation = Donation.new(params[:donation])

    Rails.logger.info("Donation: #{@donation.inspect} #{params[:donation]}")

    begin
      transaction = Paymill::Transaction.create amount: (@donation.amount*100.0).to_i, currency: @donation.currency, token: @donation.paymill_card_token, description: "Donation to Citizens Foundation / Ibuar Samradslydraedi in Iceland"
      if transaction and transaction.id
        @donation.paymill_transaction_id = transaction.id
        @donation.save
        redirect_to :action=>"thank_you"
      end
    rescue Paymill::PaymillError => e
      Rails.logger.error "Paymill error while creating transaction: #{e.message} #{Paymill.api_key}"
      @donation.errors.add :base, tr("There was a problem with your credit card - Please try again.","here")
      format.html { render action: "new" }
    end
  end

  def thank_you
  end

end
