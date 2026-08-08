Rails.application.routes.draw do
  # ---- Phase 0 hardening: Observability ----
  get "metrics", to: "metrics#show"

  # ---- Phase 0 hardening: OIDC issuer (root scope, not under /api/v1) ----
  get ".well-known/openid-configuration", to: "oidc#configuration"
  get ".well-known/jwks.json", to: "oidc#jwks"
  post "oauth/token", to: "oidc#token"
  get  "oauth/userinfo", to: "oidc#userinfo"

  namespace :api do
    namespace :v1 do
      # Health + readiness probe for K8s.
      get "/healthz", to: proc { [200, {}, ["ok"]] }

      # Phase 0 — Identity / Auth
      post "auth/login", to: "auth#login"
      post "auth/mfa/verify", to: "auth#mfa_verify"
      post "auth/refresh", to: "auth#refresh"
      post "auth/logout", to: "auth#logout"

      resources :mfa, only: [] do
        collection do
          post "totp/begin", to: "mfa#totp_begin"
          post "totp/confirm", to: "mfa#totp_confirm"
          get  "devices", to: "mfa#devices"
        end
      end

      resources :roles, only: %i[index] do
        collection do
          post "assign", to: "roles#assign"
          post "revoke", to: "roles#revoke"
          get  "audit", to: "roles#audit"
        end
      end

      resources :consent, only: %i[index create]

      # Academic Records (existing slice)
      resources :academic, only: [] do
        member do
          get "students/:id", to: "academic_records#show", as: :student
          get "students/:id/records", to: "academic_records#records", as: :student_records
          get "students/:id/summary", to: "academic_records#summary", as: :student_summary
          post "students/:id/transcript", to: "academic_records#transcript", as: :student_transcript
        end
      end

      # Public transcript verification (signed JWT, verified against JWKS).
      post "transcript/verify", to: "academic_records#verify_transcript"

      post "student-id/:student_id/issue", to: "student_ids#issue"
      post "student-id/verify", to: "student_ids#verify"

      # Phase 1 — Federation (ActivityPub)
      get ".well-known/webfinger", to: "federation#webfinger"
      post "federation/inbox", to: "federation#inbox"
      get  "federation/outbox", to: "federation#outbox"

      # Phase 1 — Social (Home / feed)
      resources :feed, only: [:index] do
        collection do
          post "posts", to: "feed#create"
          post "posts/:id/react", to: "feed#react"
          post "posts/:id/comments", to: "feed#comment"
        end
      end

      # Phase 1 — Discover (Search)
      resources :search, only: [:index] do
        collection do
          post "saved", to: "search#save"
        end
      end

      # Phase 1 — Profile
      resource :profile, only: %i[show update]

      # Phase 2 — Course Catalogue (browse)
      resources :catalog, only: [] do
        collection do
          get "courses", to: "catalog#courses"
          get "offerings", to: "catalog#offerings"
        end
      end

      # Phase 2 — Event Calendar
      resources :calendar, only: [] do
        collection do
          get "events", to: "calendar#events"
        end
      end

      # Phase 2 — SIWES / Internship tracking
      resources :siwes, only: [] do
        collection do
          post "placement", to: "siwes#placement"
          post "logs", to: "siwes#logs"
          post "logs/:id/verify", to: "siwes#verify_log"
          get  "completion", to: "siwes#completion"
        end
      end

      # Phase 2 — Assessments (record + rollup)
      resources :assessments, only: [] do
        collection do
          post "record", to: "assessments#record"
          post "rollup", to: "assessments#rollup"
        end
      end

      # Phase 2 depth — Library
      resources :library, only: [] do
        collection do
          get  "resources", to: "library#resources"
          post "borrow", to: "library#borrow"
          post "return", to: "library#return_resource"
        end
      end

      # Phase 2 depth — Notifications
      resources :notifications, only: [:index] do
        collection do
          post ":id/read", to: "notifications#read", as: :read
        end
      end

      # Phase 2 depth — Examinations (scheduling)
      resources :examinations, only: [:index]

      # Phase 2 — Career Hub
      resources :career, only: [] do
        collection do
          get  "opportunities", to: "career#opportunities"
          get  "recommendations", to: "career#recommendations"
          get  "applications", to: "career#applications"
          post "opportunities/:id/apply", to: "career#apply"
          post "opportunities/:id/save", to: "career#save_job"
        end
      end
    end
  end
end
