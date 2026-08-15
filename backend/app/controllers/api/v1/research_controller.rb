module Api
  module V1
    # Research Hub: profiles, groups, publications, projects.
    # Reads are node-scoped; writes require staff/admin RBAC (research:manage).
    class ResearchController < Api::V1::BaseController
      # GET /api/v1/research/profiles?q=
      def profiles
        list = Research::ResearchService.search_profiles(university: current_university, query: params[:q])
        render json: list.map { |p| profile_json(p) }
      end

      # GET /api/v1/research/groups
      def groups
        list = Research::ResearchService.list_groups(university: current_university)
        render json: list.map { |g| group_json(g) }
      end

      # POST /api/v1/research/groups  (staff/admin)
      def create_group
        return render_forbidden unless current_user&.has_permission?("research:manage")
        group = Research::ResearchService.create_group!(
          university: current_university, leader: current_user,
          attrs: group_params
        )
        render json: group_json(group), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # GET /api/v1/research/groups/:id
      def show_group
        group = Research::ResearchGroup.find_by(id: params[:id], university_id: current_university.id)
        return render json: { error: "not_found" }, status: :not_found unless group
        render json: group_json(group, with_members: true)
      end

      # POST /api/v1/research/groups/:id/members  (staff/admin or group lead)
      def add_member
        group = Research::ResearchGroup.find_by(id: params[:id], university_id: current_university.id)
        return render json: { error: "not_found" }, status: :not_found unless group
        return render_forbidden unless can_manage_group?(group)
        user = Identity::User.find_by(id: params[:user_id])
        return render json: { error: "user_not_found" }, status: :not_found unless user
        membership = Research::ResearchService.add_member!(group: group, user: user)
        render json: { id: membership.id, group_id: group.id, user_id: user.id, role: membership.role }, status: :created
      end

      private

      def can_manage_group?(group)
        return true if current_user&.has_permission?("research:manage")
        return true if group.lead_id == current_user&.id
        false
      end

      def group_params
        params.require(:group).permit(:name, :description)
      end

      def profile_json(p)
        { id: p.id, user_id: p.user_id, title: p.title, bio: p.bio, orcid: p.orcid,
          research_fields: p.research_fields, citations_count: p.citations_count }
      end

      def group_json(g, with_members: false)
        h = { id: g.id, name: g.name, description: g.description, lead_id: g.lead_id }
        h[:member_ids] = g.memberships.pluck(:user_id) if with_members
        h
      end
    end
  end
end
