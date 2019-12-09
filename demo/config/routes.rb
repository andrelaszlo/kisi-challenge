Rails.application.routes.draw do
  get 'demo/index'
  get 'demo/delayed_job'
  get 'demo/fail_job'
  get 'demo/start_job(/:num_jobs)', to: 'demo#start_job', defaults: { num_jobs: '1' }
  root 'demo#index'
end
