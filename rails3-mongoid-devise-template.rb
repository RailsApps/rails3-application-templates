# Application Generator Template
# Modifies a Rails app to use Mongoid and Devise
# Usage: rails new APP_NAME -m https://github.com/fortuity/rails3-application-templates/raw/master/rails3-mongoid-devise-template.rb

# Information and a tutorial: 
# http://github.com/fortuity/rails3-mongoid-devise/

# More application template recipes:
# https://github.com/fortuity/rails-template-recipes/

# Based on application template recipes by:
# Michael Bleigh https://github.com/mbleigh
# Fletcher Nichol https://github.com/fnichol
# Daniel Kehoe https://github.com/fortuity
# Ramon Brooker https://github.com/cognition

# If you are customizing this template, you can use any methods provided by Thor::Actions
# http://rdoc.info/rdoc/wycats/thor/blob/f939a3e8a854616784cac1dcff04ef4f3ee5f7ff/Thor/Actions.html
# and Rails::Generators::Actions
# http://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb

# >----------------------------[ initial setup ]------------------------------<

# for pretty printing while the script is running
def say_recipe(name); say "\033[36m" + "recipe".rjust(10) + "\033[0m" + "    Running #{name} recipe..." end
def say_wizard(text); say "\033[36m" + "wizard".rjust(10) + "\033[0m" + "    #{text}" end

# implement a script technique that allows recipes to specify gems 
# and then blocks of code that run only after gems are installed
@after_blocks = []
def after_bundler(&block); @after_blocks << block; end

say_wizard "Modifying a new Rails app to use Mongoid and Devise..."
say_wizard "Any problems? See http://github.com/fortuity/rails3-mongoid-devise/issues"

# >--------------------------------[ configure ]---------------------------------<

recipes = %w{ git 
  mongoid rspec cucumber jquery haml devise heroku yard 
  action_mailer add_user_name 
  home_page home_page_users seed_database users_page 
  css_setup application_layout devise_navigation 
  cleanup ban_spiders }

if no?('Would you like to use RSpec instead of TestUnit? (yes/no)')
  recipes.delete('rspec')
end

if no?('Would you like to use Cucumber for your BDD? (yes/no)')
  recipes.delete('cucumber')
end

if no?('Would you like to use jQuery instead of Prototype? (yes/no)')
  recipes.delete('jquery')
end

if no?('Would you like to use the Haml template system? (yes/no)')
  recipes.delete('haml')
end

if no?('Do you want to install the Heroku gem so you can deploy to Heroku? (yes/no)')
  recipes.delete('heroku')
end

if no?('Would you like to use Yard instead of RDoc? (yes/no)')
  recipes.delete('yard')
end

# >--------------------------------[ Git ]---------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/git.rb

# Set up Git for version control
say_recipe 'Git'

# Git should ignore some files
remove_file '.gitignore'
get "https://github.com/fortuity/rails-template-recipes/raw/master/gitignore.txt", ".gitignore"

# Initialize new Git repo
git :init
git :add => '.'
git :commit => "-aqm 'Initial commit of new Rails app'"

say_wizard "Creating a git working_branch (to follow the stream of development)."
git :checkout => ' -b working_branch'
git :add => '.'
git :commit => "-m 'Initial commit of working_branch (to establish a clean base line).'"

# >--------------------------------[ mongoid ]--------------------------------<

# Utilize MongoDB with Mongoid as the ORM.

