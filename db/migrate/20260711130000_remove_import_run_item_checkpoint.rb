class RemoveImportRunItemCheckpoint < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TABLE import_run_items DROP COLUMN checkpoint;"
  end

  def down
    execute <<~SQL
      ALTER TABLE import_run_items
      ADD COLUMN checkpoint jsonb NOT NULL DEFAULT '{}'::jsonb;
    SQL
  end
end
