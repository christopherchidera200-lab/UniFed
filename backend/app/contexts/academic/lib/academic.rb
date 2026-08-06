# Context loader for the Academic bounded context.
# Explicitly requires models + services so the Academic:: namespace is
# always available (deterministic, no reliance on Zeitwerk path mapping
# for the nested app/contexts structure).
require_relative "../../models/university"
require_relative "../../models/faculty"
require_relative "../../models/department"
require_relative "../../models/programme"
require_relative "../../models/course"
require_relative "../../models/academic_session"
require_relative "../../models/semester"
require_relative "../../models/lecturer"
require_relative "../../models/student"
require_relative "../../models/student_enrollment"
require_relative "../../models/course_offering"
