$:.unshift "#{File.dirname(__FILE__)}/lib"
require File.dirname(__FILE__) + '/../../lib/acts_as_taggable_on/acts_as_taggable_on'

ActiveRecord::Base.send :include, ActiveRecord::Acts::TaggableOn
ActiveRecord::Base.send :include, ActiveRecord::Acts::Tagger

Rails.logger.info "** acts_as_taggable_on: initialized properly."
