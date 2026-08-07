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
end
