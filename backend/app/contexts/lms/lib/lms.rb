# Context loader for the LMS / Assignments bounded context (P0-2).
# Owns Assignment + Submission models and the assignment workflow service.
require_relative "../app/models/lms/assignment"
require_relative "../app/models/lms/submission"
require_relative "../app/services/lms/assignment_service"
