require 'bundler/capistrano'
load 'deploy/assets'

set :application, "deploy_test"
set :repository,  "git@github.com:dr-strangecode/deploy_test.git"
set :deploy_to, "/opt/numerex/rails/"

set :scm, :git
set :scn_verbose, true
set :keep_releases, "4"
set :use_sudo, false
set :deploy_via, :copy
set :copy_cache, false
#set :copy_exclude, ['.git']
set :user, 'numerex'

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  desc "Create symlinks for shared image upload directories"
  task :create_symlinks do
    run "ln -fs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end

  namespace :assets do
    task :precompile, :roles => :web, :except => { :no_release => true } do
      from = source.next_revision(current_revision)
      if capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ app/assets/ | wc -l").to_i > 0
        run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile}
      else
        logger.info "Skipping asset pre-compilation because there were no asset changes"
      end
    end
  end

  after 'deploy:update_code', 'deploy:create_symlinks'
end

task :staging do
  set :rails_env, 'staging'
  set :branch, 'staging'
  role :web, "puppet-test.mrpbx.com"                          # Your HTTP server, Apache/etc
  role :app, "puppet-test.mrpbx.com"                          # This may be the same as your `Web` server
  role :db,  "puppet-test.mrpbx.com", :primary => true # This is where Rails migrations will run
end


# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
