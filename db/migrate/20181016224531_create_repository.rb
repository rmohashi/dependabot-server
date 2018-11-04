class CreateRepository < ActiveRecord::Migration[5.2]
  def change
    create_table :repositories do |t|
      t.integer   :installation_id
      t.string    :repo_name
      t.string    :directory
      t.string    :package_manager
    end
  end
end
