```raw
<p class="alert alert-info">
  This design issue was addressed in Rails 5.0. <a href="http://blog.bigbinary.com/2016/02/13/rails-5-does-not-halt-callback-chain-when-false-is-returned.html">Read more about the change here</a>
</p>
```

* [The Code](#the-code)
* [The Problem](#the-problem)
* [The Feature](#the-feature)
* [The Fix](#the-fix)

### [The Code](#the-code)

The following class combines multiple attributes into one boolean attribute. Most of the time it's an optimization, but sometimes it's mandatory because the boolean calculation can't be expressed in SQL.

```raw
<p class="alert alert-danger center mt-2e"><strong>Can you spot the bug?</strong></p>
```

```ruby
class Movie < ActiveRecord::Base

  validates_presence_of :title

  scope :streaming, lambda { where(is_streaming: true) }

  before_save :autoset_is_streaming

  def on_netflix_instant?
    netflix_instant_url != nil
  end

  def on_hulu?
    hulu_url != nil
  end

  def on_youtube?
    youtube_url != nil
  end

  protected

    def autoset_is_streaming
      self.is_streaming = on_netflix_instant? || on_hulu? || on_youtube?
    end

end
```

### [The Problem](#the-problem)

Your movie class is working great as you read in a bunch of streaming movies, but eventually the movies won't save, so you jump into the console:

```ruby
> Movie.create!(title: 'Grand Budapest Hotel')
   (0.2ms)  BEGIN
   (0.2ms)  ROLLBACK
ActiveRecord::RecordNotSaved: ActiveRecord::RecordNotSaved
> movie = Movie.new(title: 'Grand Budapest Hotel')
> movie.valid?
 => true
> movie.save
   (0.2ms)  BEGIN
   (0.2ms)  ROLLBACK
 => false
> movie.save!
   (0.2ms)  BEGIN
   (0.2ms)  ROLLBACK
ActiveRecord::RecordNotSaved: ActiveRecord::RecordNotSaved
> movie.errors.full_messages
 => []
```

The movie is valid, but it doesn't save? What's is going on?

### [The Feature](#the-feature)

The bug is caused by an [ActiveRecord feature called "Canceling Callbacks"](http://api.rubyonrails.org/classes/ActiveRecord/Callbacks.html):

```raw
<p class="alert alert-info">
  If a before_* callback returns false, all the later callbacks and the associated action are cancelled.
</p>
```

The example code is setting the `is_streaming` attribute to `false`, and thanks to ruby's non-explicit returns, the function returns `false`, canceling the save. No validation errors are stored because the validation passed.

### [The Fix](#the-fix)

Once you uncover the issue, the fix is simple:

```ruby
def autoset_is_streaming
  self.is_streaming = on_netflix_instant? || on_hulu? || on_youtube?
  true
end
```

`nil` would work too, but I prefer `true` indicating the value was successfully set. After running into this problem occasionally in my first couple years of Ruby on Rails programming, I engrained this thought process into my `ActiveRecord` programming:

* Writing a `before_*` callback?
* Could it return `false`?
* __Don't! `return true`!__

I see how canceling an `ActiveRecord` action is useful, but __I always cancel it with validation errors or exceptions__. Anyway, I hope you learned something and maybe avoided some future head-scratching.
