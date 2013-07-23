class TrainKey < ActiveRecord::Base
  set_table_name :tr8n_translation_keys

  def self.import_to_tolk!
    en_locale = Tolk::Locale.where(:name=>"en").first
    en_translations = en_locale.translations.all
    TrainKey.all.each do |key|
      label = key.label.gsub("{","\%{")
      puts word = en_translations.detect {|p| p.text.to_s.strip == label.to_s.strip}
      if word
        translations = TrainTranslation.find_all_by_translation_key_id(key.id).each do |tr8n_translation|
          #puts tr8n_translation
          puts locale_name = TrainLanguage.find(tr8n_translation.language_id).locale[0..1]
          locale = Tolk::Locale.find_or_create_by_name(locale_name)
          unless locale.translations.where(:phrase_id=>word.phrase_id, :text => tr8n_translation.label.gsub("{","\%{")).first
            translation = locale.translations.new(:phrase_id=>word.phrase_id, :text => tr8n_translation.label.gsub("{","\%{"))
            puts "SAVING: #{translation.inspect}"
            #raise "STOP"
            if translation.save
            elsif translation.errors[:variables].present?
              puts "[WARN] Key '#{key}' from '#{locale_name}.yml' could not be saved: #{translation.errors[:variables].first}"
            else
              puts "GENERAL ERROR"
            end
          else
            puts "Already SAVED"
          end
        end
      end
    end
  end
end

class TrainTranslation < ActiveRecord::Base
  set_table_name :tr8n_translations

end

class TrainLanguage < ActiveRecord::Base
  set_table_name :tr8n_languages

end

