# Application Generator Template
# Modifies a Rails app to set up subdomains with Devise
# Usage: rails new app_name -m https://github.com/fortuity/rails3-application-templates/raw/master/rails3-subdomain-devise-template.rb

# More info: http://github.com/fortuity/rails3-subdomain-devise/

# If you are customizing this template, you can use any methods provided by Thor::Actions
# http://rdoc.info/rdoc/wycats/thor/blob/f939a3e8a854616784cac1dcff04ef4f3ee5f7ff/Thor/Actions.html
# and Rails::Generators::Actions
# http://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb

puts "Modifying a new Rails app to set up subdomains with Devise..."
puts "Any problems? See http://github.com/fortuity/rails3-subdomain-devise/issues"

#----------------------------------------------------------------------------
# Configure
#----------------------------------------------------------------------------

if yes?('Would you like to use Mongoid instead of ActiveRecord for database access? (yes/no)')
  mongoid_flag = true
else
  mongoid_flag = false
end

if yes?('Would you like to use the Haml template system? (yes/no)')
  haml_flag = true
else
  haml_flag = false
end

if yes?('Would you like to use jQuery instead of Prototype? (yes/no)')
  jquery_flag = true
else
  jquery_flag = false
end

if yes?('Do you want to install the Heroku gem so you can deploy to Heroku? (yes/no)')
  heroku_flag = true
else
  heroku_flag = false
end

#----------------------------------------------------------------------------
# Set up git
#----------------------------------------------------------------------------
puts "setting up source control with 'git'..."
# specific to Mac OS X
append_file '.gitignore' do
  '.DS_Store'
end
git :init
git :add => '.'
git :commit => "-m 'Initial commit of unmodified new Rails app'"

#----------------------------------------------------------------------------
# Remove the usual cruft
#----------------------------------------------------------------------------
puts "removing unneeded files..."
run 'rm public/index.html'
run 'rm public/favicon.ico'
run 'rm public/images/rails.png'
run 'rm README'
run 'touch README'

puts "banning spiders from your site by changing robots.txt..."
gsub_file 'public/robots.txt', /# User-Agent/, 'User-Agent'
gsub_file 'public/robots.txt', /# Disallow/, 'Disallow'

puts "setting up the Gemfile..."
run 'rm Gemfile'
create_file 'Gemfile', "source 'http://rubygems.org'\n"
gem 'rails', '3.0.4'
if !mongoid_flag
  gem 'sqlite3'
  gem 'friendly_id', '3.2.1'
end
gem 'devise', '1.2.rc'

#----------------------------------------------------------------------------
# Heroku Option
#----------------------------------------------------------------------------
if heroku_flag
  puts "adding Heroku gem to the Gemfile..."
  gem 'heroku', '1.17.13', :group => :development
end

#----------------------------------------------------------------------------
# Haml Option
#----------------------------------------------------------------------------
if haml_flag
  puts "setting up Gemfile for Haml..."
  append_file 'Gemfile', "\n# Bundle gems needed for Haml\n"
  gem 'haml', '3.0.25'
  gem 'haml-rails', '0.3.4', :group => :development
  # the following gems are used to generate Devise views for Haml
  gem 'hpricot', '0.8.3', :group => :development
  gem 'ruby_parser', '2.0.5', :group => :development
end

#----------------------------------------------------------------------------
# jQuery Option
#----------------------------------------------------------------------------
if jquery_flag
  puts "setting up Gemfile for jQuery..."
  gem 'jquery-rails', '0.2.7'
end

#----------------------------------------------------------------------------
# Mongoid Option
#----------------------------------------------------------------------------
if mongoid_flag
  puts "setting up Gemfile for Mongoid..."
  gsub_file 'Gemfile', /gem \'sqlite3-ruby/, '# gem \'sqlite3-ruby'
  append_file 'Gemfile', "\n# Bundle gems needed for Mongoid\n"
  gem "mongoid", "2.0.0.rc.7"
  gem 'bson_ext', '1.2.2'
end

