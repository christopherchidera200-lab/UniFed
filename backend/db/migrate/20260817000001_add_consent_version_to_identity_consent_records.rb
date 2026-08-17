class AddConsentVersionToIdentityConsentRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :identity_consent_records, :consent_version, :string, null: false, default: "1.0"
    add_column :identity_consent_records, :granted_at, :timestamptz
  end
end