if recipes.include? 'mongoid'

  say_recipe 'Mongoid'

  gem 'mongoid', '>= 2.0.0.rc.7'
  gem 'bson_ext', '>= 1.2.4'

  # modifying 'config/application.rb' file to remove ActiveRecord dependency
  gsub_file 'config/application.rb', /require 'rails\/all'/ do
  <<-RUBY
  require 'action_controller/railtie'
  require 'action_mailer/railtie'
  require 'active_resource/railtie'
  require 'rails/test_unit/railtie'
  RUBY
  end

  # remove unnecessary 'config/database.yml' file
  remove_file 'config/database.yml'
  
  #----------------------------------------------------------------------------
  # Resolve issue 17: https://github.com/fortuity/rails3-mongoid-devise/issues#issue/17
  # Change YAML Engine to accommodate Ruby 1.9.2p180 yaml parser problem.
  # Rubygems 1.5.0 changes the yaml parsing default from syck 
  # to psych and psych doesn't like the ":<<" in yaml files
  # http://groups.google.com/group/mongoid/browse_thread/thread/9213a17a73d3c422
  # http://redmine.ruby-lang.org/issues/show/4300
  #----------------------------------------------------------------------------                         
  inject_into_file 'config/environment.rb', "\nrequire 'yaml'\nYAML::ENGINE.yamler= 'syck'\n", :after => "require File.expand_path('../application', __FILE__)", :verbose => false

  # generate mongoid configuration
  after_bundler do
    generate 'mongoid:config'
  end

  if recipes.include? 'git'
    git :tag => "mongoid_installation"
    git :add => '.'
    git :commit => "-am 'Mongoid installation.'"
  end

end

# >--------------------------------[ jQuery ]---------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/jquery.rb

# Utilize the jQuery Javascript framework instead of Protoype.

if recipes.include? 'jquery'
  
  # Adds the latest jQuery and Rails UJS helpers for jQuery.
  say_recipe 'jQuery'

  # remove the Prototype adapter file
  remove_file 'public/javascripts/rails.js'
  # add jQuery files
  inside "public/javascripts" do
    get "https://github.com/rails/jquery-ujs/raw/master/src/rails.js", "rails.js"
    get "http://code.jquery.com/jquery-1.5.min.js", "jquery.js"
  end
  # adjust the Javascript defaults
  inject_into_file 'config/application.rb', "config.action_view.javascript_expansions[:defaults] = %w(jquery rails)\n", :after => "config.action_view.javascript_expansions[:defaults] = %w()\n", :verbose => false
  gsub_file "config/application.rb", /config.action_view.javascript_expansions\[:defaults\] = \%w\(\)\n/, ""
  
  if recipes.include? 'git'
    git :tag => "jquery_installation"
    git :add => '.'
    git :commit => "-am 'jQuery installation.'"
  end
  
end

# >---------------------------------[ Haml ]----------------------------------<

if recipes.include? 'haml'
  
  # Utilize HAML for templating.
  say_recipe 'HAML'

  gem 'haml', '>= 3.0.0'
  gem 'haml-rails'

  if recipes.include? 'git'
    git :tag => "haml_installation"
    git :add => '.'
    git :commit => "-am 'Haml installation.'"
  end

end

# >---------------------------------[ RSpec ]---------------------------------<

if recipes.include? 'rspec'

  # Use RSpec instead of TestUnit
  say_recipe 'RSpec'

  gem 'rspec-rails', '>= 2.5', :group => [:development, :test]
  gem 'database_cleaner', :group => :test

# create a generator configuration file (only used for the RSpec recipe)
  initializer 'generators.rb', <<-RUBY
Rails.application.config.generators do |g|
    g.test_framework = :rspec
end
RUBY

  gsub_file 'config/application.rb', /require \'rails\/test_unit\/railtie\' ./, ""
  say_wizard "Removing test folder (not needed for RSpec)"
  run 'rm -rf test/'

  after_bundler do

    generate 'rspec:install'

    # remove ActiveRecord artifacts
    gsub_file 'spec/spec_helper.rb', /config.fixture_path/, '# config.fixture_path'
    gsub_file 'spec/spec_helper.rb', /config.use_transactional_fixtures/, '# config.use_transactional_fixtures'

    # reset your application database to a pristine state during testing
    inject_into_file 'spec/spec_helper.rb', :before => "\nend" do
    <<-RUBY
  \n
  # Clean up the database
  require 'database_cleaner'
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.orm = "mongoid"
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end
RUBY
    end

    if recipes.include? 'git'
      git :tag => "rspec_installation"
      git :add => '.'
      git :commit => "-am 'Installed RSpec.'"
    end

  end

end

# >-------------------------------[ Cucumber ]--------------------------------<

if recipes.include? 'cucumber'
  
  # Use Cucumber for integration testing with Capybara.
  say_recipe 'Cucumber'

  gem 'cucumber-rails', :group => :test
  gem 'capybara', :group => :test

  after_bundler do
    generate "cucumber:install --capybara#{' --rspec' if recipes.include?('rspec')}#{' -D' unless recipes.include?('activerecord')}"

    # reset your application database to a pristine state during testing
    create_file 'features/support/local_env.rb' do 
    <<-RUBY
