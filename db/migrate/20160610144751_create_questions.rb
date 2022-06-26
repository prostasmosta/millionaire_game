class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer :level, null: false
      t.text :text, null: false
      t.string :answer1, null: false
      t.string :answer2
      t.string :answer3
      t.string :answer4

      t.timestamps null: false
    end

    add_index :questions, :level
  end
end
