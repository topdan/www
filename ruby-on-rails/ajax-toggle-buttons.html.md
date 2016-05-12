* [Introduction](#introduction)
* [Demo](#demo)
* [How it Works](#how-it-works)
* [The Code](#the-code)
* [Wrap-up](#wrapup)

## [Introduction](#introduction)

Toggle buttons are useful for communicating and changing state. Here's what the user sees:

```raw
<ul class="user-experience">
  <li>Clicks on <a href="#" class="btn btn-default"><span class="fa fa-star">&nbsp;</span> Favorite</a></li>
  <li>An ajax request is started and the button becomes <a href="#" class="btn btn-default"><span class="fa fa-refresh">&nbsp;</span> Favorite</a></li>
  <li>When the request succeeds the button becomes <a href="#" class="btn btn-warning"><span class="fa fa-star">&nbsp;</span> Favorite</a></li>
</ul>
```

This pattern presents itself in every one of my applications, so I wanted to document how I implement it in Ruby on Rails, as it is a good introduction to ajax, unobtrusive javascript, and Rails handling javascript requests.

## [Demo](#demo)

```raw
<p class="alert alert-info">
  Click the buttons below and look at your web-developer tools for how the ajax response swaps the links, but note this site runs on a static webserver, so the paths and HTTP methods don't mirror an actual Ruby on Rails application.
</p>

<div id="post-1" class="my-post">
  <p class="actions">
    <a href="/assets/static/ruby-on-rails/ajax-toggle-buttons/1/favorite/put.js" data-method="GET" data-remote="true" data-type="script" class="btn btn-default favorite"><span class="fa fa-star">&nbsp;</span> Favorite</a>

    <a href="/assets/static/ruby-on-rails/ajax-toggle-buttons/1/lock/delete.js" data-method="GET" data-remote="true" data-type="script" class="btn btn-danger lock"><span class="fa fa-lock">&nbsp;</span> Locked</a>
  </p>
</div>

```

## [How it Works](#how-it-works)

1. A Rails helper method renders the button in its current state.
1. This button has an `href` along with `data-method`, `data-type=script`, and `data-remote=true` attributes which instruct `jquery_ujs.js` to perform an ajax request and evaluate the result as javascript.
1. When the user clicks either button, [a jQuery listener](#loading-js) switches to the loading icon while another listener switches it back on completion.
1. In Rails, [the main resource has a child](#routes) which provides `#update` and `#destroy` actions for [toggling on and off](#controller) respectively.
1. After saving the change, Rails responds with one line of javascript that [replaces the button with its new state](#update-js).

## [The Code](#the-code)

### [](#model)
```ruby
# models/post.rb
class Post < ActiveRecord::Base

  def favorited?
    favorited_at != nil
  end

  def favorite
    self.favorited_at = Time.now
  end

  def favorite!
    favorite
    save!
  end

  def unfavorite
    self.favorited_at = nil
  end

  def unfavorite!
    unfavorite
    save!
  end

end
```

### [](#routes)
```ruby
# config/routes.rb
resources :posts do
  resource :favorite, only: %w(update destroy)
end
```

### [](#controller)
```ruby
# controllers/posts/favorites_controller.rb
class Posts::FavoritesController < ApplicationController

  before_action :load_post

  def update
    @post.favorite!
  end

  def destroy
    @post.unfavorite!
  end

  private

  def load_post
    @post = Post.find(params[:post_id])
  end

end
```

### [](#application-helper)
```ruby
# helpers/posts_helper.rb
module PostsHelper

  def link_to_toggle_post_favorite(post)
    url = post_favorite_path(post)

    if post.favorited?
      link_to_with_icon('icon-star', 'Favorite', url, {
        method: 'DELETE',
        remote: true,
        class: 'favorite btn btn-primary',
      })
    else
      link_to_with_icon('icon-star', 'Favorite', url, {
        method: 'PUT',
        remote: true,
        class: 'favorite btn',
      })
    end
  end

  def link_to_with_icon(icon_css, title, url, options = {})
    icon = content_tag(:i, nil, class: icon_css)
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
//= require_tree .
```

### [](#loading-js)
```javascript
/* assets/javascripts/loading.js */

// This isn't necessarily specific to toggle buttons
$(function() {

  // Change the link's icon while the request is performing
  $('a[data-remote]').on('click', function(event, b, c) {
    var icon = $(this).find('i');
    icon.data('old-class', icon.attr('class'));
    icon.attr('class', 'icon-refresh');
  });

  // Change the link's icon back after it's finished.
  $(document).on('ajax:complete', function(e) {
    var icon = $(e.target).find('i');
    if (icon.data('old-class')) {
      icon.attr('class', icon.data('old-class'));
      icon.data('old-class', null);
    }
  })

  // Don't fail silently
  $(document).ajaxError(function( event, jqxhr, settings, exception ) {
    if (jqxhr.status) {
      alert("We're sorry, but something went wrong (" + jqxhr.status + ')');
    }
  });

})

```

### [](#erb)
```erb
<%# views/posts/show.html.erb %>
<%= div_for(@post, class: post_css(@post)) do %>
  <%= link_to_toggle_post_favorite @post %>
<% end %>
```

### [](#update-js)
```javascript
/* views/posts/favorites/update.js.erb */
$('#post-<%= @post.id %> .favorite').replaceWith("<%=j link_to_toggle_post_favorite @post %>");
```

### [](#destroy-js)
```javascript
/* views/posts/favorites/destroy.js.erb */
$('#post-<%= @post.id %> .favorite').replaceWith("<%=j link_to_toggle_post_favorite @post %>");
```

## [Wrap-up](#wrapup)

Unobtrusive javascript allows the application logic to stay in Ruby.

We follow "The Rails' Way" to `#update` and `#destroy` in the controller, which will help the application gracefully grow when we add more functionality to posts like additional toggles, fields, or a public RESTful API.

Let me know what else you think could be improved.