require 'database_cleaner'
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.orm = "mongoid"
Before { DatabaseCleaner.clean }
RUBY
    end
  
    if recipes.include? 'git'
      git :tag => "cucumber_installation"
      git :add => '.'
      git :commit => "-am 'Installed Cucumber.'"
    end

  end

end

# >-------------------------------[ Cucumber Scenarios ]--------------------------------<

if recipes.include? 'cucumber'
  
  say_recipe 'Cucumber Scenarios'

  after_bundler do

    # copy all the Cucumber scenario files from the rails3-mongoid-devise example app
    inside 'features' do
      get 'https://github.com/fortuity/rails3-mongoid-devise/raw/master/features/sign_in.feature', 'sign_in.feature'
      get 'https://github.com/fortuity/rails3-mongoid-devise/raw/master/features/sign_out.feature', 'sign_out.feature'
      get 'https://github.com/fortuity/rails3-mongoid-devise/raw/master/features/sign_up.feature', 'sign_up.feature'
    end
    inside 'features/step_definitions' do
      get 'https://github.com/fortuity/rails3-mongoid-devise/raw/master/features/step_definitions/sign_in_steps.rb', 'sign_in_steps.rb'
      get 'https://github.com/fortuity/rails3-mongoid-devise/raw/master/features/step_definitions/sign_out_steps.rb', 'sign_out_steps.rb'
      get 'https://github.com/fortuity/rails3-mongoid-devise/raw/master/features/step_definitions/sign_up_steps.rb', 'sign_up_steps.rb'
    end
    remove_file 'features/support/paths.rb'
    inside 'features/support' do
      get 'https://github.com/fortuity/rails3-mongoid-devise/raw/master/features/support/paths.rb', 'paths.rb'
    end
    
    if recipes.include? 'git'
      git :tag => 'cucumber_scenarios'
      git :add => '.'
      git :commit => "-am 'Installed Cucumber Scenarios.'"
    end

  end

end

# >---------------------------------[ Yard ]----------------------------------<

if recipes.include? 'yard'
  
  say_recipe 'yard'
  
  gem 'yard', :group => [:development, :test] 
  gem 'yardstick', :group => [:development, :test]
  
  run 'rm -rf /doc/'
  say_wizard "generating a .yardopts file for yardoc configuration"
  file '.yardopts',<<-RUBY
## --use-cache
--title "Rails 3 with Devise on MongoDB"
app/**/*.rb 
config/routes.rb 
lib/**/*.rb 
README.textile
spec/
--exclude README.md --exclude LICENSE
RUBY

  after_bundler do
    
    run 'yardoc'
    
    if recipes.include? 'git'
      git :tag => "yard_installation"
      git :add => '.'
      git :commit => "-am 'Installed Yard as an alternative to RDoc.'"
    end
    
  end
  
end

# >--------------------------------[ action_mailer ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/action_mailer.rb

say_recipe 'ActionMailer configuration'

# modifying environment configuration files for ActionMailer
gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '# ActionMailer Config'
gsub_file 'config/environments/development.rb', /config.action_mailer.raise_delivery_errors = false/ do
<<-RUBY
config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  # A dummy setup for development - no deliveries, but logged
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"
RUBY
end
gsub_file 'config/environments/production.rb', /config.active_support.deprecation = :notify/ do
<<-RUBY
config.active_support.deprecation = :notify

  config.action_mailer.default_url_options = { :host => 'yourhost.com' }
  # ActionMailer Config
  # Setup for production - deliveries, no errors raised
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default :charset => "utf-8"
RUBY
end

if recipes.include? 'git'
  git :tag => "ActionMailer_config"
  git :add => '.'
  git :commit => "-am 'Set ActionMailer configuration.'"
end

# >--------------------------------[ Devise ]---------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/devise.rb

# Utilize Devise for authentication, automatically configured for your selected ORM.
say_recipe 'Devise'

gem "devise", ">= 1.2.rc"

