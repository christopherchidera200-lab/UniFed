module Identity
  # Self-service account registration (product-readiness task). Integrates with
  # the existing Identity context: Argon2 password hashing, per-university unique
  # email/username, and SERVER-SIDE role assignment. Clients can never request a
  # role — only a base "member" role is auto-assigned, plus an optional "student"
  # linkage when a valid, unclaimed matric number is supplied. Admin/staff roles
  # are never grantable through this endpoint.
  class RegistrationService
    PASSWORD_POLICY = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{8,}\z/

    Result = Struct.new(:ok, :user, :tokens, :reason, :status, keyword_init: true) do
      def success? = ok == true
      def failure? = !success?
    end

    def self.register(params:, ip:, user_agent:)
      university = Academic::University.find_by(id: UniFed::Application.config.x.node_university_id)
      return Result.new(ok: false, reason: "node_not_configured", status: :service_unavailable) unless university

      display_name = (params[:name] || params[:display_name]).to_s.strip
      email       = params[:email].to_s.strip.downcase
      password    = params[:password].to_s
      matric_no   = params[:matric_no].to_s.strip

      # --- Input validation (safe, explicit; no role params accepted) ---
      return Result.new(ok: false, reason: "name_required", status: :unprocessable_entity) if display_name.blank?
      return Result.new(ok: false, reason: "email_required", status: :unprocessable_entity) unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return Result.new(ok: false, reason: "password_too_weak", status: :unprocessable_entity) unless password.match?(PASSWORD_POLICY)

      if Identity::User.exists?(university: university, email: email)
        return Result.new(ok: false, reason: "email_taken", status: :conflict)
      end

      user = nil
      ActiveRecord::Base.transaction do
        username = derive_username(university, email)
        user = Identity::User.create!(
          university: university,
          email: email,
          username: username,
          display_name: display_name,
          actor_type: "student",
          status: "active"
        )
        user.credentials.create!(
          kind: "password",
          secret_enc: Identity::Credential.hash_password(password)
        )
        assign_member_role(user, university)
      end

      # Best-effort student linkage (non-fatal). Never assigns privileged roles.
      link_student_if_valid(user, university, matric_no) if matric_no.present?

      AuditService.log!(
        action: "auth.register", actor_type: "user", actor_id: user.id,
        university_id: university.id, ip: ip,
        meta: { result: "created", student_linked: user.student? }
      )

      tokens = PasswordAuthService.success(user, ip, user_agent).tokens
      Result.new(ok: true, user: user, tokens: tokens, status: :created)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(ok: false, reason: e.record.errors.full_messages.join(", "), status: :unprocessable_entity)
    end

    def self.derive_username(university, email)
      base = email.split("@").first.to_s.downcase.gsub(/[^a-z0-9_]/, "")[0, 24].presence || "user"
      candidate = base
      n = 0
      while Identity::User.exists?(university: university, username: candidate)
        n += 1
        candidate = "#{base}#{n}"
      end
      candidate
    end

    def self.assign_member_role(user, university)
      member = Identity::Role.find_or_create_by!(university_id: university.id, name: "member") do |r|
        r.permissions = []
      end
      user.role_assignments.find_or_create_by!(role: member, scope_type: "university")
    end

    def self.link_student_if_valid(user, university, matric_no)
      return unless university.valid_matric?(matric_no)
      return if Academic::Student.exists?(university: university, matric_no: matric_no)

      student = Academic::Student.find_or_initialize_by(university: university, matric_no: matric_no)
      return if student.persisted?

      student.assign_attributes(
        identity_subject: user.id,
        entry_year: Date.current.year,
        entry_mode: "UTME",
        current_level: 100,
        status: "active"
      )
      student.save!
      student_role = Identity::Role.find_or_create_by!(university_id: university.id, name: "student") do |r|
        r.permissions = ["academic:read"]
      end
      user.update!(actor_type: "student")
      user.role_assignments.find_or_create_by!(role: student_role, scope_type: "university")
    rescue ActiveRecord::RecordInvalid
      nil # non-fatal: identity still created with member role
    end
  end
end
