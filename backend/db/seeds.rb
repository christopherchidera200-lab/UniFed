# UniFed demo seed — idempotent. Safe to re-run.
# Creates an 'adun' node, a demo student (login-able), an employer with an
# open opportunity, and a couple of calendar events so a browser session has
# data to browse. NOT for production use.
#
# Run (inside the container):  rails runner db/seeds.rb
# Or:                          docker compose run backend rails runner db/seeds.rb

def demo_password
  # Argon2 hash of "Passw0rd!" so the demo account is login-able in the browser.
  Identity::Credential.hash_password("Passw0rd!")
end

# --- University node ---
uni = Academic::University.find_or_create_by!(slug: "adun") do |u|
  u.name = "Adunni University"
  u.short_name = "ADUN"
  u.country_iso = "NG"
end
# Ensure the matric-validation pattern exists so the demo student's matric
# (and self-signup matric linkage) validate against the university scheme.
uni.update!(config_json: (uni.config_json || {}).merge("matric_pattern" => "ADUN/{FAC}/{DEPT}/{YEAR}/{SEQ}")) if uni.config_json.dig("matric_pattern").blank?
puts "university: #{uni.slug} (#{uni.id})"

# --- Demo student account + academic actor ---
student_user = Identity::User.find_or_create_by!(email: "student@adun.edu.ng", university: uni) do |usr|
  usr.username = "demo.student"
  usr.display_name = "Demo Student"
  usr.actor_type = "student"
end
student_user.credentials.find_or_create_by!(kind: "password") do |c|
  c.secret_enc = demo_password
end
student = Academic::Student.find_or_initialize_by(identity_subject: student_user.id, university: uni)
unless student.persisted?
  faculty = Academic::Faculty.find_or_create_by!(university: uni, code: "eng") { |f| f.name = "Engineering" }
  dept = Academic::Department.find_or_create_by!(faculty: faculty, code: "csc") { |d| d.name = "Computer Science" }
  prog = Academic::Programme.find_or_create_by!(department: dept, code: "CSC") { |p| p.name = "Computer Science"; p.degree_type = "B.Sc"; p.duration_years = 4 }
  session = Academic::AcademicSession.find_or_create_by!(university: uni, name: "2025/2026") do |s|
    s.start_date = Date.new(2025, 9, 1)
    s.end_date = Date.new(2026, 7, 31)
    s.is_current = true
  end
  student.assign_attributes(
    matric_no: "ADUN/ENG/CSC/21/001",
    entry_year: 2021,
    entry_mode: "UTME",
    current_level: 300,
    status: "active"
  )
  student.save!
  Academic::StudentEnrollment.find_or_create_by!(student: student, programme: prog, academic_session: session) do |en|
    en.is_primary = true
  end
end
puts "demo student: student@adun.edu.ng / Passw0rd! (actor #{student.id})"

# --- Employer + open opportunity (Career Hub) ---
employer = Career::EmployerProfile.find_or_create_by!(university: uni, name: "UniFed Labs") do |e|
  e.industry = "tech"
end
Career::CareerOpportunity.find_or_create_by!(employer_profile: employer, title: "Backend Engineering Intern") do |o|
  o.employment_type = "internship"
  o.location_type = "remote"
  o.remote = true
  o.min_level = 200
  o.salary_range = "Paid"
  o.status = "open"
  o.description = "Build federated education infrastructure with Ruby on Rails."
end
puts "employer + opportunity seeded"

# --- Calendar events ---
Academic::Event.find_or_create_by!(university: uni, title: "Convocation 2026", type: "convocation") do |e|
  e.event_start = 30.days.from_now
  e.event_end = 31.days.from_now
end
Academic::Event.find_or_create_by!(university: uni, title: "SIWES Window Opens", type: "siwes") do |e|
  e.event_start = 14.days.from_now
  e.event_end = 100.days.from_now
end
puts "calendar events seeded"

# --- Member role (for self-signup default assignment) ---
Identity::Role.find_or_create_by!(university_id: uni.id, name: "member") do |r|
  r.permissions = []
end

# --- Demo course catalogue (Cyber Security programme) ---
faculty = Academic::Faculty.find_or_create_by!(university: uni, code: "eng") { |f| f.name = "Engineering" }
dept = Academic::Department.find_or_create_by!(faculty: faculty, code: "csc") { |d| d.name = "Computer Science" }
prog = Academic::Programme.find_or_create_by!(department: dept, code: "CSC") do |p|
  p.name = "Computer Science"
  p.degree_type = "B.Sc"
  p.duration_years = 4
end

demo_courses = [
  ["CYB 301", "Introduction to Cybersecurity", 3, 300, 1],
  ["CYB 302", "Cloud Computing", 2, 300, 2],
  ["CSC 305", "Computer Networks", 3, 300, 1],
  ["CSC 307", "Operating Systems", 3, 300, 2],
  ["CSC 309", "Database Systems", 3, 300, 1],
  ["CSC 311", "Software Engineering", 2, 300, 2],
  ["CSC 313", "Web Technologies", 2, 300, 1],
  ["CYB 304", "Information Assurance", 2, 300, 2],
  ["CYB 305", "Digital Forensics", 3, 400, 1],
  ["CSC 315", "Data Structures & Algorithms", 3, 300, 2]
]
demo_courses.each do |code, title, credits, level, sem|
  Academic::Course.find_or_create_by!(programme: prog, code: code) do |c|
    c.title = title
    c.credit_units = credits
    c.level = level
    c.semester = sem
  end
end
puts "demo courses seeded: #{demo_courses.size}"

# --- Demo library resources ---
demo_resources = [
  ["Cybersecurity Lecture Notes", "Dr. A. Bello", "ebook"],
  ["Operating Systems Study Guide", "Prof. C. Eze", "book"],
  ["Networks Past Questions", "ADUN Exam Board", "past_question"],
  ["Database Systems Reference", "O. Ibrahim", "reference"],
  ["Software Engineering Handbook", "J. Okoro", "book"],
  ["Digital Forensics Lab Manual", "M. Abubakar", "ebook"],
  ["Web Technologies Cheat Sheet", "S. Musa", "reference"],
  ["Cloud Computing Overview", "K. Adeyemi", "journal"]
]
demo_resources.each do |title, author, type|
  Library::LibraryResource.find_or_create_by!(university: uni, title: title) do |r|
    r.author = author
    r.resource_type = type
  end
end
puts "demo library resources seeded: #{demo_resources.size}"

puts "SEED COMPLETE"