puts "installing gems (takes a few minutes!)..."
run 'bundle install'

#----------------------------------------------------------------------------
# Set up Mongoid
#----------------------------------------------------------------------------
if mongoid_flag
  puts "creating 'config/mongoid.yml' Mongoid configuration file..."
  run 'rails generate mongoid:config'

  puts "modifying 'config/application.rb' file for Mongoid..."
  gsub_file 'config/application.rb', /require 'rails\/all'/ do
<<-RUBY
# If you are deploying to Heroku and MongoHQ,
# you supply connection information here.
require 'uri'
if ENV['MONGOHQ_URL']
  mongo_uri = URI.parse(ENV['MONGOHQ_URL'])
  ENV['MONGOID_HOST'] = mongo_uri.host
  ENV['MONGOID_PORT'] = mongo_uri.port.to_s
  ENV['MONGOID_USERNAME'] = mongo_uri.user
  ENV['MONGOID_PASSWORD'] = mongo_uri.password
  ENV['MONGOID_DATABASE'] = mongo_uri.path.gsub('/', '')
end

require 'mongoid/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_resource/railtie'
require 'rails/test_unit/railtie'
RUBY
  end
end

if mongoid_flag
  run 'rm config/database.yml'
end

#----------------------------------------------------------------------------
# Tweak config/application.rb for Mongoid
#----------------------------------------------------------------------------
if mongoid_flag
  gsub_file 'config/application.rb', /# Configure the default encoding used in templates for Ruby 1.9./ do
<<-RUBY
config.generators do |g|
      g.orm             :mongoid
    end

    # Configure the default encoding used in templates for Ruby 1.9.
RUBY
  end
end

puts "prevent logging of passwords"
gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'

if !mongoid_flag
  puts "setting up a migration for use with FriendlyId..."
  run 'rails generate friendly_id'
end

#----------------------------------------------------------------------------
# Set up jQuery
#----------------------------------------------------------------------------
if jquery_flag
  run 'rm public/javascripts/rails.js'
  puts "replacing Prototype with jQuery"
  # "--ui" enables optional jQuery UI
  run 'rails generate jquery:install --ui'
end

#----------------------------------------------------------------------------
# Set up Devise
#----------------------------------------------------------------------------
puts "creating 'config/initializers/devise.rb' Devise configuration file..."
run 'rails generate devise:install'
run 'rails generate devise:views'

puts "modifying environment configuration files for Devise..."
gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '### ActionMailer Config'
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
gsub_file 'config/environments/production.rb', /config.i18n.fallbacks = true/ do
<<-RUBY
config.i18n.fallbacks = true

  config.action_mailer.default_url_options = { :host => 'yourhost.com' }
  ### ActionMailer Config
  # Setup for production - deliveries, no errors raised
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default :charset => "utf-8"
RUBY
end

puts "creating a User model and modifying routes for Devise..."
run 'rails generate devise User'

puts "adding a 'name' attribute to the User model"
if mongoid_flag
  inject_into_file 'app/models/user.rb', :after => ":recoverable, :rememberable, :trackable, :validatable\n" do
<<-RUBY
  field :name
  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
  key :name
  references_many :subdomains, :dependent => :destroy
RUBY
  end
else
  run 'rm app/models/user.rb'
  create_file 'app/models/user.rb' do
<<-RUBY
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :subdomains, :dependent => :destroy
  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
  has_friendly_id :name, :use_slug => true, :strip_non_ascii => true
end
RUBY
  end
end

if !mongoid_flag
  puts "creating a database migration to add 'name' to the User table"
  generate(:migration, "AddNameToUsers name:string")
end

#----------------------------------------------------------------------------
# Modify Devise views
#----------------------------------------------------------------------------
puts "modifying the default Devise user registration to add 'name'..."
if haml_flag
   inject_into_file "app/views/devise/registrations/edit.html.haml", :after => "= devise_error_messages!\n" do
<<-RUBY
  %p
    = f.label :name
    %br/
    = f.text_field :name
RUBY
   end
