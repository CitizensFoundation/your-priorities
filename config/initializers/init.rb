if File.exists?("#{Rails.root}/config/contacts.yml")
  config = YAML.load_file("#{Rails.root}/config/contacts.yml")
  Contacts.configure(config[Rails.env])
end