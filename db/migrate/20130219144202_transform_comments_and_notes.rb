class TransformCommentsAndNotes < ActiveRecord::Migration
  def up
    Comment.all.each do |c|
      c.content = c.content
      c.save
    end

    Idea.all.each do |i|
      i.notes = i.notes
      i.save
    end
  end

  def down
  end
end