else
   inject_into_file "app/views/devise/registrations/edit.html.erb", :after => "<%= devise_error_messages! %>\n" do
<<-RUBY
  <p><%= f.label :name %><br />
  <%= f.text_field :name %></p>
RUBY
   end
end

if haml_flag
   inject_into_file "app/views/devise/registrations/new.html.haml", :after => "= devise_error_messages!\n" do
<<-RUBY
  %p
    = f.label :name
    %br/
    = f.text_field :name
RUBY
   end
else
   inject_into_file "app/views/devise/registrations/new.html.erb", :after => "<%= devise_error_messages! %>\n" do
<<-RUBY
  <p><%= f.label :name %><br />
  <%= f.text_field :name %></p>
RUBY
   end
end

#----------------------------------------------------------------------------
# Create a Subdomain model
#----------------------------------------------------------------------------
puts "creating a Subdomain model..."
if mongoid_flag
  generate(:model, "Subdomain name:string")
  inject_into_file 'app/models/subdomain.rb', :after => "field :name, :type => String\n" do
<<-RUBY
key :name
referenced_in :user
validates_uniqueness_of :name, :case_sensitive => false
validates_presence_of :name
RUBY
  end
else
  generate(:model, "Subdomain name:string user:references")
  run 'rm app/models/subdomain.rb'
  create_file 'app/models/subdomain.rb' do
<<-RUBY
class Subdomain < ActiveRecord::Base
  belongs_to :user
  has_friendly_id :name, :use_slug => true, :strip_non_ascii => true
  validates_uniqueness_of :name, :case_sensitive => false
  validates_presence_of :name
end
RUBY
  end
end

puts "setting up the Site model"
create_file 'app/models/site.rb' do
<<-RUBY
class Site < Subdomain
end
RUBY
end

#----------------------------------------------------------------------------
# User controller and views
#----------------------------------------------------------------------------
puts "generating controller and views to display users"
generate(:controller, "users index show")
gsub_file 'config/routes.rb', /get \"users\/index\"/, ''
gsub_file 'config/routes.rb', /get \"users\/show\"/, ''

inject_into_file "app/controllers/users_controller.rb", :after => "def index\n" do
<<-RUBY
    @users = User.all
RUBY
end

inject_into_file "app/controllers/users_controller.rb", :after => "def show\n" do
<<-RUBY
    @user = User.find(params[:id])
RUBY
end

if haml_flag
  run 'rm app/views/users/show.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/users/show.html.haml' do <<-'FILE'
%h1= @user.name
%p
  Email: #{@user.email}
= link_to 'Edit', edit_user_registration_path
|
\#{link_to 'List of Users', users_path}
%h3
  = @user.name
  Subdomains
%table
  - @user.subdomains.each do |subdomain|
    %tr
      %td= link_to subdomain.name, subdomain
      %td= link_to 'Edit', edit_subdomain_path(subdomain)
      %td= link_to 'Destroy', subdomain, :confirm => 'Are you sure?', :method => :delete
      %td= link_to "Visit #{root_url(:subdomain => subdomain.name)}", root_url(:subdomain => subdomain.name)
%br/
= link_to "Add New Subdomain", new_user_subdomain_path(@user)
FILE
  end
else
  run 'rm app/views/users/show.html.erb'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/users/show.html.erb' do <<-'FILE'
<h1><%= @user.name %></h1>
<p>Email: <%= @user.email %></p>
<%= link_to 'Edit', edit_user_registration_path %> |
<%= link_to 'List of Users', users_path %>
<h3><%= @user.name %>'s Subdomains</h3>
<table>
<% @user.subdomains.each do |subdomain| %>
  <tr>
    <td><%= link_to subdomain.name, subdomain %></td>
    <td><%= link_to 'Edit', edit_subdomain_path(subdomain) %></td>
    <td><%= link_to 'Destroy', subdomain, :confirm => 'Are you sure?', :method => :delete %></td>
    <td><%= link_to "Visit #{root_url(:subdomain => subdomain.name)}", root_url(:subdomain => subdomain.name) %></td>
  </tr>
