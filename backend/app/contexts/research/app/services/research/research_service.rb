module Research
  # Research Hub service: profiles, groups, memberships, publications, projects.
  # Node-scoped to the requesting university; writes require staff/admin RBAC.
  class ResearchService
    class << self
      # --- Profiles ---
      def upsert_profile!(user:, university:, attrs:)
        profile = ResearchProfile.find_or_initialize_by(user_id: user.id, university_id: university.id)
        profile.update!(attrs.merge(university_id: university.id))
        profile
      end

      def search_profiles(university:, query: nil)
        scope = ResearchProfile.where(university_id: university.id)
        scope = scope.where("title ILIKE ? OR bio ILIKE ?", "%#{query}%", "%#{query}%") if query.present?
        scope.order(citations_count: :desc)
      end

      # --- Groups ---
      def create_group!(university:, leader:, attrs:)
        group = ResearchGroup.new(attrs.merge(university_id: university.id, lead_id: leader&.id))
        group.save!
        if leader
          GroupMembership.find_or_create_by!(group: group, user_id: leader.id) do |m|
            m.role = "lead"
          end
        end
        group
      end

      def list_groups(university:)
        ResearchGroup.where(university_id: university.id).order(:name)
      end

      def add_member!(group:, user:)
        GroupMembership.find_or_create_by!(group: group, user_id: user.id) do |m|
          m.role = "member"
        end
      end

      # --- Publications ---
      def create_publication!(university:, attrs:)
        Publication.create!(attrs.merge(university_id: university.id))
      end

      def list_publications(university:, group_id: nil, profile_id: nil)
        scope = Publication.where(university_id: university.id)
        scope = scope.where(group_id: group_id) if group_id.present?
        scope = scope.where(profile_id: profile_id) if profile_id.present?
        scope.order(year: :desc)
      end

      # --- Projects ---
      def create_project!(group:, attrs:)
        ResearchProject.create!(attrs.merge(group_id: group.id, university_id: group.university_id))
      end

      def list_projects(university:, group_id: nil)
        scope = ResearchProject.where(university_id: university.id)
        scope = scope.where(group_id: group_id) if group_id.present?
        scope.order(created_at: :desc)
      end
    end
  end
end
