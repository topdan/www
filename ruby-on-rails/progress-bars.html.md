* [Introduction](#introduction)
* [Demo](#demo)
* [How it Works](#how-it-works)
* [The Code](#the-code)
* [Wrap-up](#wrapup)

## [Introduction](#introduction)

Progress Bars are essential for long-running tasks that require communication to the user their request was received and is being processed. For example, many applications allow importing spreadsheets or CSV files which could take several minutes to process. These applications save the uploaded file, start a background worker, and allow the client to track its progress.

Two approaches handle this problem: pinging and [websockets](https://github.com/rails/actioncable). Here, I'll tackle the simpler pinging approach.

## [Demo](#demo)

```raw
<p>Click to the following button to see the progress bar go <a id="start" href="#" class="btn btn-primary btn-sm">Start</a> </p>

<div id="demo-progress" class="b-ccc bra-5 pt-1e pb-1e pl-1e pr-1e">
  <div class="progress progress-striped">
    <div class="progress-bar" style="width: 0%;">0%</div>
  </div>
  <div class="message fw-bold center monospace">Not Running...</div>
</div>

<p class="fs-12 c-ccc center">This webpage is not hosted by Rails, so the above UX is just a simulation.</p>
```

## [How it Works](#how-it-works)

1. When start is clicked, `jquery_ujs.js` recognizes its `data-remote` and `data-type` attributes and requests javascript from Rails via AJAX.
2. Rails receives the request, passes a new `progress_bar` into `ActiveJob` and returns javascript that starts asking Rails for updates.
3. The `ActiveJob` updates `progress_bar.message` and `progress_bar.percent` as it processes the data until it finishes.
4. When `progress_bar.percent == 100` the javascript stops asking Rails for updates.

## [The Code](#the-code)

### [](#model)
```ruby
# app/models/progress_bar.rb
class ProgressBar < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id, :message

  validates_numericality_of :percent,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
end
```

### [](migration)
```ruby
# rails g migration create_progress_bars
class CreateProgressBars < ActiveRecord::Migration[5.0]
  def change
    create_table :progress_bars do |t|
      t.text    :message
      t.integer :percent
      t.integer :user_id
      t.timestamps null: false
    end
    add_index :progress_bars, :user_id
  end
end
```

### [](#routes)
```ruby
# config/routes.rb
resources :progress_bars, only: 'show'
resources :demos, only: %w(new create)
```

### [](#demo-controller)
```ruby
# app/controllers/demos_controller.rb
class DemosController < ApplicationController

  def create
    @progress_bar = current_user.progress_bars.create!(message: 'Queued', percent: 0)
    DemoWorker.perform_later(@progress_bar)
  end

end
```

### [](#demo-new)
```erb
<!-- app/views/demos/new.html.erb -->
<div id="demo" data-ping-time="1000">
  <%= link_to 'Start', url_for(action: 'create'), 'data-remote' => true, 'data-type' => 'script' %>

  <div class="progress">
    <div class="progress-bar" style="width: 0%;"></div>
  </div>

  <div class="message">Not Running...</div>
</div>
```

### [](#demo-create)
```javascript
// app/views/demos/create.js.erb
(function() {
  var progressBar = new ProgressBar("#demo", "<%= progress_bar_path @progress_bar %>");
  progressBar.start();
})();
```

### [](#progress-bar)
```coffee
# app/assets/javascripts/progress_bar.coffee
class @ProgressBar
  constructor: (elem, url) ->
    @elem = $(elem)
    @url = url

    @message = @elem.find('.message')
    @bar = @elem.find('.progress-bar')
    @pingTime = parseInt(@elem.data('ping-time'))

  start: =>
    $.ajax({
      url: @url,
      dataType: 'json',
      success: (data) =>
        @message.html(data.message)

        percent = "#{data.percent}%"
        @bar.css('width', percent).html(percent)

        if data.percent < 100
          setTimeout(@start, @pingTime)
    })
```


### [](#progress-bars-controller)
```ruby
# app/controllers/progress_bars_controller.rb
class ProgressBarsController < ApplicationController

  def show
    @progress_bar = current_user.progress_bars.find(params[:id])
    render json: @progress_bar
  end

end
```

### [](#demo-worker)
```ruby
# app/workers/demo_worker.rb
class DemoWorker < ActiveJob::Base

  def perform(progress_bar)
    @progress_bars.update_attributes!({
      message: 'Working ...',
      percent: 0
    })

    10.times do |i|
      sleep(1)
      @progress_bar.update_attributes!(percent: i * 10)
    end

    @progress_bars.update_attributes!({
      message: 'Finished!',
      percent: 0
    })
  end

end
```

## [Wrap-up](#wrapup)

Get all that? The button inside `demos#new` invokes `#create` via AJAX, starting a client-side pinging of `progress_bars#show` while `demo_worker#perform` runs in the background.

Of course it's just a demo. A real worker would do something useful like import a data file. Here are a few more thoughts:

* Should you use [Redis](http://redis.io/) for ephemeral data like progress bars?
* How do you notify the user of errors that may occur inside your worker?
* Do you want the progress bar to popup in a [modal](http://www.w3schools.com/bootstrap/bootstrap_modal.asp)?
* Would you allow multiple progress bars on the same screen?
* Can the user cancel the background process?

All easily built on top of this initial implementation, but I'll leave them to you. Feel free to contact me with any questions or comments at [dan@topdan.com](mailto:dan@topdan.com).
