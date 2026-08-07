Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Health + readiness probe for K8s.
      get "/healthz", to: proc { [200, {}, ["ok"]] }

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