after_bundler do

  #----------------------------------------------------------------------------
  # Run the Devise generator
  #----------------------------------------------------------------------------
  generate 'devise:install'

  if recipes.include? 'mongo_mapper'
    gem 'mm-devise'
    gsub_file 'config/initializers/devise.rb', 'devise/orm/active_record', 'devise/orm/mongo_mapper_active_model'
  elsif recipes.include? 'mongoid'
    # Nothing to do (Devise changes its initializer automatically when Mongoid is detected)
    # gsub_file 'config/initializers/devise.rb', 'devise/orm/active_record', 'devise/orm/mongoid'
  elsif recipes.include? 'active_record'
    # Nothing to do
  else
    # Nothing to do
  end

  #----------------------------------------------------------------------------
  # Prevent logging of password_confirmation
  #----------------------------------------------------------------------------
  gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'

  #----------------------------------------------------------------------------
  # Generate models and routes for a User
  #----------------------------------------------------------------------------
  generate 'devise user'

  if recipes.include? 'git'
    git :tag => "devise_installation"
    git :add => '.'
    git :commit => "-am 'Added Devise for authentication.'"
  end

end

# >--------------------------------[ add_user_name ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/add_user_name.rb

# There is Haml code in this script. Changing the indentation is perilous between HAMLs.

say_recipe 'add_user_name'

if recipes.include? 'haml'
  # the following gems are required to generate Devise views for Haml
  gem 'hpricot', :group => :development
  gem 'ruby_parser', :group => :development
end

after_bundler do
   
  #----------------------------------------------------------------------------
  # Add a 'name' attribute to the User model
  #----------------------------------------------------------------------------
  if recipes.include? 'mongoid'
    gsub_file 'app/models/user.rb', /end/ do
  <<-RUBY
  field :name
  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
end
RUBY
    end
  elsif recipes.include? 'mongo_mapper'
    # Using MongoMapper? Create an issue, suggest some code, and I'll add it
  elsif recipes.include? 'active_record'
    gsub_file 'app/models/user.rb', /end/ do
  <<-RUBY
  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
end
RUBY
    end
  else
    # Placeholder for some other ORM
  end
  
  if recipes.include? 'git'
    git :tag => "add_user_name"
    git :add => '.'
    git :commit => "-am 'Add a name attribute to the User model.'"
  end

  if recipes.include? 'devise'
    #----------------------------------------------------------------------------
    # Generate Devise views
    #----------------------------------------------------------------------------
    run 'rails generate devise:views'

    #----------------------------------------------------------------------------
    # Modify Devise views to add 'name'
    #----------------------------------------------------------------------------
    if recipes.include? 'haml'
       inject_into_file "app/views/devise/registrations/edit.html.haml", :after => "= devise_error_messages!\n" do
  <<-HAML
  %p
    = f.label :name
    %br/
    = f.text_field :name
HAML
       end
    else
       inject_into_file "app/views/devise/registrations/edit.html.erb", :after => "<%= devise_error_messages! %>\n" do
  <<-ERB
  <p><%= f.label :name %><br />
  <%= f.text_field :name %></p>
ERB
       end
    end

    if recipes.include? 'haml'
       inject_into_file "app/views/devise/registrations/new.html.haml", :after => "= devise_error_messages!\n" do
  <<-HAML
  %p
    = f.label :name
    %br/
    = f.text_field :name
HAML
       end
    else
       inject_into_file "app/views/devise/registrations/new.html.erb", :after => "<%= devise_error_messages! %>\n" do
  <<-ERB
  <p><%= f.label :name %><br />
  <%= f.text_field :name %></p>
ERB
       end
    end
    
    if recipes.include? 'git'
      git :tag => "devise_views"
      git :add => '.'
      git :commit => "-am 'Generate and modify Devise views.'"
    end
    
  end
  
end

# >--------------------------------[ home_page ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/home_page.rb

# There is Haml code in this script. Changing the indentation is perilous between HAMLs.

say_recipe 'Home Page'

after_bundler do
  
  # remove the default home page
  remove_file 'public/index.html'
  
  # create a home controller and view
  generate(:controller, "home index")

  # set up a simple home page (with placeholder content)
  if recipes.include? 'haml'
    remove_file 'app/views/home/index.html.haml'
    # we have to use single-quote-style-heredoc to avoid interpolation
    create_file 'app/views/home/index.html.haml' do 
    <<-'HAML'
