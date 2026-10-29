# frozen_string_literal: true

class UpgradePostgisExtensions < ActiveRecord::Migration[8.1]
  def up
    execute "SELECT postgis_extensions_upgrade('3.6.4')"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "PostGIS extension upgrades require restoring a database backup to downgrade"
  end
end
