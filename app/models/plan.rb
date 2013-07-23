class Plan < ActiveRecord::Base
  attr_accessible :currency, :description, :max_users, :name, :paymill_id, :price_gbp, :price_eur, :price_usd
  has_many :subscriptions

  after_initialize :default_values

  def default_values
    self.name ||= "---\nen: Some name\nis: Nafn\n"
    self.description ||= "---\nen: | \n      <h1>Some description</h1>\nis: | \n      <h1>Útskýring</h1>\n"
  end

  def price
    self.price_gbp
    self.price_eur
    self.price_isk
    self.price_usd
  end

  def price_unit
    "€"
    "£"
    "isk "
    "$"
  end

  def self.create_test_data
    plan1 = Plan.create!(:private_instance=>true, :max_users=>5, :price_usd=>0.0, :price_eur=>0.0, :price_gbp=>0.0)
    plan1.private_instance = true
    plan1.name = "---\nen: Free\nis: Ókeypis\n"
    plan1.save
    plan2 = Plan.create!(:private_instance=>true, :max_users=>50, :price_usd=>50.0, :price_eur=>49.0, :price_gbp=>30.0)
    plan2.private_instance = true
    plan2.name = "---\nen: Small\nis: Lítið\n"
    plan2.save
    plan3 = Plan.create!(:private_instance=>true, :max_users=>500, :price_usd=>200.0, :price_eur=>399.0, :price_gbp=>200.0)
    plan3.private_instance = true
    plan3.name = "---\nen: Medium\nis: Miðlungs\n"
    plan3.save
    plan5 = Plan.create!(:private_instance=>false, :max_users=>50, :price_usd=>0.0, :price_eur=>0.0, :price_gbp=>0.0)
    plan5.name = "---\nen: Free\nis: Ókeypis\n"
    plan5.save
    plan6 = Plan.create!(:private_instance=>false, :max_users=>500, :price_usd=>50.0, :price_eur=>49.0, :price_gbp=>30.0)
    plan6.name = "---\nen: Small\nis: Lítið\n"
    plan6.save
    plan7 = Plan.create!(:private_instance=>false, :max_users=>5000, :price_usd=>200.0, :price_eur=>399.0, :price_gbp=>200.0)
    plan7.name = "---\nen: Medium\nis: Miðlungs\n"
    plan7.save
  end
end
