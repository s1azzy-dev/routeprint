class IndexAirportPickerNames < ActiveRecord::Migration[8.1]
  def up
    execute "CREATE INDEX index_places_on_picker_name ON places (lower(name) text_pattern_ops);"
    execute "CREATE INDEX index_place_names_on_locale_picker_name ON place_names (locale, lower(name) text_pattern_ops);"
  end

  def down
    execute "DROP INDEX index_place_names_on_locale_picker_name;"
    execute "DROP INDEX index_places_on_picker_name;"
  end
end
