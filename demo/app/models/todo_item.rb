class TodoItem < ActiveRecord::Base
  attr_accessible :description, :done, :notes

  def to_api
    ret = {}
    ret[:id] = self.id
    ret[:description] = self.description
    ret[:done] = self.done
    ret[:notes] = self.notes
    ret[:created_at] = self.created_at.utc.to_i
    ret[:updated_at] = self.updated_at.utc.to_i
    return ret
  end
end
