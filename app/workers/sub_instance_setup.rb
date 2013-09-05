class SubInstanceSetup
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(sub_instance_id,user_id)
    sub_instance = SubInstance.find(sub_instance_id)
    sub_instance.setup!
    UserMailer.new_sub_instance(User.unscoped.find(user_id)).deliver
  end
end
