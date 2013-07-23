class LoadYahooContacts
  
  attr_accessor :id
  
  def initialize(id,consumer,params)
    @id = id
    @consumer = consumer
    @params = params
  end

  def perform
    Instance.current = Instance.all.last
    @user = User.find(@id)
    offset = 0
    if not @user.is_importing_contacts? or not @user.attribute_present?("imported_contacts_count") or @user.imported_contacts_count > 0
      @user.is_importing_contacts = true
      @user.imported_contacts_count = 0
      @user.save(:validate => false)
    end
    consumer = Contacts::Yahoo.deserialize(@consumer)
    if consumer.authorize(@params)
      @contacts = consumer.contacts
    else
      raise "Yahoo contacts import not authorized"
    end
    if @contacts
      @contacts.each do |c|
        begin
          if c.email
            contact = @user.contacts.find_by_email(c.email)
            contact = @user.contacts.new unless contact
            contact.name = c.name
            contact.email = c.email
            contact.other_user = User.find_by_email(contact.email)
            if @user.followings_count > 0 and contact.other_user
              contact.following = followings.find_by_other_user_id(contact.other_user_id)
            end
            contact.save(:validate => false)          
            offset += 1
            @user.update_attribute(:imported_contacts_count,offset) if offset % 20 == 0        
          end
        rescue
          next
        end
      end
    end
    @user.calculate_contacts_count
    @user.imported_contacts_count = offset
    @user.is_importing_contacts = false
    @user.save(:validate => false)
  end
  
end

