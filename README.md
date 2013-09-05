Your Priorities is a web based platform that enables groups of people to define their democratic ideas and together discover which are the most important ideas to implement by their instances.  People can add new ideas, add arguments for and against ideas, indicate if they support or oppose an idea, create a personal list of ideas and discuss all ideas. The end results are lists of top ideas in many categories as well as the best arguments for and against each idea. This service enables people to make up their minds about most issues in a short time.

Your Priorities is being used on the https://www.yrpri.org/ eDemocracy service and the Better Reykjavik website in Iceland amongst other places.

Short new instructions
======================


Setup the project locally
=========================

Fork the project from github.com
````bash
1. Create a github account if you do not have one
2. Make sure you are logged in
3. Click the "Fork" button at the top of the page to create your own fork
````

Download / clone on your local Ubuntu installation
````bash
(replace YOURNAME with your github username)
git clone git@github.com:YOURNAME/your-priorities.git
````

Setup git to easily merge from the main branch
Add the following to the .git/config file
````bash
[remote "robert"]
        url = git@github.com:rbjarnason/your-priorities.git
        fetch = +refs/heads/*:refs/remotes/robert/*
````

Merge the latest changes from the master branch
````bash
git fetch robert
git merge robert/master
````

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

Your Priorities is a merge between:

NationBuilder by Jim Gilliam http://www.jimgilliam.com/ and Open Direct Democracy by Róbert Viðar Bjarnason and Gunnar Grimsson http://github.com/rbjarnason/open-direct-democracy