%h3 Home
HAML
    end
  else
    remove_file 'app/views/home/index.html.erb'
    create_file 'app/views/home/index.html.erb' do <<-ERB
<h3>Home</h3>
ERB
    end
  end

  # set routes
  gsub_file 'config/routes.rb', /get \"home\/index\"/, 'root :to => "home#index"'

  if recipes.include? 'git'
    git :tag => "home_page"
    git :add => '.'
    git :commit => "-am 'Create a home controller and view.'"
  end

end

# >--------------------------------[ home_page_users ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/home_page_users.rb

# There is Haml code in this script. Changing the indentation is perilous between HAMLs.

say_recipe 'Home Page Showing Users'

after_bundler do

  if recipes.include? 'devise'

    #----------------------------------------------------------------------------
    # Modify the home controller
    #----------------------------------------------------------------------------
    gsub_file 'app/controllers/home_controller.rb', /def index/ do
    <<-RUBY
def index
  @users = User.all
RUBY
    end

    #----------------------------------------------------------------------------
    # Replace the home page
    #----------------------------------------------------------------------------
    if recipes.include? 'haml'
      remove_file 'app/views/home/index.html.haml'
      # we have to use single-quote-style-heredoc to avoid interpolation
      create_file 'app/views/home/index.html.haml' do 
      <<-'HAML'
%h3 Home
- @users.each do |user|
  %p User: #{user.name}
HAML
      end
    else
      append_file 'app/views/home/index.html.erb' do <<-ERB
<h3>Home</h3>
<% @users.each do |user| %>
  <p>User: <%= user.name %></p>
<% end %>
ERB
      end
    end

  end

  if recipes.include? 'git'
    git :tag => "home_page_with_users"
    git :add => '.'
    git :commit => "-am 'Added display of users to the home page.'"
  end

end

# >--------------------------------[ seed_database ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/seed_database.rb

say_recipe 'Seed Database'

after_bundler do
  
  if recipes.include? 'devise'
  
    if recipes.include? 'mongoid'
      # create a default user
      say_wizard "creating a default user"
      append_file 'db/seeds.rb' do <<-FILE
puts 'EMPTY THE MONGODB DATABASE'
Mongoid.master.collections.reject { |c| c.name =~ /^system/}.each(&:drop)
puts 'SETTING UP DEFAULT USER LOGIN'
user = User.create! :name => 'First User', :email => 'user@test.com', :password => 'please', :password_confirmation => 'please'
puts 'New user created: ' << user.name
FILE
      end
    end
  
    run 'rake db:seed'
  
  end

  if recipes.include? 'git'
    git :tag => "database_seed"
    git :add => '.'
    git :commit => "-am 'Create a database seed file with a default user.'"
  end

end

# >--------------------------------[ users_page ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/users_page.rb

# There is Haml code in this script. Changing the indentation is perilous between HAMLs.

say_recipe 'Users Page'

after_bundler do

  if recipes.include? 'devise'

    #----------------------------------------------------------------------------
    # Create a users controller
    #----------------------------------------------------------------------------
    generate(:controller, "users show")
    gsub_file 'app/controllers/users_controller.rb', /def show/ do
    <<-RUBY
before_filter :authenticate_user!

  def show
    @user = User.find(params[:id])
RUBY
    end

    #----------------------------------------------------------------------------
    # Modify the routes
    #----------------------------------------------------------------------------
    # @devise_for :users@ route must be placed above @resources :users, :only => :show@.
    gsub_file 'config/routes.rb', /get \"users\/show\"/, '#get \"users\/show\"'
    gsub_file 'config/routes.rb', /devise_for :users/ do
    <<-RUBY
devise_for :users
  resources :users, :only => :show
RUBY
    end

    #----------------------------------------------------------------------------
    # Create a users show page
    #----------------------------------------------------------------------------
    if recipes.include? 'haml'
      remove_file 'app/views/users/show.html.haml'
      # we have to use single-quote-style-heredoc to avoid interpolation
      create_file 'app/views/users/show.html.haml' do <<-'HAML'
