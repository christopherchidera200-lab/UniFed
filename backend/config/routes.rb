Rails.application.routes.draw do
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
        end
      end

      post "student-id/:student_id/issue", to: "student_ids#issue"
      post "student-id/verify", to: "student_ids#verify"
    end
  end
end
