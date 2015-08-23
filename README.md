# SpartaHack on Rails
****

This is a guide for running a local copy of SpartaHack at http://localhost:3000

**Once set up, only Postgres.app and the rails server need to be on to run the site**
    
    rails server

### Installation (Mac OS X)

##### Install homebrew
Open terminal and run the following commands in order to install Command Line Tools and homebrew

    xcode-select --install
    
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

##### Install RVM
Open terminal and run the following command

    \curl -sSL https://get.rvm.io | bash

Close and reopen terminal. Run the following commands        
    
    rvm install 2.2.1

    rvm --default use 2.1.1

And then execute:

    gem install bundle

##### Install Postgres
Run the following commands in terminal
    
    brew install postgresql
    
    gem install pg

Now go to http://postgresapp.com/ and install Postgress.app.

##### Run Postgres locally
Open the app and click on `Open psql`. A terminal window should pop up.

Run the following commands

    CREATE ROLE "pguser" NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;

    ALTER ROLE pguser WITH PASSWORD 'hello';
    
    CREATE DATABASE dev ENCODING 'UTF8';

**Postgres must be running in the background to run SpartaHack locally.**

##### Setting your Environmental Variables
Set the following environmental variables:
	export PROD_SECRET='YOUR PRODUCTION SECRET'
	
	export PARSE_API_KEY='YOUR PARSE API KEY'
	
	export PARSE_APP_ID='YOUR PARSE APP ID'
	
	export MAILCHIMP_API_KEY='YOUR MAILCHIMP API KEY'
	
	export MAILCHIMP_LIST_ID='YOUR MAILCHIMP LIST ID'


If you're a SpartaHack organizer, contact the Webmaster for the correct credentials.

##### Running SpartaHack locally

Clone Spartahack and `cd` into it.

Execute the command:

    bundle

To run the SpartaHack locally execute

    rails server
    
then navigate to http://localhost:3000



### Installation (Linux)
To do.

### Installation (Windows)
Is that a thing? To Do.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request