# == FactoryBot factories for the Academic + Records + StudentId contexts.
# Only structural attributes are set; no invented institutional data.
# Uniqueness-constrained fields use sequences so examples never collide
# (the suite does not assume cross-example transaction rollback).
FactoryBot.define do
  sequence(:uni_slug) { |n| "adun#{n}" }
  sequence(:faculty_code) { |n| "FOS#{n}" }
  sequence(:dept_code) { |n| "CYB#{n}" }
  sequence(:programme_code) { |n| "CYB-BSC#{n}" }
  sequence(:course_code) { |n| "CYB #{300 + n}" }
  sequence(:matric_no) { |n| "ADUN/FS/CYB/23/%03d" % n }
  sequence(:token_hex) { |n| SecureRandom.hex(32) << n.to_s }

  factory :university, class: "Academic::University" do
    slug { generate(:uni_slug) }
    name { "Admiralty University of Nigeria" }
    short_name { "ADUN" }
    kind { "federal" }
    owner { "Nigerian Navy" }
    country_iso { "NG" }
    config_json { { "matric_pattern" => "ADUN/{FAC}/{DEPT}/{YEAR}/{SEQ}" } }
  end

  factory :faculty, class: "Academic::Faculty" do
    association :university
    code { generate(:faculty_code) }
    name { "Faculty of Science" }
    dean_name { nil }
  end

  factory :department, class: "Academic::Department" do
    association :faculty
    code { generate(:dept_code) }
    name { "Cyber Security" }
  end

  factory :programme, class: "Academic::Programme" do
    association :department
    code { generate(:programme_code) }
    name { "Cyber Security" }
    degree_type { "B.Sc" }
    duration_years { 4 }
  end

  factory :course, class: "Academic::Course" do
    association :programme
    code { generate(:course_code) }
    title { "Network Security" }
    credit_units { 3 }
    level { 300 }
    semester { 1 }
  end

  factory :academic_session, class: "Academic::AcademicSession" do
    association :university
    name { "2025/2026" }
    start_date { Date.new(2025, 10, 26) }
    end_date { Date.new(2026, 8, 9) }
  end

  factory :semester, class: "Academic::Semester" do
    association :academic_session
    number { 1 }
    lecture_start { Date.new(2025, 11, 3) }
    lecture_end { Date.new(2026, 2, 9) }
    exam_start { Date.new(2026, 2, 16) }
    exam_end { Date.new(2026, 3, 7) }
  end

  factory :lecturer, class: "Academic::Lecturer" do
    association :university
    full_name { "Dr. Example Lecturer" }
  end

  factory :student, class: "Academic::Student" do
    association :university
    matric_no { generate(:matric_no) }
    entry_year { 2023 }
    entry_mode { "UTME" }
    current_level { 300 }
    status { "active" }
  end

  factory :course_offering, class: "Academic::CourseOffering" do
    association :course
    association :academic_session
    semester_number { 1 }
    association :lecturer
  end

  factory :grade_record, class: "Records::GradeRecord" do
    association :student
    association :course_offering
    score { 70 }
    is_published { true }
  end

  factory :digital_student_id, class: "StudentId::DigitalStudentId" do
    association :student
    token_hash { generate(:token_hex) }
    qr_payload { {} }
    status { "active" }
    issued_at { Time.current }
    expires_at { 1.year.from_now }
  end

  # ---- Phase 0: Identity / RBAC / Audit / NDPA ----
  factory :identity_user, class: "Identity::User" do
    association :university
    email { "user#{SecureRandom.hex(4)}@adun.edu.ng" }
    username { "user_#{SecureRandom.hex(4)}" }
    display_name { "Test User" }
    actor_type { "student" }
    status { "active" }

    after(:create) do |user, evaluator|
      next if evaluator.skip_password
      user.credentials.create!(
        kind: "password",
        secret_enc: Identity::Credential.hash_password(evaluator.password)
      )
    end

    transient do
      password { "Sup3rSecret!" }
      skip_password { false }
    end
  end

  factory :identity_role, class: "Identity::Role" do
    association :university
    name { "student" }
    permissions { ["academic:read"] }
  end

  factory :identity_mfa_device, class: "Identity::MfaDevice" do
    association :user, factory: :identity_user
    kind { "totp" }
    label { "Authenticator" }
    confirmed { true }
    secret_enc { Identity::MfaService.encrypt(ROTP::Base32.random_base32) }
  end

  factory :identity_audit_log, class: "Identity::AuditLog" do
    association :university
    action { "auth.login" }
    actor_type { "user" }
  end

  factory :identity_credential, class: "Identity::Credential" do
    association :user, factory: :identity_user
    kind { "password" }
    secret_enc { Identity::Credential.hash_password("Sup3rSecret!") }
  end

  factory :identity_session, class: "Identity::Session" do
    association :user, factory: :identity_user
    jti { SecureRandom.hex(16) }
    refresh_jti { SecureRandom.hex(16) }
    expired_at { 30.days.from_now }
  end

  factory :identity_role_assignment, class: "Identity::RoleAssignment" do
    association :user, factory: :identity_user
    association :role, factory: :identity_role
    scope_type { "university" }
  end

  factory :identity_consent_record, class: "Identity::ConsentRecord" do
    association :user, factory: :identity_user
    purpose { "health_wellbeing" }
    granted { true }
  end
end