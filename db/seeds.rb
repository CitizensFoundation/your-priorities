# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

# Create Categories

# Create Portlet Templates

i = Instance.new
i.name = "Your Instance"
i.description = "Your Instance"
i.domain_name = "yourdomain.com"
i.layout = "application"
i.admin_name = "Your Admin Name"
i.admin_email = "admin@yourdomain.com"
i.email = "admin@yourdomain.com"
i.save(:validation=>false)


si = SubInstance.new
si.short_name = "default"
si.name = "Your Default Sub Instance"
si.save(:validation=>false)

Instance.current = i

require 'activity'

u = User.new
u.login="Administrator"
u.password="admin"
u.first_name="Administrator"
u.last_name="Admin"
u.is_admin = true
u.is_root = true
u.password_confirmation="admin"
u.email="admin@admin.is"
u.save(:validate=>false)

Category.create(:name=>"Test category", :description => "", :sub_instance_id=>si.id)
