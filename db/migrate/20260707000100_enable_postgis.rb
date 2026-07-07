class EnablePostgis < ActiveRecord::Migration[8.1]
  def up
    enable_extension "postgis"
  end

  def down
    disable_extension "postgis"
  end
end
