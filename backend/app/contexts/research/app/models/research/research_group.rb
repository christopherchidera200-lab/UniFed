module Research
  # A university research group/lab with members and outputs.
  class ResearchGroup < ::ApplicationRecord
    self.table_name = "research_groups"
    belongs_to :university, class_name: "Academic::University"
    belongs_to :lead, class_name: "Identity::User", optional: true
    has_many :memberships, class_name: "Research::GroupMembership", dependent: :destroy
    has_many :members, through: :memberships, source: :user
    has_many :publications, class_name: "Research::Publication", dependent: :nullify
    has_many :projects, class_name: "Research::ResearchProject", dependent: :destroy

    validates :name, presence: true
  end
end
