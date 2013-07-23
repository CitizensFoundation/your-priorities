namespace :httrack_test do
  
  desc "all pages"
  task :all_pages => :environment do
     if ENV['domain']
       puts command = "httrack \"http://#{ENV['domain']}/\" -O \"/tmp/#{ENV['domain']}\" \"+*.#{ENV['domain']}/*\" -v"
       system command
     else
       puts "NO URL"
     end
  end
end