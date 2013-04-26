class CreateTodoItems < ActiveRecord::Migration
  def change
    create_table :todo_items do |t|
      t.string :description
      t.string :notes
      t.boolean :done

      t.timestamps
    end
  end
end
