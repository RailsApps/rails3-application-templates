# Application Generator Template
# Modifies a Rails app to use Mongoid and Devise
# Usage: rails new APP_NAME -m https://github.com/fortuity/rails3-application-templates/raw/master/rails3-mongoid-devise-template.rb

# Information and a tutorial: 
# http://github.com/fortuity/rails3-mongoid-devise/

# More application template recipes:
# https://github.com/fortuity/rails-template-recipes/

# If you are customizing this template, you can use any methods provided by Thor::Actions
# http://rdoc.info/rdoc/wycats/thor/blob/f939a3e8a854616784cac1dcff04ef4f3ee5f7ff/Thor/Actions.html
# and Rails::Generators::Actions
# http://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb

puts "Modifying a new Rails app to use Mongoid and Devise..."
puts "Any problems? See http://github.com/fortuity/rails3-mongoid-devise/issues"

# >----------------------------[ initial setup ]------------------------------<

initializer 'generators.rb', <<-RUBY
Rails.application.config.generators do |g|
end
RUBY

def say_recipe(name); say "\033[36m" + "recipe".rjust(10) + "\033[0m" + "    Running #{name} recipe..." end
def say_wizard(text); say "\033[36m" + "wizard".rjust(10) + "\033[0m" + "    #{text}" end

@after_blocks = []
def after_bundler(&block); @after_blocks << block; end

# >--------------------------------[ configure ]---------------------------------<

recipe_list = %w{ mongoid jquery haml devise heroku }

extra_recipes = %w{ git 
  action_mailer devise_extras add_user_name 
  home_page home_page_users seed_database users_page 
  css_setup application_layout devise_navigation 
  cleanup ban_spiders }

if no?('Would you like to use the Haml template system? (yes/no)')
  recipe_list.delete('haml')
end

if no?('Would you like to use jQuery instead of Prototype? (yes/no)')
  recipe_list.delete('jquery')
end

if no?('Do you want to install the Heroku gem so you can deploy to Heroku? (yes/no)')
  recipe_list.delete('heroku')
end

# >--------------------------------[ git ]---------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/git.rb

# Set up Git for version control
say_recipe 'Git'

