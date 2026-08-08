module Records
  # Assembles a student's published academic record into a signed, verifiable
  # transcript (JWT, RS256) that a third party can verify against the
  # university's JWKS. Includes per-course results + cumulative CGPA/class.
  class TranscriptService
    # Build the transcript payload (unsigned claims) for a student.
    def self.build_payload(student)
      published = Records::GradeRecord.published_for(student)
                     .joins(course_offering: { course: :programme })
                     .includes(course_offering: { course: :programme })
                     .order("courses.level", "courses.code")

      cum = student.academic_summaries.find_by(academic_session_id: nil)
      {
        sub: student.id,
        matric_no: student.matric_no,
        university: student.university&.slug,
        issued_at: Time.current.iso8601,
        cgpa: cum&.cgpa,
        total_credits: cum&.total_credits,
        class_of_degree: cum&.class_of_degree,
        results: published.map do |g|
          {
            code: g.course_offering.course.code,
            title: g.course_offering.course.title,
            credit_units: g.course_offering.course.credit_units,
            score: g.score,
            grade: g.grade_letter,
            grade_point: g.grade_point,
            semester: g.course_offering.semester_number
          }
        end
      }
    end

    # Sign the transcript as a JWT (RS256) using the OIDC signing key.
    def self.issue_signed(student)
      payload = build_payload(student)
      key = Identity::OidcKeyService.private_key
      JWT.encode(payload, key, "RS256")
    end

    # Verify a transcript JWT against the university public key.
    def self.verify(token)
      key = Identity::OidcKeyService.public_key
      JWT.decode(token, key, true, algorithm: "RS256").first
    rescue JWT::DecodeError => e
      { error: e.message }
    end
  end
end
