class Plan < ActiveRecord::Base
  GBP_COUNTRIES = ["GB"]
  ISK_COUNTRIES = ["IS"]
  EUR_COUNTRIES = ["AD", "CY", "MT", "MC", "ME", "SM", "SK", "VA", "AT", "BE", "FI", "FR", "DE", "GR", "IE", "IT", "LU", "NL", "PT", "ES", "SI","EE"]

  attr_accessible :currency, :description, :max_users, :name, :paymill_offer_id, :amount, :vat, :private_instance
  has_many :subscriptions

  def self.offer_data
    [
        {:currency=>"USD", :private_instance=>true, :amount=>0.0, :max_users=>5, :vat=>0.0},
        {:currency=>"EUR", :private_instance=>true, :amount=>0.0, :max_users=>5, :vat=>0.0},
        {:currency=>"GBP", :private_instance=>true, :amount=>0.0, :max_users=>5, :vat=>0.0},
        {:currency=>"ISK", :private_instance=>true, :amount=>0.0, :max_users=>5, :vat=>0.0},

        {:currency=>"USD", :private_instance=>true, :amount=>50.0, :max_users=>50, :vat=>0.0},
        {:currency=>"EUR", :private_instance=>true, :amount=>40.0, :max_users=>50, :vat=>0.0},
        {:currency=>"GBP", :private_instance=>true, :amount=>35.0, :max_users=>50, :vat=>0.0},
        {:currency=>"ISK", :private_instance=>true, :amount=>6000.0, :max_users=>50, :vat=>0.0},

        {:currency=>"USD", :private_instance=>true, :amount=>200.0, :max_users=>500, :vat=>0.0},
        {:currency=>"EUR", :private_instance=>true, :amount=>150.0, :max_users=>500, :vat=>0.0},
        {:currency=>"GBP", :private_instance=>true, :amount=>130.0, :max_users=>500, :vat=>0.0},
        {:currency=>"ISK", :private_instance=>true, :amount=>25000.0, :max_users=>500, :vat=>0.0},

        {:currency=>"USD", :private_instance=>false, :amount=>0.0, :max_users=>50, :vat=>0.0},
        {:currency=>"EUR", :private_instance=>false, :amount=>0.0, :max_users=>50, :vat=>0.0},
        {:currency=>"GBP", :private_instance=>false, :amount=>0.0, :max_users=>50, :vat=>0.0},
        {:currency=>"ISK", :private_instance=>false, :amount=>0.0, :max_users=>50, :vat=>0.0},

        {:currency=>"USD", :private_instance=>false, :amount=>50.0, :max_users=>500, :vat=>0.0},
        {:currency=>"EUR", :private_instance=>false, :amount=>40.0, :max_users=>500, :vat=>0.0},
        {:currency=>"GBP", :private_instance=>false, :amount=>35.0, :max_users=>500, :vat=>0.0},
        {:currency=>"ISK", :private_instance=>false, :amount=>6000.0, :max_users=>500, :vat=>0.0},

        {:currency=>"USD", :private_instance=>false, :amount=>200.0, :max_users=>5000, :vat=>0.0},
        {:currency=>"EUR", :private_instance=>false, :amount=>150.0, :max_users=>5000, :vat=>0.0},
        {:currency=>"GBP", :private_instance=>false, :amount=>130.0, :max_users=>5000, :vat=>0.0},
        {:currency=>"ISK", :private_instance=>false, :amount=>25000.0, :max_users=>5000, :vat=>0.0}

    ]
  end

  def self.better_iceland_offer_data
    [
        {:currency=>"ISK", :private_instance=>true, :amount=>0.0, :max_users=>5, :vat=>0.0},
        {:currency=>"ISK", :private_instance=>true, :amount=>7800.0, :max_users=>50, :vat=>25.5},
        {:currency=>"ISK", :private_instance=>true, :amount=>32500.0, :max_users=>500, :vat=>25.5},
        {:currency=>"ISK", :private_instance=>false, :amount=>0.0, :max_users=>50, :vat=>0.0},
        {:currency=>"ISK", :private_instance=>false, :amount=>7800.0, :max_users=>500, :vat=>25.5},
        {:currency=>"ISK", :private_instance=>false, :amount=>32500.0, :max_users=>5000, :vat=>25.5}
    ]
  end


  def amount_with_vat
    if self.vat>0.0
      return_amount = self.amount
      return_vat = return_amount*(self.vat/100)
      return_amount = return_amount + return_vat
    else
      amount
    end
  end

  def self.clear_vat
    Plan.all.each do |plan|
      plan.vat = 0.0
      plan.save
    end
  end

  def self.create_paymill_offers
    Plan.all.each do |plan|
      next unless plan.currency=="EUR"
      name = "Up to #{plan.max_users} #{plan.private_instance ? 'private' : 'public'}"
      if plan.vat>0.0
        amount = plan.amount
        vat = amount*(plan.vat/100)
        amount = amount+vat
        amount = (amount*100.0).to_i
      else
        amount = (plan.amount*100.0).to_i
      end
      if amount>0
        offer = Paymill::Offer.create amount: amount, name: name, interval: "1 MONTH", currency: plan.currency, trial_period_days: 0
        plan.paymill_offer_id = offer.id
        plan.save
      end
    end
  end

  def self.create_test_data
    Plan.offer_data.each do |offer|
      name = "Up to #{offer[:max_users]} #{offer[:private_instance] ? 'private' : 'public'}"
      plan = Plan.create!(:name=>name, :private_instance=>offer[:private_instance], :max_users=>offer[:max_users], :amount=>offer[:amount], :currency=>offer[:currency], :vat=>offer[:vat])
      if plan.vat>0.0
        amount = plan.amount
        vat = amount*(plan.vat/100)
        amount = amount+vat
        amount = (amount*100.0).to_i
      else
        amount = (plan.amount*100.0).to_i
      end
      if amount>0
        offer = Paymill::Offer.create amount: amount, name: name, interval: "1 MONTH", currency: plan.currency, trial_period_days: 0
        plan.paymill_offer_id = offer.id
        plan.save
      end
    end
  end

  def self.create_better_iceland_test_data
    Plan.better_iceland_offer_data.each do |offer|
      name = "Up to #{offer[:max_users]} #{offer[:private_instance] ? 'private' : 'public'}"
      paymill_name = "Better Iceland - Up to #{offer[:max_users]} #{offer[:private_instance] ? 'private' : 'public'}"
      plan = Plan.create!(:name=>name, :private_instance=>offer[:private_instance], :max_users=>offer[:max_users], :amount=>offer[:amount], :currency=>offer[:currency], :vat=>offer[:vat])
      if plan.vat>0.0
        amount = plan.amount
        vat = amount*(plan.vat/100)
        amount = amount+vat
        amount = (amount*100.0).to_i
      else
        amount = (plan.amount*100.0).to_i
      end
      if amount>0
        #offer = Paymill::Offer.create amount: amount, name: paymill_name, interval: "1 MONTH", currency: plan.currency, trial_period_days: 0
        #plan.paymill_offer_id = offer.id
        #plan.save
      end
    end
  end

end
