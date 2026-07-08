class CreateAuthFoundation < ActiveRecord::Migration[8.1]
  def up
    enable_extension("citext")

    execute <<~SQL
      CREATE TABLE users (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        primary_email citext NOT NULL,
        primary_email_verified_at timestamptz,
        role text NOT NULL DEFAULT 'member',
        status text NOT NULL DEFAULT 'active',
        display_name text,
        locale text NOT NULL DEFAULT 'en',
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_users_on_primary_email ON users (primary_email);
    SQL

    execute <<~SQL
      CREATE TABLE user_identities (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        provider text NOT NULL,
        provider_uid text,
        email citext,
        email_verified boolean NOT NULL DEFAULT FALSE,
        password_digest text,
        metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
        password_reset_token_digest text,
        password_reset_sent_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_user_identities_on_provider_and_provider_uid
      ON user_identities (provider, provider_uid)
      WHERE provider_uid IS NOT NULL;
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_user_identities_on_user_id_and_provider_for_password
      ON user_identities (user_id, provider)
      WHERE provider = 'password';
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_user_identities_on_password_reset_token_digest
      ON user_identities (password_reset_token_digest)
      WHERE password_reset_token_digest IS NOT NULL;
    SQL

    execute <<~SQL
      CREATE INDEX index_user_identities_on_user_id ON user_identities (user_id);
    SQL

    execute <<~SQL
      CREATE TABLE user_sessions (
        id uuid PRIMARY KEY DEFAULT uuidv7(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        user_identity_id uuid NOT NULL REFERENCES user_identities(id) ON DELETE CASCADE,
        authentication_method text NOT NULL,
        token_digest text NOT NULL,
        ip_address inet,
        user_agent text,
        last_seen_at timestamptz NOT NULL,
        expires_at timestamptz NOT NULL,
        revoked_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_user_sessions_on_token_digest ON user_sessions (token_digest);
    SQL

    execute <<~SQL
      CREATE INDEX index_user_sessions_on_user_id ON user_sessions (user_id);
    SQL

    execute <<~SQL
      CREATE INDEX index_user_sessions_on_user_identity_id ON user_sessions (user_identity_id);
    SQL

    execute <<~SQL
      CREATE INDEX index_user_sessions_on_expires_at ON user_sessions (expires_at);
    SQL

    execute <<~SQL
      CREATE INDEX index_user_sessions_on_revoked_at ON user_sessions (revoked_at);
    SQL
  end

  def down
    execute("DROP TABLE IF EXISTS user_sessions;")
    execute("DROP TABLE IF EXISTS user_identities;")
    execute("DROP TABLE IF EXISTS users;")
    disable_extension("citext")
  end
end