<% end %>
</table>
<br />
<%= link_to "Add New Subdomain", new_user_subdomain_path(@user) %>
FILE
  end
end

if haml_flag
  run 'rm app/views/users/index.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/users/index.html.haml' do <<-'FILE'
%h1 Users
%table
  - @users.each do |user|
    %tr
      %td= link_to user.name, user
FILE
  end
else
  run 'rm app/views/users/index.html.erb'
  create_file 'app/views/users/index.html.erb' do <<-FILE
<h1>Users</h1>
<table>
<% @users.each do |user| %>
  <tr>
    <td><%= link_to user.name, user %></td>
  </tr>
<% end %>
</table>
FILE
  end
end

#----------------------------------------------------------------------------
# Devise navigation
#----------------------------------------------------------------------------
if haml_flag
  create_file "app/views/devise/menu/_login_items.html.haml" do <<-'FILE'
- if user_signed_in?
  %li
    = link_to('Logout', destroy_user_session_path)
- else
  %li
    = link_to('Login', new_user_session_path)
%li
  User:
  - if current_user
    = current_user.name
  - else
    (not logged in)
  FILE
  end
else
  create_file "app/views/devise/menu/_login_items.html.erb" do <<-FILE
<% if user_signed_in? %>
  <li>
  <%= link_to('Logout', destroy_user_session_path) %>        
  </li>
<% else %>
  <li>
  <%= link_to('Login', new_user_session_path)  %>  
  </li>
<% end %>
<li>
  User: 
  <% if current_user %>
    <%= current_user.name %>
  <% else %>
    (not logged in)
  <% end %>
</li>
  FILE
  end
end

if haml_flag
  create_file "app/views/devise/menu/_registration_items.html.haml" do <<-'FILE'
- if user_signed_in?
  %li
    = link_to('Edit account', edit_user_registration_path)
- else
  %li
    = link_to('Sign up', new_user_registration_path)
  FILE
  end
else
  create_file "app/views/devise/menu/_registration_items.html.erb" do <<-FILE
<% if user_signed_in? %>
  <li>
  <%= link_to('Edit account', edit_user_registration_path) %>
  </li>
<% else %>
  <li>
  <%= link_to('Sign up', new_user_registration_path)  %>
  </li>
<% end %>
  FILE
  end
end

#----------------------------------------------------------------------------
# Generate Application Layout
#----------------------------------------------------------------------------
if haml_flag
  run 'rm app/views/layouts/application.html.erb'
  create_file 'app/views/layouts/application.html.haml' do <<-FILE
!!!
%html
  %head
    %title Testapp
    = stylesheet_link_tag :all
    = javascript_include_tag :defaults
    = csrf_meta_tag
  %body
    %ul.hmenu
      = render 'devise/menu/registration_items'
      = render 'devise/menu/login_items'
    %p{:style => "color: green"}= notice
    %p{:style => "color: red"}= alert
    = yield
FILE
  end
else
  inject_into_file 'app/views/layouts/application.html.erb', :after => "<body>\n" do
  <<-RUBY
<ul class="hmenu">
  <%= render 'devise/menu/registration_items' %>
  <%= render 'devise/menu/login_items' %>
</ul>
<p style="color: green"><%= notice %></p>
<p style="color: red"><%= alert %></p>
RUBY
  end
end

#----------------------------------------------------------------------------
# Add Stylesheets
#----------------------------------------------------------------------------
create_file 'public/stylesheets/application.css' do <<-FILE
ul.hmenu {
  list-style: none; 
  margin: 0 0 2em;
  padding: 0;
}

ul.hmenu li {
  display: inline;  
}
FILE
end

#----------------------------------------------------------------------------
# Home Controller and View
#----------------------------------------------------------------------------
puts "create a home controller and view"
generate(:controller, "home index")
gsub_file 'config/routes.rb', /get \"home\/index\"/, ''

if haml_flag
  run 'rm app/views/home/index.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/home/index.html.haml' do <<-'FILE'
