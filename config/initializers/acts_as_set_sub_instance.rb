$:.unshift "#{File.dirname(__FILE__)}/lib"
require File.dirname(__FILE__) + '/../../lib/acts_as_set_sub_instance/active_record/acts/set_sub_instance'
ActiveRecord::Base.send :include, ActiveRecord::Acts::SetSubInstance
