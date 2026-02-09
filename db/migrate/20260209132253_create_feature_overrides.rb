class CreateFeatureOverrides < ActiveRecord::Migration[8.0]
  def change
    create_table    :feature_overrides do |t|
      t.references  :feature, null: false, foreign_key: true
      t.string      :target_type, null: false
      t.string      :target_identifier, null: false
      t.boolean     :enabled, null: false

      t.timestamps
    end
    add_index :feature_overrides, [:feature_id, :target_type, :target_identifier], 
              unique: true, name: 'index_feature_overrides_uniqueness'
  end
end