%h1 Rails3-Subdomain-Devise
%p= link_to "View List of Users", users_path
  FILE
  end
else
  run 'rm app/views/home/index.html.erb'
  create_file 'app/views/home/index.html.erb' do <<-FILE
<h1>Rails3-Subdomain-Devise</h1>
<p><%= link_to "View List of Users", users_path %></p>
  FILE
  end
end

#----------------------------------------------------------------------------
# Subdomains Controller and View
#----------------------------------------------------------------------------
puts "create a controller and views to manage subdomains"
generate(:scaffold_controller, "Subdomains")
run 'rm app/controllers/subdomains_controller.rb'
create_file 'app/controllers/subdomains_controller.rb' do <<-FILE
class SubdomainsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]
  before_filter :find_user, :except => [:index, :show]
  respond_to :html

  def index
    @subdomains = Subdomain.all
    respond_with(@subdomains)
  end

  def show
    @subdomain = Subdomain.find(params[:id])
    respond_with(@subdomain)
  end

  def new
  @subdomain = Subdomain.new(:user => @user)
  respond_with(@subdomain)
  end

  def create
    @subdomain = Subdomain.new(params[:subdomain])
    if @subdomain.save
      flash[:notice] = "Successfully created subdomain."
    end
    redirect_to @user
  end

  def edit
    @subdomain = Subdomain.find(params[:id])
    respond_with(@subdomain)
  end

  def update
    @subdomain = Subdomain.find(params[:id])
    if @subdomain.update_attributes(params[:subdomain])
      flash[:notice] = "Successfully updated subdomain."
    end
    respond_with(@subdomain)
  end

  def destroy
    @subdomain = Subdomain.find(params[:id])
    @subdomain.destroy
    flash[:notice] = "Successfully destroyed subdomain."
    redirect_to @user
  end

  protected

    def find_user
      if params[:user_id]
        @user = User.find(params[:user_id])
      else
        @subdomain = Subdomain.find(params[:id])
        @user = @subdomain.user
      end
      unless current_user == @user
        redirect_to @user, :alert => "Are you logged in properly? You are not allowed to create or change someone else's subdomain."
      end
    end

end
  FILE
end

if haml_flag
  run 'rm app/views/subdomains/_form.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/subdomains/_form.html.haml' do <<-'FILE'
- if @subdomain.errors.any?
  #error_explanation
    %h2
      = pluralize(@subdomain.errors.count, "error")
      prohibited this subdomain from being saved:
    %ul
      - @subdomain.errors.full_messages.each do |msg|
        %li= msg
= fields_for @subdomain do |f|
  %div
    = f.label :name
    = f.text_field :name
    = f.hidden_field (:user_id, :value => @subdomain.user_id)
  %br/
  .actions
    = f.submit
  FILE
  end
else
  run 'rm app/views/subdomains/_form.html.erb'
  create_file 'app/views/subdomains/_form.html.erb' do <<-FILE
<% if @subdomain.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@subdomain.errors.count, "error") %> prohibited this subdomain from being saved:</h2>
    <ul>
    <% @subdomain.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
<% end %>
<%= fields_for @subdomain do |f| %> 
  <div>
  <%= f.label :name %>
  <%= f.text_field :name %>
  <%= f.hidden_field (:user_id, :value => @subdomain.user_id) %>
  </div>
  <br />
  <div class="actions">
    <%= f.submit %>
  </div>
<% end %>
  FILE
  end
end

if haml_flag
  run 'rm app/views/subdomains/edit.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/subdomains/edit.html.haml' do <<-'FILE'
%h1 Editing subdomain
= form_for(@subdomain) do |f|
  = render 'form'
= link_to 'Show', @subdomain
|
\#{link_to @subdomain.user.name, user_path(@subdomain.user)}
  FILE
  end
else
  run 'rm app/views/subdomains/edit.html.erb'
  create_file 'app/views/subdomains/edit.html.erb' do <<-FILE