%p
  User: #{@user.name}
HAML
      end
    else
      append_file 'app/views/users/show.html.erb' do <<-ERB
<p>User: <%= @user.name %></p>
ERB
      end
    end

    #----------------------------------------------------------------------------
    # Create a home page containing links to user show pages
    # (clobbers code from the home_page_users recipe)
    #----------------------------------------------------------------------------
    # set up the controller
    remove_file 'app/controllers/home_controller.rb'
    create_file 'app/controllers/home_controller.rb' do
    <<-RUBY
class HomeController < ApplicationController
  def index
    @users = User.all
  end
end
RUBY
    end

    # modify the home page
    if recipes.include? 'haml'
      remove_file 'app/views/home/index.html.haml'
      # we have to use single-quote-style-heredoc to avoid interpolation
      create_file 'app/views/home/index.html.haml' do
      <<-'HAML'
%h3 Home
- @users.each do |user|
  %p User: #{link_to user.name, user}
HAML
      end
    else
      remove_file 'app/views/home/index.html.erb'
      create_file 'app/views/home/index.html.erb' do <<-ERB
<h3>Home</h3>
<% @users.each do |user| %>
  <p>User: <%=link_to user.name, user %></p>
<% end %>
ERB
      end
    end

  end

  if recipes.include? 'git'
    git :tag => "users_page"
    git :add => '.'
    git :commit => "-am 'Add a users controller and user show page with links from the home page.'"
  end

end

# >--------------------------------[ css_setup ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/css_setup.rb

say_recipe 'CSS Setup'

after_bundler do

  #----------------------------------------------------------------------------
  # Add a stylesheet with styles for a horizontal menu and flash messages
  #----------------------------------------------------------------------------
  create_file 'public/stylesheets/application.css' do <<-CSS
ul.hmenu {
  list-style: none;	
  margin: 0 0 2em;
  padding: 0;
}
ul.hmenu li {
  display: inline;  
}
#flash_notice, #flash_alert {
  padding: 5px 8px;
  margin: 10px 0;
}
#flash_notice {
  background-color: #CFC;
  border: solid 1px #6C6;
}
#flash_alert {
  background-color: #FCC;
  border: solid 1px #C66;
}
CSS
  end

end

# >--------------------------------[ application_layout ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/application_layout.rb

# There is Haml code in this script. Changing the indentation is perilous between HAMLs.

say_recipe 'Application Layout'

after_bundler do

  #----------------------------------------------------------------------------
  # Set up the default application layout
  #----------------------------------------------------------------------------
  if recipes.include? 'haml'
    remove_file 'app/views/layouts/application.html.erb'
    create_file 'app/views/layouts/application.html.haml' do <<-HAML
!!!
%html
  %head
    %title #{app_name}
    = stylesheet_link_tag :all
    = javascript_include_tag :defaults
    = csrf_meta_tag
  %body
    - flash.each do |name, msg|
      = content_tag :div, msg, :id => "flash_\#{name}" if msg.is_a?(String)
    = yield
HAML
    end
  else
    inject_into_file 'app/views/layouts/application.html.erb', :after => "<body>\n" do
  <<-ERB
  <%- flash.each do |name, msg| -%>
    <%= content_tag :div, msg, :id => "flash_\#{name}" if msg.is_a?(String) %>
  <%- end -%>
ERB
    end
  end
  
  if recipes.include? 'git'
    git :tag => "app_layout"
    git :add => '.'
    git :commit => "-am 'Add application layout with CSS.'"
  end

end

# >--------------------------------[ devise_navigation ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/devise_navigation.rb

# There is Haml code in this script. Changing the indentation is perilous between HAMLs.

say_recipe 'Devise Navigation'

after_bundler do

  if recipes.include? 'devise'

    #----------------------------------------------------------------------------
    # Create navigation links for Devise
    #----------------------------------------------------------------------------
    if recipes.include? 'haml'
      create_file "app/views/devise/menu/_login_items.html.haml" do <<-'HAML'
- if user_signed_in?
  %li
    = link_to('Logout', destroy_user_session_path)
- else
  %li
    = link_to('Login', new_user_session_path)
HAML
      end
    else
      create_file "app/views/devise/menu/_login_items.html.erb" do <<-ERB
