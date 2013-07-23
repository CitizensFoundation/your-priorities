class Page < ActiveRecord::Base
  attr_accessible :content, :title

  after_initialize :default_values

  def default_values
    self.title ||= "---\nen: Some title\nis: Titill\n"
    self.content ||= "---\nen: | \n      <h1>Some header</h1>\nis: | \n      <h1>Fyrirsögn</h1>\n"
  end

end