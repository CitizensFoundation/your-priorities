module ActiveRecord 
  class Base 
    def self.tr(a,b,c={})
      a.localized_text(c)
    end

    def tr(a,b,c={})
      a.localized_text(c)
    end
  end 
end

module ActionMailer
  class Base 
    def self.tr(a,b,c={})
      a.localized_text(c)
    end

    def tr(a,b,c={})
      a.localized_text(c)
    end
  end 
end

I18n.locale = "is"
