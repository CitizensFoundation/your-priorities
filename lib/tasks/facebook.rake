namespace :facebook do  
  
  desc "register any unregistered facebook templates"
  task :register_templates => :environment do
    Instance.current = Instance.all.last
    UserPublisher.register_all_templates
  end

end