xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Nýjustu spurningarnar á vidraedur.is"
    xml.description ""
    xml.link url_for
    for question in @questions
      xml.item do
        xml.title question.name
        xml.pubDate question.created_at.to_s(:rfc822)
        xml.author question.user.login if question.user
        xml.link question_url(question)
      end
    end
  end
end