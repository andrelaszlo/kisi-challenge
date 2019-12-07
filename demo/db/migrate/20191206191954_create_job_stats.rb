class CreateJobStats < ActiveRecord::Migration[6.0]
  def change
    create_table :job_stats do |t|
      t.integer :job_count
      t.float :job_time
      t.integer :jobs_enqueued
      t.integer :best_hash_count
      t.string :best_hash_str
      t.string :best_hash_hash

      t.timestamps
    end
  end
end
