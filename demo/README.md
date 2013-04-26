QuickScript Demo - Todo List
============================

This demo is an example of a Rails application using QuickScript to build a simple TodoList web app. It uses a local sqlite db as its development database, so it should be fully deployable locally. Follow the instructions below to get it up and running.

Local Deployment
----------------

1. Clone this repository

		git clone git@github.com:agquick/quick_script.git

2. CD to the app folder in demo

		cd quick_script/demo

3. Install necessary rubygems

		bundle install

4. Run the migration

		rake db:migrate

5. Start web server

		rails s -p 3000


