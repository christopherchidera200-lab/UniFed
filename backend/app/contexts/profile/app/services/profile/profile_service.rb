module Profile
  # Reads/writes the extended profile. Academic records + digital ID are surfaced
  # via the existing Academic/StudentId contexts; this service composes them.
  class ProfileService
    def self.for_user(user)
      profile = ::Profile::Profile.find_or_initialize_by(user: user)
      {
        id: user.id,
        display_name: user.display_name,
        email: user.email,
        actor_type: user.actor_type,
        bio: profile.bio,
        skills: profile.skills || [],
        portfolio: profile.portfolio || [],
        social_links: profile.social_links || {},
        creator: profile.creator || false,
        academic_summary_url: nil, # populated by frontend via /academic/summary
        university: user.university ? {
          id: user.university.id,
          name: user.university.name,
          short_name: user.university.short_name,
          slug: user.university.slug
        } : nil
      }
    end

    def self.update(user, attrs)
      profile = ::Profile::Profile.find_or_initialize_by(user: user)
      profile.assign_attributes(attrs.slice(:bio, :skills, :portfolio, :social_links, :creator))
      profile.save!
      for_user(user)
    end
  end
end
