class AddToIsoCountryDefaultLocaleContent < ActiveRecord::Migration
  def up
    i=IsoCountry.find_by_country_english_name("Iceland")
    i.default_locale="is" if i
    i.save if i

    i=IsoCountry.find_by_country_english_name("France")
    i.default_locale="fr" if i
    i.save if i

    i=IsoCountry.find_by_country_english_name("Bulgaria")
    i.default_locale="bg" if i
    i.save if i
  end


  def down
  end
end
