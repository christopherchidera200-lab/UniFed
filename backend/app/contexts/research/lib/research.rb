# Context loader for the Research Hub bounded context (P0-3).
# Owns profiles, groups, memberships, publications, projects + the research service.
require_relative "../app/models/research/research_profile"
require_relative "../app/models/research/research_group"
require_relative "../app/models/research/group_membership"
require_relative "../app/models/research/publication"
require_relative "../app/models/research/research_project"
require_relative "../app/services/research/research_service"
