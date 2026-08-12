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
puts "SEED COMPLETE"
