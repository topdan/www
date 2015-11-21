* [Introduction](#introduction)
* [Demo](#demo)
* [How it Works](#how-it-works)
* [The Code](#the-code)
* [Wrap-up](#wrapup)

## [Introduction](#introduction)

Toggle buttons are useful for communicating and changing state. Here's what the user sees:

```raw
<ul class="user-experience">
  <li>Clicks on <a href="#" class="btn"><i class="icon-star">&nbsp;</i> Favorite</a></li>
  <li>An ajax request is started and the button becomes <a href="#" class="btn"><i class="icon-refresh">&nbsp;</i> Favorite</a></li>
  <li>When the request succeeds the button becomes <a href="#" class="btn btn-warning"><i class="icon-star">&nbsp;</i> Favorite</a></li>
</ul>
```

This pattern presents itself in every one of my applications, so I wanted to document how I implement it in Ruby on Rails, as it is a good introduction to ajax, unobtrusive javascript, and Rails handling javascript requests.

## [Demo](#demo)

```raw
<p class="alert alert-info">
  Click the buttons below and look at your web-developer tools for the ajax responses and <code>class</code> attribute changes, but note this site runs on a static webserver, so the state is not saved, and the paths and HTTP methods don't mirror an actual Ruby on Rails application.
</p>

<div id="post-1" class="my-post">
  <p class="actions">
    <a href="/assets/static/ruby-on-rails/ajax-toggle-buttons/1/favorite/put.js" data-method="GET" data-remote="true" data-type="script" class="btn favorite"><i class="icon-star">&nbsp;</i> Favorite</a>
    <a href="/assets/static/ruby-on-rails/ajax-toggle-buttons/1/favorite/delete.js" data-method="GET" data-remote="true" data-type="script" class="btn btn-warning unfavorite"><i class="icon-star">&nbsp;</i> Favorite</a>

    <a href="/assets/static/ruby-on-rails/ajax-toggle-buttons/1/lock/put.js" data-method="GET" data-remote="true" data-type="script" class="btn lock"><i class="icon-lock">&nbsp;</i> Locked</a>
    <a href="/assets/static/ruby-on-rails/ajax-toggle-buttons/1/lock/delete.js" data-method="GET" data-remote="true" data-type="script" class="btn btn-danger unlock"><i class="icon-lock">&nbsp;</i> Locked</a>
  </p>
</div>

```

## [How it Works](#how-it-works)

1. Each toggle button is actually [two buttons](#erb) ("on" and "off") with a parent [CSS class](#stylesheet) determining which is visible.
2. Each button has an `href` along with `data-method`, `data-type=script`, and `data-remote=true` attributes, which instruct `jquery_ujs.js` to perform an ajax request and evaluate the result as javascript.
3. When the user clicks either button, [a jQuery listener](#loading-js) switches to the loading icon while another listener switches it back on completion.
4. In Rails, [the main resource has a child](#routes) which provides `#update` and `#destroy` actions for [toggling on and off](#controller) respectively.
5. After saving the change, Rails responds with one line of javascript that [adds](#update-js) or [removes](#destroy-js) the parent element's class switching the visible button.

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

  protected

    def load_post
      @post = Post.find(params[:post_id])
    end

end
```

### [](#application-helper)
```ruby
# helpers/application_helper.rb
module ApplicationHelper

  def link_to_with_icon(icon_css, title, url, options = {})
    icon = content_tag(:i, nil, class: icon_css)
    title_with_icon = icon << ' ' << title
    link_to(title_with_icon, url, options)
  end

  def toggle_button_to(icon_css, title, url, options = {})
    on_options = {
      'data-remote' => true,
      'data-type' => 'script',
      'data-method' => 'PUT',
      class: options[:on]
    }

    off_options = {
      'data-remote' => true,
      'data-type' => 'script',
      'data-method' => 'DELETE',
      class: options[:off]
    }

    on_link = link_to_with_icon(icon_css, title, url, on_options)
    off_link = link_to_with_icon(icon_css, title, url, off_options)

    on_link << off_link
  end

end
```

### [](#helper)
```ruby
# helpers/posts_helper.rb
module PostsHelper

  def post_css(post)
    'favorite' if post.favorited?
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

### [](#stylesheet)
```
/* assets/stylesheets/posts.css.scss */
.post {
  /* off by default */
  .unfavorite { display: none; }
}

/* when the post is favorited show the unfavorite button instead */
.post.favorited {
  .favorite { display: none; }
  .unfavorite { display: inline-block; }
}
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

  <%# This outputs two buttons which CSS rules make
      sure only one is visible at a time %>
  <%= toggle_button_to 'icon-star', 'Favorite', post_favorite_path(@post),
       on: 'favorite btn',
       off: 'unfavorite btn btn-primary' %>

<% end %>
```

### [](#update-js)
```javascript
/* views/posts/favorites/update.js.erb */
$('#post-<%= @post.id %>').addClass('favorited');
```

### [](#destroy-js)
```javascript
/* views/posts/favorites/destroy.js.erb */
$('#post-<%= @post.id %>').removeClass('favorited');
```

## [Wrap-up](#wrapup)

The only thing changing on the client-side is the loading icon and adding/removing the `class=favorited`.

We follow "The Rails' Way" to `#update` and `#destroy` in the controller, which will help the application gracefully grow when we add more functionality to posts like additional toggles, fields, or a public RESTful API.

If your application doesn't require javascript, then you'll want to change `#toggle_button_to` to output inline forms instead of links, and make the Rails controller redirect inside `format.html`.

Let me know what else you think could be improved.
