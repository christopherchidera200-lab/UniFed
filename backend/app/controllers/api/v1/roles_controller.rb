module Api
  module V1
    # RBAC role assignment + audit log read (Phase 0). Admin-scoped.
    class RolesController < BaseController
      before_action :authenticate!
      before_action :require_permission, only: %i[assign revoke index audit]

      # GET /api/v1/roles  (admin)
      def index
        roles = Identity::Role.where(university: current_university)
        render json: roles.select(:id, :name, :permissions)
      end

      # POST /api/v1/roles/assign  {user_id, role, scope_type?, scope_id?}
      def assign
        target = Identity::User.find_by(id: params.dig(:user_id), university: current_university)
        return render json: { error: "not_found" }, status: :not_found unless target
        role = Identity::RoleService.assign(user: target, role_name: params.dig(:role),
          scope_type: params.dig(:scope_type) || "university", scope_id: params.dig(:scope_id))
        return render json: { error: "unknown_role" }, status: :unprocessable_entity unless role
        Identity::AuditService.log!(action: "rbac.assign", actor_type: "admin",
          actor_id: current_subject, university_id: current_university&.id,
          meta: { target: target.id, role: role.name })
        render json: { ok: true, role: role.name }, status: :ok
      end

      # POST /api/v1/roles/revoke  {user_id, role, scope_type?, scope_id?}
      def revoke
        target = Identity::User.find_by(id: params.dig(:user_id), university: current_university)
        return render json: { error: "not_found" }, status: :not_found unless target
        ok = Identity::RoleService.revoke(user: target, role_name: params.dig(:role),
          scope_type: params.dig(:scope_type) || "university", scope_id: params.dig(:scope_id))
        render json: { ok: ok }, status: ok ? :ok : :unprocessable_entity
      end

      # GET /api/v1/audit  (admin) — security/compliance trail
      def audit
        logs = Identity::AuditLog.where(university: current_university)
          .order(created_at: :desc).limit(params.dig(:limit) || 100)
        render json: logs.select(:id, :action, :actor_type, :actor_id, :ip, :meta, :created_at)
      end
    end
  end
end