<h1>Editing subdomain</h1>
<%= form_for(@subdomain) do |f| %>
  <%= render 'form' %>
<% end %><%= link_to 'Show', @subdomain %> |
<%= link_to @subdomain.user.name, user_path(@subdomain.user) %>
  FILE
  end
end

if haml_flag
  run 'rm app/views/subdomains/index.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/subdomains/index.html.haml' do <<-'FILE'
%h1 Subdomains
%table
  - @subdomains.each do |subdomain|
    %tr
      %td= link_to subdomain.name, subdomain
      %td
        (belongs to #{link_to subdomain.user.name, user_url(subdomain.user)})
      %td= link_to 'Edit', edit_subdomain_path(subdomain)
      %td= link_to 'Destroy', subdomain, :confirm => 'Are you sure?', :method => :delete
  FILE
  end
else
  run 'rm app/views/subdomains/index.html.erb'
  create_file 'app/views/subdomains/index.html.erb' do <<-FILE
<h1>Subdomains</h1>
<table>
<% @subdomains.each do |subdomain| %>
  <tr>
    <td><%= link_to subdomain.name, subdomain %></td>
    <td>(belongs to <%= link_to subdomain.user.name, user_url(subdomain.user) %>)</td>
    <td><%= link_to 'Edit', edit_subdomain_path(subdomain) %></td>
    <td><%= link_to 'Destroy', subdomain, :confirm => 'Are you sure?', :method => :delete %></td>
  </tr>
<% end %>
</table>
  FILE
  end
end

if haml_flag
  run 'rm app/views/subdomains/new.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/subdomains/new.html.haml' do <<-'FILE'
%h1 New subdomain
= form_for([@user, @subdomain]) do |f|
  = render 'form'
= link_to @subdomain.user.name, user_path(@subdomain.user)
  FILE
  end
else
  run 'rm app/views/subdomains/new.html.erb'
  create_file 'app/views/subdomains/new.html.erb' do <<-FILE
<h1>New subdomain</h1>
<%= form_for([@user, @subdomain]) do |f| %>
  <%= render 'form' %>
<% end %>
<%= link_to @subdomain.user.name, user_path(@subdomain.user) %>
  FILE
  end
end

if haml_flag
  run 'rm app/views/subdomains/show.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/subdomains/show.html.haml' do <<-'FILE'
%h1= @subdomain.name
%p
  Belongs to: #{link_to @subdomain.user.name, user_url(@subdomain.user)}
= link_to 'Edit', edit_subdomain_path(@subdomain)
  FILE
  end
else
  run 'rm app/views/subdomains/show.html.erb'
  create_file 'app/views/subdomains/show.html.erb' do <<-FILE
<h1><%= @subdomain.name %></h1>
<p>Belongs to: <%= link_to @subdomain.user.name, user_url(@subdomain.user) %></p>
<%= link_to 'Edit', edit_subdomain_path(@subdomain) %>
  FILE
  end
end

#----------------------------------------------------------------------------
# Sites Controller and View
#----------------------------------------------------------------------------
puts "create a controller and views to display subdomain sites"
generate(:controller, "Sites show")
gsub_file 'config/routes.rb', /get \"sites\/show\"/, ''
inject_into_file "app/controllers/sites_controller.rb", :after => "ApplicationController\n" do
<<-RUBY
  skip_before_filter :limit_subdomain_access
RUBY
end
if mongoid_flag
  inject_into_file "app/controllers/sites_controller.rb", :after => "def show\n" do
<<-RUBY
    # this is not quite right, needs investigation, should be "Site" not "Subdomain"
    @site = Subdomain.first(:conditions => { :name => request.subdomain })
RUBY
  end
else
  inject_into_file "app/controllers/sites_controller.rb", :after => "def show\n" do
<<-RUBY
    @site = Site.find_by_name!(request.subdomain)
RUBY
  end
end
if haml_flag
  run 'rm app/views/sites/show.html.haml'
  # we have to use single-quote-style-heredoc to avoid interpolation
  create_file 'app/views/sites/show.html.haml' do <<-'FILE'
%h1
  Site: #{@site.name}
%p
  Belongs to: #{link_to @site.user.name, user_url(@site.user, :subdomain => false)}
%p= link_to 'Home', root_url(:subdomain => false)
  FILE
  end
else
  run 'rm app/views/sites/show.html.erb'
  create_file 'app/views/sites/show.html.erb' do <<-FILE
<h1>Site: <%= @site.name %></h1>
<p>Belongs to: <%= link_to @site.user.name, user_url(@site.user, :subdomain => false) %></p>
<p><%= link_to 'Home', root_url(:subdomain => false) %></p>
  FILE
  end
end

#----------------------------------------------------------------------------
# URL helper
#----------------------------------------------------------------------------
puts "create a URL helper for navigation between sites"
create_file 'app/helpers/url_helper.rb' do <<FILE
module UrlHelper
  def with_subdomain(subdomain)
    subdomain = (subdomain || "")
    subdomain += "." unless subdomain.empty?
    [subdomain, request.domain, request.port_string].join
  end

  def url_for(options = nil)
    if options.kind_of?(Hash) && options.has_key?(:subdomain)
      options[:host] = with_subdomain(options.delete(:subdomain))
    end
    super
  end
  
  def set_mailer_url_options
    ActionMailer::Base.default_url_options[:host] = with_subdomain(request.subdomain)
  end
end
FILE
end

puts "modifying the application controller"
run 'rm app/controllers/application_controller.rb'
create_file 'app/controllers/application_controller.rb' do
<<-RUBY
class ApplicationController < ActionController::Base
  include UrlHelper
  protect_from_forgery
  before_filter :limit_subdomain_access
  before_filter :set_mailer_url_options

  protected

    def limit_subdomain_access
        if request.subdomain.present?
          # this error handling could be more sophisticated!
          # please make a suggestion :-)
          redirect_to root_url(:subdomain => false)
        end
    end

end
RUBY
end

#----------------------------------------------------------------------------
# Create Routes
#----------------------------------------------------------------------------
puts "creating routes"
inject_into_file 'config/routes.rb', :after => "devise_for :users\n" do
<<-RUBY
  resources :users, :only => [:index, :show] do
    resources :subdomains, :shallow => true
  end
  match '/' => 'home#index', :constraints => { :subdomain => 'www' }
  match '/' => 'sites#show', :constraints => { :subdomain => /.+/ }
  root :to => "home#index"
RUBY
end

puts "allow cookies to be shared across subdomains"
inject_into_file 'config/initializers/session_store.rb', ":domain => :all, ", :after => ":cookie_store, "

#----------------------------------------------------------------------------
# Create a default user and subdomains
#----------------------------------------------------------------------------
if !mongoid_flag
  puts "create and migrate the database"
  run 'rake db:create'
  run 'rake db:migrate'
end

puts "creating default users and subdomains"
append_file 'db/seeds.rb' do <<-FILE
puts 'SETTING UP EXAMPLE USERS'
user1 = User.create! :name => 'First User', :email => 'user@test.com', :password => 'please', :password_confirmation => 'please'
puts 'New user created: ' << user1.name
user2 = User.create! :name => 'Other User', :email => 'otheruser@test.com', :password => 'please', :password_confirmation => 'please'
puts 'New user created: ' << user2.name
puts 'SETTING UP EXAMPLE SUBDOMAINS'
subdomain1 = Subdomain.create! :name => 'foo'
puts 'Created subdomain: ' << subdomain1.name
subdomain2 = Subdomain.create! :name => 'bar'
puts 'Created subdomain: ' << subdomain2.name
user1.subdomains << subdomain1
user1.save
user2.subdomains << subdomain2
user2.save
FILE
end
run 'rake db:seed'

#----------------------------------------------------------------------------
# Finish up
#----------------------------------------------------------------------------
puts "checking everything into git..."
git :add => '.'
git :commit => "-m 'modified Rails app to use subdomains with Devise'"

puts "Done setting up your Rails app using subdomains with Devise."
