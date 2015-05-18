* [Introduction](#introduction)
* [How it Works](#how-it-works)
  * [Gemfile](#gemfile)
  * [Controller](#controller)
  * [HTML Templates](#html-templates)
  * [Client-Side Javascript](#javascript)
  * [Javascript Template](#post-js)
* [Wrap-up](#wrapup)

## [Introduction](#introduction)

Infinite scrolling appends more content to the end of the page before the viewer gets to it, so they can just keep scrolling unabated and the application doesn't need to initially load a bunch of records only a small percent of viewers will ever scroll down to.

## [How it Works](#how-it-works)

```raw
<p class="alert alert-info">
  <strong>Summary: </strong> Rails renders the HTML like always, but there's a javascript file that watches the scrollbar and fires off an ajax request that returns some javascript that appends new content.
</p>
```

### [Gemfile](#gemfile)

ActiveRecord has [a lot of pagination gems](https://www.ruby-toolbox.com/categories/pagination) that groups your records into pages.

```ruby
# Gemfile

gem 'kaminari'
# gem 'will_paginate'
```

#### [Controller](#controller)
Your controller queries the page param or the first page if not provided.

```ruby
# controllers/posts_controller.rb
class PostsController < ApplicationController

  def index
    @posts = Post.order('published_at desc').page(params[:page]).per(25)
  end

end
```

#### [HTML Templates](#html-templates)
HTML requests will render like they normally do, along with a "View More" link to load the next page. You can use the `paginate` view helper method provided by your gem, but I want to be explicit about the CSS classes here.

```
<!-- views/posts/index.html.erb -->
<div id="content">
  <%= render(partial: 'post', collection: @posts) %>
</div>

<% unless @posts.current_page == @posts.total_pages %>
  <p id="view-more">
    <%= link_to('View More', url_for(page: @posts.current_page + 1)) %>
  </p>
<% end %>
```

```
<!-- views/posts/_post.html.erb -->
<%= div_for(post) do %>
  <h2><%= post.title %></h2>
  <p><%= post.excerpt %></p>
<% end %>
```

#### [Client-Side Javascript](#javascript)

Client-side javascript watches for when the scrollbar gets towards the bottom and ajax-requests javascript using the "View More" link's URL along with a failsafe for requesting pages too quickly and allowing the viewer to paginate manually.

```coffee
# assets/javascripts/infinite-scroll.js.coffee
$ ->
  content = $('#content')    # where to load new content
  viewMore = $('#view-more') # tag containing the "View More" link

  isLoadingNextPage = false  # keep from loading two pages at once
  lastLoadAt = null          # when you loaded the last page
  minTimeBetweenPages = 5000 # milliseconds to wait between loading pages
  loadNextPageAt = 1000      # pixels above the bottom

  waitedLongEnoughBetweenPages = ->
    return lastLoadAt == null || new Date() - lastLoadAt > minTimeBetweenPages

  approachingBottomOfPage = ->
    return document.documentElement.clientHeight +
        $(document).scrollTop() < document.body.offsetHeight - loadNextPageAt

  nextPage = ->
    url = viewMore.find('a').attr('href')

    return if isLoadingNextPage || !url

    viewMore.addClass('loading')
    isLoadingNextPage = true
    lastLoadAt = new Date()

    $.ajax({
      url: url,
      method: 'GET',
      dataType: 'script',
      success: ->
        viewMore.removeClass('loading');
        isLoadingNextPage = false;
        lastLoadAt = new Date();
    })

  # watch the scrollbar
  $(window).scroll ->
    if approachingBottomOfPage() && waitedLongEnoughBetweenPages()
      nextPage()

  # failsafe in case the user gets to the bottom
  # without infinite scrolling taking affect.
  viewMore.find('a').click (e) ->
    nextPage()
    e.preventDefaults()
```

#### [Javascript Template](#post-js)

The Rails controller remains unchanged, but since the ajax call is requesting javascript it renders `index.js.erb` instead of `index.html.erb`. This template appends the new posts to the page and updates the "View More" link URL. When the viewer reaches the last page, it removes the "View More" link and the client-side javascript stops requesting more pages.

```javascript
// views/posts/index.js.erb
$('#content').append("<%=j render(partial: 'post', collection: @posts, format: 'html') %>");

<% if @posts.current_page == @posts.total_pages %>
  $('#view-more').remove();
<% else %>
  $('#view-more a').attr('href', '<%= url_for(page: @posts.current_page + 1) %>');
<% end %>
```


## [Wrap-up](#wrapup)

Simple right? Rails returning javascript simplifies the client-side code significantly. Your HTML may not be exactly like mine, but the jQuery and Rails code should be straight-forward enough for you to tailor it to your web design.
