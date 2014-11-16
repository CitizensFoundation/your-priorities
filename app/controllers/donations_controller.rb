class DonationsController < ApplicationController
  
  def get_layout
    if action_name=="estartup" or action_name=="thank_you_estartup"
      return "estartup"
    else
      return Instance.current.layout_for_subscriptions
    end
  end
  
  def status
    @sum = Donation.where(:external_project_id=>params[:external_project_id]).sum(:amount)
    render :layout=>false 
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

  def estartup
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

    Rails.logger.debug("Donation: #{@donation.inspect} #{params[:donation]}")

    begin
      if params[:donation][:estartup]
        @donation.external_project_id = 1
        transaction = Paymill::Transaction.create amount: (@donation.amount*100.0).to_i, currency: @donation.currency, token: @donation.paymill_card_token, description: "Balkan Startup Project to Citizens Foundation / Ibuar Samradslydraedi in Iceland"
      else
        transaction = Paymill::Transaction.create amount: (@donation.amount*100.0).to_i, currency: @donation.currency, token: @donation.paymill_card_token, description: "Donation to Citizens Foundation / Ibuar Samradslydraedi in Iceland"
      end
      if transaction and transaction.id
        @donation.paymill_transaction_id = transaction.id
        @donation.save
        if params[:donation][:estartup]
          redirect_to "https://balkan-startup.yrpri.org/pages/thank_you_for_donating"
        else
          redirect_to :action=>"thank_you"
        end
      end
    rescue Paymill::PaymillError => e
      Rails.logger.error "Paymill error while creating transaction: #{e.message} #{Paymill.api_key}"
      @donation.errors.add :base, tr("There was a problem with your credit card - Please try again.","here")
      if params[:donation][:estartup]
        render action: "estartup"
      else
        render action: "new"
      end
    end
  end

  def thank_you
  end

  def estartup_thank_you
  end
end