# Git should ignore some files
remove_file '.gitignore'
file '.gitignore', <<-'IGNORES'.gsub(/^ {2}/, '')
  # bundler state
  /.bundle
  /vendor/bundle/

  # minimal Rails specific artifacts
  db/*.sqlite3
  /log/*
  tmp/*

  # various artifacts
  **.war
  *.rbc
  *.sassc
  .rspec
  .sass-cache
  /config/config.yml
  /config/database.yml
  /coverage.data
  /coverage/
  /db/*.javadb/
  /db/*.sqlite3-journal
  /doc/api/
  /doc/app/
  /doc/features.html
  /doc/specs.html
  /log/*
  /public/cache
  /public/stylesheets/compiled
  /public/system
  /spec/tmp/*
  /tmp/*
  /cache
  /capybara*
  /capybara-*.html
  /gems
  /rerun.txt
  /spec/requests
  /spec/routing
  /spec/views
  /specifications

  # scm revert files
  **.orig

  # mac finder poop
  .DS_Store

  # netbeans project directory
  /nbproject/

  # textmate project files
  /*.tmpproj

  # vim poop
  **.swp
IGNORES

# Initialize new Git repo
git :init
git :add => '.'
git :commit => "-aqm 'Initial commit of new Rails app'"

# >--------------------------------[ mongoid ]--------------------------------<

# Utilize MongoDB with Mongoid as the ORM.

if recipe_list.include? 'mongoid'

  say_recipe 'Mongoid'

  gem 'mongoid', '>= 2.0.0.rc.7'
  gem 'bson_ext'

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

  after_bundler do
    generate 'mongoid:config'
  end

  if extra_recipes.include? 'git'
    say_wizard "commiting changes to git"
    git :add => '.'
    git :commit => "-am 'Fix config/application.rb file to remove ActiveRecord dependency.'"
  end

end

# >--------------------------------[ jQuery ]---------------------------------<

if recipe_list.include? 'jquery'
  
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
  
end 

# >---------------------------------[ Haml ]----------------------------------<

if recipe_list.include? 'haml'
  
  # Utilize HAML for templating.
  say_recipe 'HAML'

  gem 'haml', '>= 3.0.0'
  gem 'haml-rails'

end

# >--------------------------------[ devise ]---------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/devise_extras.rb

if recipe_list.include? 'devise'
  
  # Utilize Devise for authentication, automatically configured for your selected ORM.
  say_recipe 'Devise'

  gem "devise", ">= 1.2.rc"

  after_bundler do

    #----------------------------------------------------------------------------
    # Run the Devise generator
    #----------------------------------------------------------------------------
    generate 'devise:install'

    if recipe_list.include? 'mongo_mapper'
      gem 'mm-devise'
      gsub_file 'config/initializers/devise.rb', 'devise/orm/active_record', 'devise/orm/mongo_mapper_active_model'
    elsif recipe_list.include? 'mongoid'
      # Nothing to do (Devise changes its initializer automatically when Mongoid is detected)
      # gsub_file 'config/initializers/devise.rb', 'devise/orm/active_record', 'devise/orm/mongoid'
    elsif recipe_list.include? 'active_record'
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

    if extra_recipes.include? 'git'
      say_wizard "commiting changes to git"
      git :add => '.'
      git :commit => "-am 'Added Devise for authentication'"
    end

  end

end

# >--------------------------------[ action_mailer ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/action_mailer.rb

say_recipe 'ActionMailer configuration'

# modifying environment configuration files for ActiveRecord
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

if extra_recipes.include? 'git'
  say_wizard "commiting changes to git"
  git :add => '.'
  git :commit => "-am 'Set ActionMailer configuration.'"
end

# >--------------------------------[ add_user_name ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/add_user_name.rb

# There is Haml code in this script. Changing the indentation is perilous between HAMLs.

say_recipe 'add_user_name'

if recipe_list.include? 'haml'
  # the following gems are required to generate Devise views for Haml
  gem 'hpricot', :group => :development
  gem 'ruby_parser', :group => :development
end

after_bundler do
   
  #----------------------------------------------------------------------------
  # Add a 'name' attribute to the User model
  #----------------------------------------------------------------------------
  if recipe_list.include? 'mongoid'
    gsub_file 'app/models/user.rb', /end/ do
  <<-RUBY
  field :name
  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
end
RUBY
    end
  elsif recipe_list.include? 'mongo_mapper'
    # Using MongoMapper? Create an issue, suggest some code, and I'll add it
  elsif recipe_list.include? 'active_record'
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

  if extra_recipes.include? 'devise_extras'
    #----------------------------------------------------------------------------
    # Generate Devise views
    #----------------------------------------------------------------------------
    run 'rails generate devise:views'

    #----------------------------------------------------------------------------
    # Modify Devise views to add 'name'
    #----------------------------------------------------------------------------
    if recipe_list.include? 'haml'
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

    if recipe_list.include? 'haml'
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
  end

  if extra_recipes.include? 'git'
    say_wizard "commiting changes to git"
    git :add => '.'
    if extra_recipes.include? 'devise_extras'
      git :commit => "-am 'Add a name attribute to the User model and modify Devise views.'"
    else
      git :commit => "-am 'Add a name attribute to the User model.'"
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
  if recipe_list.include? 'haml'
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

  if extra_recipes.include? 'git'
    say_wizard "commiting changes to git"
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

  if extra_recipes.include? 'devise_extras'

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
    if recipe_list.include? 'haml'
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

  if extra_recipes.include? 'git'
    say_wizard "commiting changes to git"
    git :add => '.'
    git :commit => "-am 'Added display of users to the home page.'"
  end

end

# >--------------------------------[ seed_database ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/seed_database.rb

say_recipe 'Seed Database'

after_bundler do
  
  if extra_recipes.include? 'devise_extras'
  
    if recipe_list.include? 'mongoid'
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

  if extra_recipes.include? 'git'
    say_wizard "commiting changes to git"
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

  if extra_recipes.include? 'devise_extras'

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
    if recipe_list.include? 'haml'
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
    if recipe_list.include? 'haml'
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

  if extra_recipes.include? 'git'
    say_wizard "commiting changes to git"
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

if recipe_list.include? 'haml'
  say_recipe 'Application layout (Haml)'

  remove_file 'app/views/layouts/application.html.erb'

  create_file 'app/views/layouts/application.html.haml' do
    <<-FLASHES.gsub(/^ {6}/, '')
      !!! 5
      %html
        %head
          %title #{app_name}
          = stylesheet_link_tag :all
          = javascript_include_tag :defaults
          = csrf_meta_tag
        %body
          = yield
    FLASHES
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
  if recipe_list.include? 'haml'
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

end

# >--------------------------------[ devise_navigation ]--------------------------------<

# Application template recipe. Check for a newer version here:
# https://github.com/fortuity/rails-template-recipes/blob/master/devise_navigation.rb

# There is Haml code in this script. Changing the indentation is perilous between HAMLs.

say_recipe 'Devise Navigation'

after_bundler do

  if extra_recipes.include? 'devise_extras'

    #----------------------------------------------------------------------------
    # Create navigation links for Devise
    #----------------------------------------------------------------------------
    if recipe_list.include? 'haml'
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

    if recipe_list.include? 'haml'
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
    if recipe_list.include? 'haml'
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

    if extra_recipes.include? 'git'
      say_wizard "commiting changes to git"
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

# remove commented lines from Gemfile
# thanks to https://github.com/perfectline/template-bucket/blob/master/cleanup.rb
gsub_file "Gemfile", /#.*\n/, "\n"
gsub_file "Gemfile", /\n+/, "\n"

if extra_recipes.include? 'git'
  say_wizard "commiting deletes of unneeded files to git"
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

if extra_recipes.include? 'git'
  say_wizard "commiting changes to git"
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

# >-----------------------------[ finish up ]-------------------------------<
puts "Done setting up your Rails app with Mongoid and Devise."