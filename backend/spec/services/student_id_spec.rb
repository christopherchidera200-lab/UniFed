require "rails_helper"

RSpec.describe StudentId::IdIssuanceService, type: :service do
  let(:university) { create(:university) }
  let(:student)    { create(:student, university: university) }

  it "issues an active digital ID and returns a one-time token" do
    result = described_class.issue!(student, issued_by: "staff-123")
    expect(result[:digital_id]).to be_persisted
    expect(result[:digital_id].status).to eq("active")
    expect(result[:token]).to be_present
    # Only the SHA-256 hash is stored, never the cleartext token.
    expect(result[:digital_id].token_hash).to eq(Digest::SHA256.hexdigest(result[:token]))
    expect(result[:digital_id].expires_at).to be > Time.current
  end

  it "embeds signed claims in the qr payload" do
    result = described_class.issue!(student, issued_by: "staff-123")
    claims = result[:digital_id].qr_payload
    expect(claims["matric"]).to eq(student.matric_no)
    expect(claims["uni"]).to eq(university.slug)
  end
end

RSpec.describe StudentId::IdVerificationService, type: :service do
  let(:university) { create(:university) }
  let(:student)    { create(:student, university: university) }

  it "verifies a valid, active, unexpired token and logs success" do
    token = StudentId::IdIssuanceService.issue!(student, issued_by: "staff-123")[:token]
    outcome = described_class.verify!(token, verifier_actor: "guard-1", ip: "10.0.0.1")
    expect(outcome[:valid]).to be true
    expect(outcome[:student]).to eq(student)
    expect(student.digital_student_ids.first.verification_logs.last.result).to be true
  end

  it "rejects a tampered token" do
    token = StudentId::IdIssuanceService.issue!(student, issued_by: "staff-123")[:token]
    outcome = described_class.verify!("garbage.token.value", verifier_actor: "guard-1")
    expect(outcome[:valid]).to be false
    expect(outcome[:reason]).to eq("invalid_token")
  end

  it "rejects a revoked ID" do
    issued = StudentId::IdIssuanceService.issue!(student, issued_by: "staff-123")
    issued[:digital_id].revoke!(by: "admin")
    outcome = described_class.verify!(issued[:token], verifier_actor: "guard-1")
    expect(outcome[:valid]).to be false
  end
end
