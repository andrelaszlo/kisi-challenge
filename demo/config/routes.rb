Rails.application.routes.draw do
  get 'demo/index'
  get 'demo/start_job(/:num_jobs)', to: 'demo#start_job', defaults: { num_jobs: '1' }
  root 'demo#index'
end
