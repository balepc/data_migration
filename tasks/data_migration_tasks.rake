namespace :db do
    namespace :migrate do                
        desc "Migrate structure, data and translations"
        task :all => :environment do
            puts "# CREATING STRUCTURE"
            Rake::Task["db:migrate"].invoke if ActiveRecord::Base.schema_format == :ruby
            
            puts "# MIGRATING DATA"
            Rake::Task["db:migrate:data"].invoke if ActiveRecord::Base.schema_format == :ruby
        end
        
        desc "Migrate data"
        task :data => :environment do
            FileUtils.mkdir('db/data') if not File.exists?('db/data')
            ActiveRecord::Migrator.migrate_data("db/data/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
        end
    end    
end
