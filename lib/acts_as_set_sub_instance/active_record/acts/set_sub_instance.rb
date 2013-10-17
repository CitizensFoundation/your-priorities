module ActiveRecord
  module Acts
    module SetSubInstance
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def default_scope(what=nil)
          if Thread.current[:skip_default_scope_globally] or not ["activities","comments","tags","groups","ads","ideas","points","pages","r","users","categories"].include?(table_name)
            # Do nothing for now
          elsif table_name=="users"
            if Thread.current[:current_user] and Thread.current[:current_user].id == 1
              # DO NOTHING
            elsif SubInstance.current.respond_to?(:lock_users_to_instance) and SubInstance.current.lock_users_to_instance==true
              where(SubInstance.current ? ["sub_instance_id = ?", SubInstance.current.id] : nil)
            end
          elsif table_name=="categories"
            where(:sub_instance_id=>Category.where(:sub_instance_id=>SubInstance.current.id).count>0 ? SubInstance.current.id : SubInstance.find_by_short_name("default").id)
          elsif table_name=="pages"
            where(:sub_instance_id=>Page.where(:sub_instance_id=>SubInstance.current.id).count>0 ? SubInstance.current.id : SubInstance.find_by_short_name("default").id)
          elsif table_name=="groups"
            where(:sub_instance_id=>SubInstance.current ? SubInstance.current.id : nil)
          elsif table_name=="ideas"
            where(:sub_instance_id=>SubInstance.current ? SubInstance.current.id : nil).
            where("ideas.group_id IS NULL OR ideas.group_id IN (#{(Thread.current[:current_user] and not Thread.current[:current_user].groups.empty?) ? Thread.current[:current_user].groups.map{|g| g.id}.to_s.gsub("[","").gsub("]","") : "-1"})")
          elsif ["comments","tags","users"].include?(table_name)
            where(:sub_instance_id=>SubInstance.current ? SubInstance.current.id : nil)
          elsif table_name=="activities"
            where(:sub_instance_id=>SubInstance.current ? SubInstance.current.id : nil).
            where("activities.group_id IS NULL OR activities.group_id IN (#{(Thread.current[:current_user] and not Thread.current[:current_user].groups.empty?) ? Thread.current[:current_user].groups.map{|g| g.id}.to_s.gsub("[","").gsub("]","") : "-1"})")
          elsif table_name=="ads"
            where(:sub_instance_id=>SubInstance.current ? SubInstance.current.id : nil)
          elsif table_name=="points"
            where(:sub_instance_id=>SubInstance.current ? SubInstance.current.id : nil)
          elsif table_name=="endorsements"
            where(:sub_instance_id=>SubInstance.current ? SubInstance.current.id : nil)
          else
            where(:sub_instance_id=>SubInstance.current ? SubInstance.current.id : nil).
            where("ideas.group_id IS NULL OR ideas.group_id IN (#{(Thread.current[:current_user] and not Thread.current[:current_user].groups.empty?) ? Thread.current[:current_user].groups.map{|g| g.id}.to_s.gsub("[","").gsub("]","") : "-1"})").
            includes(:idea)
          end
        end

        def acts_as_set_sub_instance(options = {})
          belongs_to :sub_instance
          before_create :set_sub_instance

          class_eval <<-EOV
            include SetSubInstance::InstanceMethods
          EOV
        end
      end

      module InstanceMethods
        def set_sub_instance
          self.sub_instance_id = SubInstance.current.id
        end
      end
    end
  end
end
