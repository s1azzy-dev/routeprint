# frozen_string_literal: true

class RegisterWikidataAirlinesImportSource < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      INSERT INTO import_sources (
        key, provider_key, dataset_key, target_kind, fetch_mode, enabled,
        license_key, attribution_text, config, created_at, updated_at
      ) VALUES (
        'wikidata_airlines', 'wikidata', 'airlines', 'airline', 'api', TRUE,
        'cc0', 'Wikidata (CC0)', '{}'::jsonb, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      )
      ON CONFLICT (key) DO NOTHING;
    SQL
  end

  def down
    execute "DELETE FROM import_sources WHERE key = 'wikidata_airlines';"
  end
end
