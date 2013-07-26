Your Priorities is a web based platform that enables groups of people to define their democratic ideas and together discover which are the most important ideas to implement by their instances.  People can add new ideas, add arguments for and against ideas, indicate if they support or oppose an idea, create a personal list of ideas and discuss all ideas. The end results are lists of top ideas in many categories as well as the best arguments for and against each idea. This service enables people to make up their minds about most issues in a short time.

Your Priorities is being used on the https://www.yrpri.org/ eDemocracy service and the Better Reykjavik website in Iceland amongst other places.

Short new instructions
======================

Development on Ubuntu
=====================

1. Install rvm the Ruby version manager
````bash
sudo apt-get install curl
\curl -L https://get.rvm.io | bash -s stable
````

2. Go into the application and install all gems
````bash
bundle install
````

3. Install postgres
````bash
sudo apt-get install postgresql
````

4. Then start the psql shell
````bash
sudo su postgres
psql
````

5. When in psql create a user and the Your Priorities dev database
````bash
create user puser password 'xxxxxxxx'
create database yrpri_dev with encoding 'utf8';
grant all privileges on database yrpri_dev to puser;
postgres=#
````

6. Then exit the postgres shell and copy and edit the config/database.yml.dist file
````bash
cd config
cp database.yml.dist database.yml
````

7. Then edit the database.yml file for your puser password

8. When ready create the database tables and seed the database:
````bash
rake db:schema:load
rake db:seed
````

9. Start the server
````bash
rails s
````

10. Navigate to http://localhost:3000/


Production Deployment on Heroku
===============================

Your Priorities is now setup to be a Heroku app, using S3 and CloudFront for deployment.

Here are the parameters that are used in Heroku config.

Heroku parameters you need to setup yourself:
````bash
AWS_ACCESS_KEY_ID:            ----------------------
````
````bash
AWS_SECRET_ACCESS_KEY:        ----------------------
````
````bash
CF_ASSET_HOST:                ----------------------.cloudfront.net
````
````bash
FACEBOOKER2_API_KEY:          ----------------------
````
````bash
FACEBOOKER2_APP_ID:           ----------------------
````
````bash
FOG_DIRECTORY:                ----------------------
````
````bash
S3_BUCKET:                    ----------------------
````
````bash
S3_KEY:                       ----------------------
````
````bash
S3_SECRET:                    ----------------------
````
````bash
YRPRI_ALL_DOMAIN: 1
````

Below config examples set automatically by the respected services, you can see from this list what heroku additions are needed to run the app:

````bash
ADEPT_SCALE_URL:              ----------------------
````
````bash
DATABASE_URL:                 ----------------------
````
````bash
FLYING_SPHINX_API_KEY:        ----------------------
````
````bash
HEROKU_POSTGRESQL_WHITE_URL:  ----------------------
````
````bash
MEMCACHIER_USERNAME:          ----------------------
````
````bash
PGBACKUPS_URL:                ----------------------
````
````bash
REDISTOGO_URL:                ----------------------
````
````bash
SENDGRID_USERNAME:            ----------------------
````
````bash
AWS_ACCESS_KEY_ID:            ----------------------
````
````bash
AWS_ACCESS_KEY_ID:            ----------------------
````


Installation (Old instructions below)
=====================================

Ruby
----

First you'll want to install your own Ruby (if you haven't already). There are
a few ways to do that. The rest of this guide assumes you use bash and RVM.

First you install RVM (Ruby Version Manager):

Then reload your environment:

````bash
$ source ~/.bash_profile
````

Find out what dependencies are needed for Ruby (MRI) and install them:

````bash
$ rvm requirements
````

Install and use Ruby 1.9.3

````bash
$ rvm install 1.9.3
$ rvm use 1.9.3 --default
````

Install Bundler

````bash
$ gem install bundler
````

Install thinking-sphinx, memcached, and imagemagick

````bash
$ sudo aptitude install sphinxsearch memcached imagemagick
````

You will also need to have an smtpd running on the machine.

Set up your-priorities
----------------------------

````bash
$ git clone https://github.com/rbjarnason/your-priorities.git
$ cd your-priorities
````

Install all the dependencies

````bash
$ bundle install
````

Modify database.yml and fill in your MySQL database credentials

````bash
$ $EDITOR config/database.yml
````

Then create and seed the database

````bash
bundle exec rake db:drop db:create db:schema:load tr8n:import_db db:seed --trace
````

Recreate tr8n from scratch

````bash

rake tr8n:init tr8n:import_and_setup_iso_3166
````

Run your-priorities
-------------------------

Finally, start the rails server:

````bash
$ rails server
````

Testing your-priorities
-------------------------

First set up the test database and start the test server

````bash
$ RAILS_ENV=test bundle exec rake db:drop db:create db:schema:load tr8n:init tr8n:import_and_setup_iso_3166
$ bundle exec rails server -e test
````

Then run the tests

````bash
# run all tests
$ bundle exec rake test

# run one test
$ bundle exec ruby -Ilib:test test/integration/navigation.rb
````

Deploying your-priorities
---------------------------

Install RVM, Ruby, Bundler, and thinking-sphinx on your server(s) as described
above.

Set up Phusion Passenger as described by http://www.modrails.com/install.html.

Edit config/deploy.rb to fit your server configuration.

Setup the deployment environment:

````bash
$ bundle exec cap deploy:setup
````

Then copy `config/database.yml`, `config/newrelic.yml`, and `config/facebooker.yml`
to `sites/your-priorities/shared/` on the app server(s)

Then deploy the application:

````bash
$ bundle exec cap deploy
````

Your Priorities is a merge between:

NationBuilder by Jim Gilliam http://www.jimgilliam.com/ and Open Direct Democracy by Róbert Viðar Bjarnason and Gunnar Grimsson http://github.com/rbjarnason/open-direct-democracy
