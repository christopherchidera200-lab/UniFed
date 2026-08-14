require "rails_helper"

RSpec.describe "Seed idempotency (db/seeds.rb)", type: :request do
  it "produces a stable dataset across repeated runs (no duplicates)" do
    load Rails.root.join("db/seeds.rb")
    courses_after_first = Academic::Course.count
    libs_after_first   = Library::LibraryResource.count
    users_after_first  = Identity::User.where(email: "student@adun.edu.ng").count

    load Rails.root.join("db/seeds.rb")
    expect(Academic::Course.count).to eq(courses_after_first)
    expect(Library::LibraryResource.count).to eq(libs_after_first)
    expect(Identity::User.where(email: "student@adun.edu.ng").count).to eq(users_after_first)
  end

  it "creates demo course + library content on a fresh seed" do
    load Rails.root.join("db/seeds.rb")
    expect(Academic::Course.where(code: "CYB 301").exists?).to be true
    expect(Library::LibraryResource.where(title: "Introduction to Cybersecurity — Lecture Notes").exists?).to be true
    expect(Identity::Role.where(name: "member").exists?).to be true
  end
end
