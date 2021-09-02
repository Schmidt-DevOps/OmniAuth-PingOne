# OmniAuth PingOne

[![Build Status](https://travis-ci.org/ping-one/omniauth-pingone.svg?branch=master)](https://travis-ci.org/ping-one/omniauth-ping-one)


[OmniAuth](https://github.com/Schmidt-DevOps/OmniAuth-PingOne) strategy for authenticating
PingOne users.

Mount this with your Rails app to simplify the
[OAuth flow with PingOne](https://admin.pingone.com/web-portal/login).

This is intended for apps already using OmniAuth, for apps that authenticate
against more than one service (eg: PingOne and GitHub).

## Configuration

OmniAuth works as a Rack middleware. Mount this PingOne adapter with:

## Usage

### Install/Set up dev env

```bash
bundle install --binstubs
docker build . -t sdo_omniauth_ping_one
docker run --rm sdo_omniauth_ping_one 
```

### OAuth scopes

[PingOne supports different OAuth scopes][oauth-scopes]. 

[oauth-scopes]: https://docs.pingidentity.com/bundle/pingfederate-93/page/gtr1564002990929.html

## Example - Rails

Your `.env`:
``` 
OAUTH_PING_ONE_CLIENT_ID="<set_client_id_here>"
OAUTH_PING_ONE_CLIENT_SECRET="<set_client_secret_here>"
OAUTH_PING_ONE_SITE="https://sso.connect.pingidentity.com"
OAUTH_PING_ONE_REDIRECT_URI="https://your.host.example.com/auth/ping_one/callback"
OAUTH_PING_ONE_ENV_PATH="/sso"
```

Note that not all Ping instances have a Ping environment set but use hostnames to differentiate Ping environments (not to be confused with Rails environment for example). In this case, omit `OAUTH_PING_ONE_ENV_PATH`. Otherwise set the Ping ID environment ID here with a slash prepended, because the Ping environment ID is part of the endpoint URIs.

Under `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
    provider :ping_one, ENV['OAUTH_PING_ONE_CLIENT_ID'], ENV['OAUTH_PING_ONE_CLIENT_SECRET'], {
        :pkce => false,
        :client_options => {
            site: ENV['OAUTH_PING_ONE_SITE'],
            redirect_uri: ENV['OAUTH_PING_ONE_REDIRECT_URI'],
            authorize_url: "#{ENV['OAUTH_PING_ONE_ENV_PATH']}/as/authorization.oauth2",
            token_url: "#{ENV['OAUTH_PING_ONE_ENV_PATH']}/as/token.oauth2",
            user_url: "#{ENV['OAUTH_PING_ONE_ENV_PATH']}/idp/userinfo.openid"
        },
        :scopes => ["profile", "email", "openid"],
        name: :ping_one,
        setup: false,
    } 
end
```

Then add to `config/routes.rb`:

```ruby
# Named routes for OAuth cycle, b/c OmniAuth does not seem to provide named routes
post "/auth/:provider", to: lambda{ |env| [404, {}, ["Route not Found"]] }, as: :oauth_start
get '/auth/:provider/callback', to: 'sessions#create', as: :oauth_callback
post '/auth/failure', to: 'sessions#auth_failure'
```

Controller support:

```ruby
# Note: this is not supposed to be a "copy&paste&forget"-kind-of example. 
# It is supposed to give you an idea what you'd probably want to change in your sessions controller.
class SessionsController < ApplicationController
    def new
        # No need for anything in here, we are just going to render our
        # new.html.erb AKA the login page
    end

    def create
        auth_hash ? create_oauth_session : create_regular_session
    end

    def auth_failure
        # On OAuth error (e.g. invalid secret) 'omniauth-rails_csrf_protection' intercepts this call with
        # an CSRF error so it's not that easy to access the actual error here.
        # Show at least a generic message. The actual error is in the logs.
        render(:file => Rails.root.join('public', '401'), :formats => [:html], :status => 401, :layout => 'error')
    end

    private

    def auth_hash
        request.env['omniauth.auth']
    end

    # Look up User in db by the UID and email address provided by OAuth
    # Note: If multiple OIDC providers are configured make sure their UIDs to not conflict.
    def create_oauth_session
        logger.debug "create_oauth_session:" + auth_hash.slice('provider', 'uid', 'info', 'extra').to_s # do not log the token

        # Email address is still the main identifier for users, for example when invalidating accounts on DEV/STAGE.
        user = User.find_by(uid: auth_hash.uid, email: auth_hash.info.email.downcase)

        if user
            session[:user_id] = user.id.to_s
            # redirect to home
            redirect_to dashboard_path, notice: t('forms.login.loggedin', user: user.name)
        else
            flash.now[:error] = t('forms.login.denied_ping_one')
            render :new
        end
    end

    # Look up User in db by the UID and email address provided the user via login form
    def create_regular_session
    # ...
    end
end
```

The view (note that for security reasons the OAuth login cycle [*begins* with a POST request][omniauth-rails_csrf_protection]):

```erb
<h1>Your PingOne OAuth cycle start:</h1>

<%= bootstrap_form_with method: :post, url: oauth_start_path('ping_one'), local: true do |f| %>
    <%= f.submit t('forms.login.submit_sso.ping_one' ), class: "btn btn-primary btn-block" %>
<% end %>
```

[omniauth-rails_csrf_protection]: https://github.com/cookpad/omniauth-rails_csrf_protection