<% if user_signed_in? %>
  <li>
  <%= link_to('Logout', destroy_user_session_path) %>        
  </li>
<% else %>
  <li>
  <%= link_to('Login', new_user_session_path)  %>  
  </li>
<% end %>
ERB
      end
    end

    if recipes.include? 'haml'
      create_file "app/views/devise/menu/_registration_items.html.haml" do <<-'HAML'
- if user_signed_in?
  %li
    = link_to('Edit account', edit_user_registration_path)
- else
  %li
    = link_to('Sign up', new_user_registration_path)
HAML
      end
    else
      create_file "app/views/devise/menu/_registration_items.html.erb" do <<-ERB
<% if user_signed_in? %>
  <li>
  <%= link_to('Edit account', edit_user_registration_path) %>
  </li>
<% else %>
  <li>
  <%= link_to('Sign up', new_user_registration_path)  %>
  </li>
<% end %>
ERB
      end
    end

    #----------------------------------------------------------------------------
    # Add navigation links to the default application layout
    #----------------------------------------------------------------------------
    if recipes.include? 'haml'
      inject_into_file 'app/views/layouts/application.html.haml', :after => "%body\n" do <<-HAML
  %ul.hmenu
    = render 'devise/menu/registration_items'
    = render 'devise/menu/login_items'
HAML
      end
    else
      inject_into_file 'app/views/layouts/application.html.erb', :after => "<body>\n" do
  <<-ERB
  <ul class="hmenu">
    <%= render 'devise/menu/registration_items' %>
    <%= render 'devise/menu/login_items' %>
  </ul>
ERB
      end
    end

    if recipes.include? 'git'
      git :tag => "devise_navlinks"
      git :add => '.'
      git :commit => "-am 'Add navigation links for Devise.'"
    end

  end

end

# >--------------------------------[ cleanup ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/cleanup.rb

say_recipe 'cleanup'

# remove unnecessary files
%w{
  README
  doc/README_FOR_APP
  public/index.html
  public/images/rails.png
}.each { |file| remove_file file }

# add placeholder READMEs
get "https://github.com/fortuity/rails-template-recipes/raw/master/sample_readme.txt", "README"
get "https://github.com/fortuity/rails-template-recipes/raw/master/sample_readme.textile", "README.textile"
gsub_file "README", /App_Name/, "#{app_name.humanize.titleize}"
gsub_file "README.textile", /App_Name/, "#{app_name.humanize.titleize}"

# remove commented lines from Gemfile
# thanks to https://github.com/perfectline/template-bucket/blob/master/cleanup.rb
gsub_file "Gemfile", /#.*\n/, "\n"
gsub_file "Gemfile", /\n+/, "\n"

if recipes.include? 'git'
  git :tag => "file_cleanup"
  git :add => '.'
  git :commit => "-am 'Removed unnecessary files left over from initial app generation.'"
end

# >--------------------------------[ ban_spiders ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/ban_spiders.rb

say_recipe 'ban spiders'

# ban spiders from your site by changing robots.txt
say_wizard "banning spiders from your site by changing robots.txt"
gsub_file 'public/robots.txt', /# User-Agent/, 'User-Agent'
gsub_file 'public/robots.txt', /# Disallow/, 'Disallow'

if recipes.include? 'git'
  git :tag => "ban_spiders"
  git :add => '.'
  git :commit => "-am 'Ban spiders from the site by changing robots.txt'"
end

# >-----------------------------[ Custom Code ]-------------------------------<



# >-----------------------------[ run Bundler ]-------------------------------<

say_wizard "Running Bundler install. This will take a while."
run 'bundle install'

# >-----------------------------[ call everything that runs after Bundler ]-------------------------------<

say_wizard "Running after Bundler callbacks."
@after_blocks.each{|b| b.call}

# >-----------------------------[ reload Yard for updated documentation ]-------------------------------<

if recipes.include? 'yard'
  gsub_file '.yardopts', '## --use-cache', ' --use-cache'
  run 'yardoc'
  say_wizard "see application documentation at http://0.0.0.0:8080"
end

# >-----------------------------[ finish up ]-------------------------------<
say_wizard "Done setting up your Rails app with Mongoid and Devise."