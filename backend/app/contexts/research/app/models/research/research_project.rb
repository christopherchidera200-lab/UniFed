module Research
  # A research project run by a group. Status is operator-managed (no auto-state machine).
  class ResearchProject < ::ApplicationRecord
    self.table_name = "research_projects"
    belongs_to :group, class_name: "Research::ResearchGroup"
    belongs_to :university, class_name: "Academic::University"

    validates :title, presence: true
    validates :status, inclusion: { in: %w[active completed archived] }
  end
end
