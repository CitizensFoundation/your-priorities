class Page < ActiveRecord::Base
  attr_accessible :content, :title, :name, :hide_from_menu, :hide_from_menu_unless_admin

  after_initialize :default_values

  acts_as_set_sub_instance :table_name=>"pages"

  belongs_to :sub_instance

  def default_values
    self.title ||= "---\nen: Some title\nis: Titill\n"
    self.content ||= "---\nen: | \n      <h1>Some header</h1>\nis: | \n      <h1>Fyrirsögn</h1>\n"
  end

end