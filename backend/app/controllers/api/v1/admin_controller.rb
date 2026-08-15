module Api
  module V1
    # Administration portal endpoints (Phase 2 depth). RBAC-guarded node
    # administration over existing contexts. All actions require an
    # admin-scoped permission; no self-service or federation exposure.
    class AdminController < Api::V1::BaseController
      # GET /api/v1/admin/users?q=&role=  (admin:users)
      def users
        return render_forbidden unless current_user&.has_permission?("admin:users") || current_user&.admin?
        scope = Identity::User.where(university: current_university)
        scope = scope.where("email ILIKE ? OR username ILIKE ? OR display_name ILIKE ?",
                            "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
        if params[:role].present?
          scope = scope.joins(:role_assignments).where(role_assignments: { role_id: Identity::Role.where(name: params[:role], university_id: current_university.id).select(:id) })
        end
        page = [params[:page].to_i, 1].max
        per = [[params[:per].to_i, 50].min, 1].max
        results = scope.order(created_at: :desc).offset((page - 1) * per).limit(per)
        render json: {
          users: results.map { |u| user_json(u) },
          total: scope.count
        }
      end

      # GET /api/v1/admin/stats  (admin:users)
      def stats
        return render_forbidden unless current_user&.has_permission?("admin:users") || current_user&.admin?
        render json: {
          users: Identity::User.where(university: current_university).count,
          roles: Identity::Role.where(university_id: current_university.id).count,
          research_groups: Research::ResearchGroup.where(university_id: current_university.id).count,
          campus_places: Campus::Place.where(university_id: current_university.id).count,
          assignments: Lms::Assignment.where(lecturer_id: Academic::Lecturer.where(university_id: current_university.id).select(:id)).count
        }
      end

      # POST /api/v1/admin/users/:id/roles  {role, scope_type?, scope_id?}  (admin:users)
      def assign_role
        return render_forbidden unless current_user&.has_permission?("admin:users") || current_user&.admin?
        target = Identity::User.find_by(id: params[:id], university: current_university)
        return render json: { error: "not_found" }, status: :not_found unless target
        role = Identity::RoleService.assign(
          user: target, role_name: params.dig(:role),
          scope_type: params.dig(:scope_type) || "university", scope_id: params.dig(:scope_id)
        )
        return render json: { error: "unknown_role" }, status: :unprocessable_entity unless role
        render json: { ok: true, role: role.name }, status: :ok
      end

      private

      def user_json(u)
        {
          id: u.id, email: u.email, username: u.username, display_name: u.display_name,
          actor_type: u.actor_type, status: u.status,
          roles: u.roles.where(university_id: current_university.id).pluck(:name)
        }
      end
    end
  end
end
