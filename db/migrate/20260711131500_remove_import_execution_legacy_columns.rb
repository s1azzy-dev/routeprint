class RemoveImportExecutionLegacyColumns < ActiveRecord::Migration[8.1]
  def change
    remove_column :import_run_items, :lease_token, :text
    remove_column :import_run_items, :lease_expires_at, :datetime
    remove_column :import_runs, :cancel_requested_at, :datetime
  end
end
