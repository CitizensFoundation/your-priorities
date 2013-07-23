class SubInstanceSetup
  include Sidekiq::Worker

  def perform(sub_instance_id)
    sub_instance = SubInstance.find(sub_instance_id)
    sub_instance.setup!
  end
end
