* [Introduction](#introduction)
* [Demo](#demo)
* [How it Works](#how-it-works)
* [The Code](#the-code)
* [Wrap-up](#wrapup)

## [Introduction](#introduction)

Infinite scrolling appends more content to the end of the page before the viewer gets to it, so they can just keep scrolling unabated and the application doesn't need to initially load a bunch of records only a small percent of viewers will ever scroll down to.

## [Demo](#demo)

```raw
<p>
  The scrollable pane of movie posters automatically adds more rows of posters as you approach the bottom of the page.
</p>

<div id="demo-infinite-scrolling" class="posters b-ccc pt-1e pb-1e pl-1e pr-1e" data-movies-url="/entertainment/movie-recommendations.json" data-per-page="16" data-per-row="4" data-threshold="1000">
  <% Post.find('movie_recommendations').data[0..15].in_groups_of(4).each do |row| %>
    <div class="page-row">
      <% row.compact.each do |movie| %>
        <%= image_tag movie.poster_url %>
      <% end %>
    </div>
  <% end %>

  <p><a href="#" data-action="load-next-page"><span class="fa fa-refresh fa-spin">&nbsp;</span> View next page <span class="fa fa-refresh fa-spin">&nbsp;</span></a></p>
</div>

<p class="fs-12 c-ccc center">This webpage is not hosted by Rails, so the above UX is just a simulation.</p>
```

### [How it Works](#how-it-works)

* Rails renders [the first page and a "View More" link](#views) during the initial HTML request.
* The "View More" link is a UI fallback but also lets us know the URL for the next page.
* [Javascript](#javascript) watches the page's scrollbar to break a threshold.
* An AJAX request is issued when either the threshold is broken or the user clicks the "View More" link.
* Rails returns javascript that inserts the next page and points the "View More" link to the next unloaded page.

### [The Code](#the-code)

### [](#gemfile)

```ruby
# Gemfile

gem 'kaminari'
# gem 'will_paginate' # another option
```

### [](#controller)
```ruby
# controllers/posts_controller.rb
class PostsController < ApplicationController

  def index
    @posts = Post.order(published_at: :desc).page(params[:page]).per(25)
  end

end
```

### [](#views)
```
<!-- views/posts/index.html.erb -->
<div id="content">
  <%= render(partial: 'post', collection: @posts) %>
</div>

<% unless @posts.current_page == @posts.total_pages %>
  <p id="view-more">
    <%= link_to('View More', url_for(page: @posts.current_page + 1), remote: true) %>
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

```javascript
// views/posts/index.js.erb
$('#content').append("<%=j render(partial: 'post', collection: @posts, format: 'html') %>");

<% if @posts.current_page == @posts.total_pages %>
  $('#view-more').remove();
<% else %>
  $('#view-more a').attr('href', '<%= url_for(page: @posts.current_page + 1) %>');
<% end %>
```

### [](#javascript)
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

## [Wrap-up](#wrapup)

Simple enough? Rails returning javascript simplifies the client-side code significantly. Your HTML won't be exactly like mine, but the jQuery and Rails code should be straight-forward enough for you to tailor it to your own infinite scrolling page.
