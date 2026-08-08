require "rails_helper"

RSpec.describe Social::Post, type: :model do
  let(:university) { create(:university) }
  let(:author) { create(:identity_user, university: university, skip_password: true) }

  it "creates a post and fans out to the university feed" do
    post = Social::PostService.create!(author: author, body: "Hello ADUN", visibility: "university")
    expect(post).to be_persisted
    expect(Social::FeedEntry.where(post: post, university: university).count).to eq(1)
  end

  it "creates a post from a federated AP object idempotently" do
    post = Social::Post.create_from_ap({ "id" => "https://remote.edu/obj/42", "content" => "hi" }, university: university.id)
    again = Social::Post.create_from_ap({ "id" => "https://remote.edu/obj/42", "content" => "hi" }, university: university.id)
    expect(again.id).to eq(post.id)
    expect(post.federated).to be true
  end

  it "rejects an empty body" do
    expect { Social::Post.create!(university: university, author: author, body: "") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end

RSpec.describe Social::FeedService, type: :service do
  let(:university) { create(:university) }
  let(:author) { create(:identity_user, university: university, skip_password: true) }

  it "returns home feed posts for the university" do
    p1 = Social::PostService.create!(author: author, body: "one", visibility: "university")
    p2 = Social::PostService.create!(author: author, body: "two", visibility: "university")
    feed = Social::FeedService.home_feed(university_id: university.id, page: 1)
    expect(feed.map(&:id)).to include(p1.id, p2.id)
  end
end

RSpec.describe Social::Reaction, type: :model do
  it "enforces one reaction per author per post" do
    post = create(:social_post)
    create(:social_reaction, post: post, author: post.author)
    dup = build(:social_reaction, post: post, author: post.author)
    expect(dup).not_to be_valid
  end
end
