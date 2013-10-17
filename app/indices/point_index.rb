ThinkingSphinx::Index.define :point, :with => :active_record do
  indexes name
  indexes content
  #has idea.category.name, :facet=>true, :as=>"category_name"
  has updated_at
  has sub_instance_id, :as=>:sub_instance_id, :type => :integer
  has "1", :as=>:tag_count, :type=>:integer
  set_property :enable_star => true, :min_prefix_len => 2
  where "points.status = 'published'"
end