class Account < ActiveRecord::Base
  attr_accessible :active, :name, :paymill_id, :user_id
end
