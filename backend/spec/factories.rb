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

  # ---- Phase 1: Federation ----
  factory :federation_actor, class: "Federation::Actor" do
    association :university
    actor_type { "university" }
    actor_uri { "https://adun.unifed.ng/actors/#{SecureRandom.hex(4)}@adun.unifed.ng" }
    inbox_url { "https://adun.unifed.ng/api/v1/federation/inbox" }
    outbox_url { "https://adun.unifed.ng/api/v1/federation/outbox" }
    public_key_pem { "-----BEGIN PUBLIC KEY-----\nMOCK\n-----END PUBLIC KEY-----" }
  end

  factory :federation_activity, class: "Federation::Activity" do
    association :actor, factory: :federation_actor
    activity_type { "Create" }
    object_type { "Note" }
    object_uri { "https://adun.unifed.ng/objects/#{SecureRandom.hex(6)}" }
    payload { { "type" => "Note", "content" => "hello federation" } }
  end

  factory :federation_delivery, class: "Federation::Delivery" do
    association :activity, factory: :federation_activity
    target_inbox { "https://remote.edu/inbox" }
    status { "pending" }
  end

  # ---- Phase 1: Social ----
  factory :social_post, class: "Social::Post" do
    association :university
    association :author, factory: :identity_user
    body { "UniFed is live at ADUN!" }
    visibility { "university" }
  end

  factory :social_reaction, class: "Social::Reaction" do
    association :post, factory: :social_post
    association :author, factory: :identity_user
    kind { "like" }
  end

  factory :social_comment, class: "Social::Comment" do
    association :post, factory: :social_post
    association :author, factory: :identity_user
    body { "Congrats!" }
  end

  # ---- Phase 1: Search + Profile ----
  factory :search_saved_search, class: "Search::SavedSearch" do
    association :university
    association :user, factory: :identity_user
    query { "cyber security" }
  end

  factory :profile_profile, class: "Profile::Profile" do
    association :user, factory: :identity_user
    bio { "CS student at ADUN" }
    skills { ["Ruby", "Security"] }
    portfolio { [{ "title" => "Thesis", "url" => "https://example.com" }] }
    social_links { { "twitter" => "@me" } }
    creator { false }
  end

  # ---- Phase 2: Career Hub ----
  factory :employer_profile, class: "Career::EmployerProfile" do
    association :university
    name { "Naija Tech Ltd" }
    industry { "tech" }
    verified { false }
  end

  factory :career_opportunity, class: "Career::CareerOpportunity" do
    association :employer_profile
    title { "Junior Backend Engineer" }
    employment_type { "full_time" }
    location_type { "remote" }
    remote { true }
    status { "open" }
  end

  factory :career_application, class: "Career::CareerApplication" do
    association :student
    association :career_opportunity
  end

  factory :saved_job, class: "Career::SavedJob" do
    association :student
    association :career_opportunity
  end

  # ---- Phase 2: Assessments ----
  factory :assessment_record, class: "Assessment::AssessmentRecord" do
    association :student
    association :course_offering
    component { "ca1" }
    score { 80 }
    weight { 30 }
  end

  # ---- Phase 2: Transcript issuance ----
  factory :transcript_issuance, class: "Records::TranscriptIssuance" do
    association :student
    token_hash { SecureRandom.hex(32) }
    issued_to { "verifier-1" }
    purpose { "job-application" }
  end

  # ---- Phase 2: Events / Calendar ----
  factory :event, class: "Academic::Event" do
    association :university
    title { "Convocation 2026" }
    type { "convocation" }
    event_start { 30.days.from_now }
    event_end { 31.days.from_now }
  end

  # ---- Phase 2: SIWES / Internship ----
  factory :siwes_placement, class: "Siwes::SiwesPlacement" do
    association :student
    employer_name { "Naija Tech Ltd" }
    supervisor_name { "Mr. Smith" }
    supervisor_email { "supervisor@naijatech.com" }
    start_date { 60.days.from_now.to_date }
    end_date { 150.days.from_now.to_date }
    status { "pending" }
  end

  factory :siwes_log, class: "Siwes::SiwesLog" do
    association :siwes_placement
    week_number { 1 }
    hours { 40 }
    task_summary { "Set up dev environment" }
    status { "submitted" }
  end

  # ---- Phase 2 depth: Library ----
  factory :library_resource, class: "Library::LibraryResource" do
    association :university
    title { "Introduction to Algorithms" }
    author { "Cormen et al." }
    resource_type { "book" }
  end

  factory :library_loan, class: "Library::LibraryLoan" do
    association :student
    association :library_resource
    status { "borrowed" }
  end

  # ---- Phase 2 depth: Notifications ----
  factory :notification_item, class: "Notification::NotificationItem" do
    association :university
    association :user, factory: :identity_user
    category { "system" }
    channel { "in_app" }
    title { "Welcome to UniFed" }
    status { "unread" }
  end

  # ---- Phase 2 depth: Examinations ----
  factory :exam_schedule, class: "Examination::ExamSchedule" do
    association :university
    association :course_offering
    exam_type { "exam" }
    starts_at { 30.days.from_now }
    ends_at { 30.days.from_now + 2.hours }
  end

end