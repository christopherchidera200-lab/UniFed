# Campus / Smart-Campus GIS context (P0-1).
# PostGIS-compatible: geometry stored as decimal lat/lng ALWAYS (so the app
# works on staging without PostGIS). If the postgis extension is available we
# also add a `geography(Point,4326)` column + GiST index for future spatial
# queries — but no runtime path depends on it being present.
class CreateCampusContext < ActiveRecord::Migration[7.1]
  def up
    # Optional spatial extension — never fail if it isn't installed.
    begin
      enable_extension :postgis unless extension_enabled?(:postgis)
      @postgis = extension_enabled?(:postgis)
    rescue StandardError
      @postgis = false
    end

    create_table :campus_campuses, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id, null: false
      t.string :name, null: false
      t.text :address
      t.decimal :center_lat, precision: 10, scale: 7
      t.decimal :center_lng, precision: 10, scale: 7
      t.timestamps
    end
    add_foreign_key :campus_campuses, :universities, column: :university_id if table_exists?(:universities)
    add_index :campus_campuses, :university_id

    create_table :campus_places, id: false do |t|
      t.uuid :id, primary_key: true, default: -> { "gen_random_uuid()" }
      t.uuid :university_id, null: false
      t.uuid :campus_id, null: false
      t.string :name, null: false
      t.string :kind, null: false
      t.text :description
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.decimal :accessibility_level, precision: 2, scale: 1, default: 0
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    add_foreign_key :campus_places, :campus_campuses, column: :campus_id
    add_index :campus_places, :university_id
    add_index :campus_places, :campus_id
    add_index :campus_places, :kind

    # Spatial bonus column (only if PostGIS is present).
    if @postgis
      add_column :campus_places, :location, :geography, limit: { srid: 4326 }
      add_index :campus_places, :location, using: :gist
    end
  end

  def down
    remove_index :campus_places, :location if @postgis && index_exists?(:campus_places, :location)
    remove_column :campus_places, :location if column_exists?(:campus_places, :location)
    drop_table :campus_places
    drop_table :campus_campuses
  end
end
