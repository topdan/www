* [Introduction](#introduction)
* [Demo](#demo)
* [How it Works](#how-it-works)
* [The Code](#the-code)
* [Wrap-up](#wrapup)

## [Introduction](#introduction)

Loading buttons are a common user-experience concept used to indicate the state between starting and completing an action. They are most useful when server-side logic decides what happens next, such as displaying validation errors or a success message.

<a href="https://en.wikipedia.org/wiki/Single-page_application">Single page applications</a> may bypass loading buttons to appear more responsive since they use client-side logic, but loading buttons still play a large role in the standard MVC Rails application.

```raw
<div id="user-experience">
  <p class="mt-2e"><a href="#" class="btn btn-primary"><span class="fa fa-sign-out">&nbsp;</span> Log out</a> represents an action for the user to perform.</p>
  <p class="mb-2e"><a href="#" class="btn btn-primary" data-disabled><span class="fa fa-refresh fa-spin">&nbsp;</span> Log out</a> indicates the action in processing via a loading icon and disabled button.</p>
</div>
```

## [Demo](#demo)

```raw
<p class="center">Click the buttons below for a live demonstration.</p>

<div id="demo-buttons" class="center pt-1e pb-1e pl-1e pr-1e">
  <a href="#" class="btn btn-default favorite"><span class="fa fa-star">&nbsp;</span> Favorite</a>
  <a href="#" class="btn btn-primary log-out"><span class="fa fa-sign-out">&nbsp;</span> Log out</a>
</div>

<p class="fs-12 c-ccc center">This webpage is not hosted by Rails, so the above UX is just a simulation.<br>A "Log out" button would normally redirect you to the sign-in page.</p>
```

## [How it Works](#how-it-works)

1. A Rails helper method renders a button with `data-remote=true` and `data-loading=true` attributes.
1. `data-remote=true` instructs `jquery_ujs.js` to begin an ajax request.
1. `data-loading=true` instructs [a jQuery listener](#loading-js) to disable the button and insert a spinner.
1. Your Rails application determines what happens after the request finishes:
  * Reset the button's state
  * Redirect to another page

## [The Code](#the-code)

### [](#routes)
```ruby
# config/routes.rb
resources :sessions, only: %w(new destroy)
```

### [](#controller)
```ruby
# controllers/sessions_controller.rb
class SessionsController < ApplicationController

  def destroy
    reset_session
  end

end
```

### [](#application-helper)
```ruby
# helpers/sessions_helper.rb
module SessionsHelper
  def link_to_log_out
    link_to_with_icon('sign-out', 'Log out', url, {
      method: 'DELETE',
      remote: true,
      class: 'btn btn-primary',
      data: {loading: true}
    })
  end
end

# helpers/layouts_helper.rb
module LayoutsHelper
  def link_to_with_icon(icon, title, url, options = {})
    icon = content_tag(:span, nil, class: "fa fa-#{icon}")
    title_with_icon = icon << ' '.html_safe << h(title)
    link_to(title_with_icon, url, options)
  end
end
```

### [](#gemfile)
```ruby
# Gemfile
gem 'jquery-rails'
```

### [](#application-js)
```javascript
// assets/javascript/application.js
//
// jquery_ujs allows us to use 'data-remote',
// 'data-type', and 'data-method' attributes
//
//= require jquery
//= require jquery_ujs
//= require loading
```

### [](#loading-js)
```coffeescript
# assets/javascripts/loading.coffee
$ ->
  # Insert a spinner and disable the button
  $(document).on('click', 'a[data-loading]', (e) ->
    $(this).attr('disabled', 'disabled')
    $(this).find('.fa:first').attr('class', 'fa-refresh fa-spin')
```

### [](#erb)
```erb
<%# views/layouts/application.html.erb %>
<%= link_to_log_out %>
```

### [](#destroy-js)
```javascript
/* views/sessions/destroy.js.erb */
Turbolinks.visit("<%= new_session_path %>");
```

## [Wrap-up](#wrapup)

The Rails code is rather boring, but two important user-experience concepts occur on the frontend:

1. Disabling the button prevents duplicate submissions.
1. Using a loading spinner lets the user know we started performing the action.

For further reading, <a href="ajax-toggle-buttons.html">my AJAX Toggle Buttons article</a> builds on these concepts to implement an on/off feature for buttons.
