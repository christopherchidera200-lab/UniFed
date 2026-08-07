# Puma production config (K8s). Tuned for Rails 7 + jemalloc.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }.to_i
threads min_threads_count, max_threads_count

port ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }

# Preload in production for faster worker boot.
preload_app!

plugin :tmp_restart

# 30s graceful shutdown (K8s SIGTERM).
worker_timeout 30
