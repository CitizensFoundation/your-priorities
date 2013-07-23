module HomeHelper

  def all_countries_in_columns
    one = []
    two = []
    three = []
    four = []
    five = []
    six = []
    flip = 1

    IsoCountry.by_name.all.each do |a|
      if flip==1
        one << a
        flip = 2
      elsif flip==2
        two << a
        flip = 3
      elsif flip==3
        three << a
        flip = 4
      elsif flip==4
        four << a
        flip = 5
      elsif flip==5
        five << a
        flip = 6
      elsif flip==6
        six << a
        flip = 1
      end
    end
    [one,two,three,four,five,six]
  end

  EU_AND_EEA_COUNTRIES = ["at", "be", "bg", "cy", "cz", "dk", "ee", "fi", "fr", "de", "gr", "hu", "ie", "it", "lv", "lt", "lu", "mt", "nl", "pl", "pt", "ro", "sk", "si", "es", "se", "gb","is","no","li","ch"]

  def country_in_eu_or_eea?(country_code)
    EU_AND_EEA_COUNTRIES.include?(country_code.downcase)
  end

  def get_placemark_map_style(country)
    current_sub_instance = SubInstance.current
    SubInstance.current = SubInstance.find_by_iso_country_id(country.id)
    if sub_instance = SubInstance.find_by_iso_country_id(country.id) and Idea.where("sub_instance_id = ?", sub_instance.id).count>0
      ret = "#HasIdeasStyle"
    else
      ret = "#NoIdeaStyle"
    end
    SubInstance.current = SubInstance.current
    ret
  end
end