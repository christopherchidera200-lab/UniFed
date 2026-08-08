require "rails_helper"

RSpec.describe Notification::NotificationService, type: :service do
  let(:university) { create(:university) }
  let(:user)       { create(:identity_user, university: university) }

  it "creates an unread notification" do
    n = described_class.notify!(university: university, user: user, category: "career", title: "New role")
    expect(n).to be_persisted
    expect(n.status).to eq("unread")
  end

  it "lists unread for a user and counts them" do
    described_class.notify!(university: university, user: user, category: "system", title: "A")
    described_class.notify!(university: university, user: user, category: "system", title: "B")
    expect(described_class.count_unread(user: user)).to eq(2)
  end

  it "marks a notification read" do
    n = described_class.notify!(university: university, user: user, category: "system", title: "A")
    described_class.mark_read!(id: n.id)
    expect(n.reload.status).to eq("read")
    expect(described_class.count_unread(user: user)).to eq(0)
  end

  it "returns none for a nil user" do
    expect(described_class.unread_for(user: nil)).to eq([])
  end
end
