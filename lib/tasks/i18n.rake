require 'digest/md5'

def rewrite_app_customization(text)
  text = text.gsub("\#{IDEA_TOKEN_PLURAL}",IDEA_TOKEN_PLURAL)
  text = text.gsub("\#{IDEA_TOKEN}",IDEA_TOKEN)
  text = text.gsub("\#{IDEA_TOKEN_PLURAL_CAPS}",IDEA_TOKEN_PLURAL_CAPS)
  text = text.gsub("\#{IDEA_TOKEN_CAPS}",IDEA_TOKEN_CAPS)
  text
end

namespace :i18n do

  desc "from tr8n"
  task :from_tr8n => :environment do
    TrainKey.import_to_tolk!
  end

  desc "sync"
  task :sync => :environment do
    count = 0
    all_strings = []
    [".rb",".erb",".haml"].each do |type|
      Dir.glob("**/*#{type}").uniq.each do |file|
        #puts "---------------- #{file}"
        puts file
        File.open(file).each do |line|
         # File.open(Rails.root.join("app/controllers/ideas_controller.rb")).each do |line|
          txt=line=line.gsub(" ,",",").gsub(", ",",").gsub("]=[","")
          if txt.index("tr(")
            re1='(tr\()'	# Variable Name 1
            re2='.*?'	# Non-greedy match on filler
            re3='(".*?")'	# Double Quote String 1
            re4='(,)'	# Any Single Character 1
            re5='(".*?")'	# Double Quote String 2

            re=(re1+re2+re3+re4+re5)
            m=Regexp.new(re,Regexp::IGNORECASE);
            if m.match(txt)
              var1=m.match(txt)[1];
              string1=m.match(txt)[2];
              c1=m.match(txt)[3];
              string2=m.match(txt)[4];
              all_strings << string1 unless ["ideas\" and [\"show"].include?(string1)
              #puts string2
              #""<<")"<<"("<<c1<<")"<<"("<<string2<<")"<< "\n"
            end
          end
        end
      end
    end
    content = "en:\n"
    all_strings.uniq.each do |string|
      string = rewrite_app_customization(string.strip)
      digest_string = string[1..string.length-2]
      puts "XXXXXXXXXXXXXXXXXXX--------------------#{digest_string}-----#{digest_string.hexdigest}"
      content += "  #{digest_string.hexdigest}: #{string.gsub("\#{","XXXXXAAASSDDSDSDS").gsub("{","%{").gsub("XXXXXAAASSDDSDSDS","\#{")}\n"
    end
    content += File.open(Rails.root.join("lib/en_template.yml")).read
    File.open(Rails.root.join("config/locales/en.yml"),"w").write(content)
  end

end