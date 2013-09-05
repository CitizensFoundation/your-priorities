class IsoCountry < ActiveRecord::Base
  set_table_name :tr8n_iso_countries
  scope :by_name, :order=>"country_english_name"

  def large_flag_image
    base_flag_url(64)
  end

  def base_flag_url(size)
    "/assets/flags/#{size}/#{self.code.downcase}.png"
  end

  def name
    country_english_name
  end
end
