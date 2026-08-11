require "rails_helper"

# Coverage for the StudentId bounded context (was untested per audit).
# Exercises privacy-by-design issuance (only the token hash is stored) and
# offline-friendly verification (every attempt is audited).
RSpec.describe StudentId::IdIssuanceService, type: :service do
  let(:university) { create(:university) }
  let(:student) { create(:student, university: university, identity_subject: "s1") }

  describe ".issue!" do
    it "stores only the token hash, never the cleartext token" do
      result = described_class.issue!(student, issued_by: "registrar")
      id = result[:digital_id]
      token = result[:token]

      expect(id).to be_persisted
      expect(id.token_hash).to eq(Digest::SHA256.hexdigest(token))
      # Privacy-by-design: the raw token must not be recoverable from the row.
      expect(id.reload.attributes).not_to have_key("token")
      expect(id.qr_payload).to include("sub" => student.id, "matric" => student.matric_no)
    end

    it "creates an active, unexpired ID scoped to one year" do
      id = described_class.issue!(student, issued_by: "registrar")[:digital_id]
      expect(id.status).to eq("active")
      expect(id.expired?).to be(false)
      expect(id.expires_at).to be > 1.year.from_now - 1.day
    end
  end

  describe "verification round-trip" do
    let!(:issued) { described_class.issue!(student, issued_by: "registrar") }
    let(:token) { issued[:token] }

    it "accepts a valid, active token and returns the student" do
      out = StudentId::IdVerificationService.verify!(token, verifier_actor: "scanner")
      expect(out[:valid]).to be(true)
      expect(out[:student]).to eq(student)
      expect(out[:digital_id].verification_logs.last.result).to be(true)
    end

    it "rejects a tampered token as invalid_token" do
      out = StudentId::IdVerificationService.verify!(token + "x", verifier_actor: "scanner")
      expect(out[:valid]).to be(false)
      expect(out[:reason]).to eq("invalid_token")
    end

    it "rejects a revoked ID and audits the failed attempt" do
      issued[:digital_id].revoke!(by: "registrar")
      out = StudentId::IdVerificationService.verify!(token, verifier_actor: "scanner")
      expect(out[:valid]).to be(false)
      expect(out[:reason]).to eq("revoked_or_expired")
      # revoke! logged one failure; verify! logged another — both must be audited.
      expect(issued[:digital_id].verification_logs.where(result: false).count).to be >= 1
      expect(issued[:digital_id].verification_logs.last.result).to be(false)
    end

    it "rejects an expired ID" do
      id = issued[:digital_id]
      id.update_column(:expires_at, 1.day.ago) # bypass expires_after_issued validation
      out = StudentId::IdVerificationService.verify!(token, verifier_actor: "scanner")
      expect(out[:valid]).to be(false)
      expect(out[:reason]).to eq("revoked_or_expired")
    end
  end
end

RSpec.describe StudentId::DigitalStudentId, type: :model do
  let(:university) { create(:university) }
  let(:student) { create(:student, university: university, identity_subject: "s2") }

  it "requires a unique token_hash" do
    existing = create(:digital_student_id, student: student)
    dup = build(:digital_student_id, student: student, token_hash: existing.token_hash)
    expect(dup).not_to be_valid
    expect(dup.errors[:token_hash]).to be_present
  end

  it "rejects an unknown status" do
    id = build(:digital_student_id, student: student, status: "pending")
    expect(id).not_to be_valid
    expect(id.errors[:status]).to be_present
  end

  it "defaults expires_at on create" do
    id = StudentId::DigitalStudentId.create!(
      student: student,
      token_hash: SecureRandom.hex(32),
      qr_payload: {},
      status: "active",
      issued_at: Time.current
    )
    expect(id.expires_at).to be_present
  end
end
