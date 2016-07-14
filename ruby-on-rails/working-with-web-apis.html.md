```raw
<p class="alert alert-danger">
  <span class="label label-info">Archived</span> While some of the concepts are timeless, much of this article is out-dated new modes of background processing that handles exceptions and throttling for you.
</p>
```

## [Your Goals](#goals)

Your goals when using a web service are very simple:

* Successfully make a request
* Appropriately handle the response
* __Don't break your application__

## [Handling net/http exceptions](#net_http_exceptions)

[Net::HTTP](http://ruby-doc.org/stdlib-1.9.3/libdoc/net/http/rdoc/Net/HTTP.html) throws different exceptions with different superclasses, as noted by [Tammer Saleh](http://tammersaleh.com/posts/rescuing-net-http-exceptions). If you don't catch all the different types, your application will eventually break. Luckily, the [net_http_exception_fix](https://github.com/edward/net_http_exception_fix) gem provides a simple solution, so you can catch all net/http exceptions with one type of exception:

```ruby
begin
  response = Net::HTTP.get_response("http://www.google.com/")
rescue Net::HTTPBroken => e
  # all possible ways Net::HTTP can go wrong are handled here
end
```

## [Don't Trust Web Data](#dont_trust_web_data)

All data you receive from a webserver should be suspect and handled with extreme care. The JSON might be invalid, or what you expect might be missing. Your code should clearly indicate what data it requires and raise an exception when the response is unexpected. Then it's up to the calling function to decide how to proceed.

Do not use method_missing magic on a hash parsed from a network call response. It may allow you to access the hash like a regular ruby object, but it's not a regular ruby object: it's a foreign, untrusted entity and should be accessed with extreme caution.

## [On or Off the Request Thread?](#request_thread)

Web developers need to decide whether performing the network call on the request thread is safe. If that network call timeouts your application will also timeout. In most cases, you should move it off the request thread using delayed_job or resque. If you leave it on the request thread make extra-sure to handle __all__ exceptions and lower the net/http timeout threshold or your users will eventually be staring at the 500 error screen.

```ruby
# delayed_job
user.delay.tweet_message("OMG LOL")
```

## [Database Transactions](#db_transactions)

Are your network calls occurring within a database transaction, for example in ActiveRecord callbacks? On one hand you want to ensure your records are updated correctly but on the other you'll be locking for an uncertain amount of time.

First ensure you are only locking what you need to lock then lower the network call's timeout threshold to avoid causing "Lock wait timeout exceeded" exceptions on other processes. If the network call times out, try it again later.

```ruby
http = Net::HTTP.new("www.google.com", 80)

# decrease from 60 seconds to 5 seconds
http.read_timeout = 20
```

## [Recovering from Exceptions](#recovering)

When the network call fails (and they all do eventually), your application should handle it smoothly. The easiest way is to try again later, if it fails after X tries then enter a fail-safe state.

```ruby
def tweet! retry_count = 0
  tweet = twitter_client.tweet(self.message)

  # save the success state
  update_attributes! :tweet_id => tweet.id, :tweeted_at => Time.now

rescue Net::HTTPBroken => e
  if retry_count > 5
    tweet_failsafe! e
  else
    Rails.logger.warn("net/http failure during a tweet. Trying again later: #{e.to_s}")
    delay(:run_at => Time.now + 10.seconds).tweet!(retry_count + 1)
  end
end

protected

# This class no longer knows how to handle the network problem, so
# enter a safe state and notify those involved
def tweet_failsafe! e
  # save the error state
  update_attributes! :tweet_errored_at => Time.now, :tweet_error => e.to_s

  # Log the error
  Rails.logger.error(e)

  # email the support staff
  SupportStaffMailer.network_failure(e, self).deliver

  # notify developers
  Airbrake.notify({
    :error_class => self.class.name,
    :error_message => "Trouble connecting to Twitter: #{e.to_s}"
  })

  # communicate the problem to the user
  user.notifications.create!(:text => "We ran into a problem sending your tweet. Twitter may be experiencing downtime, please try again later")
end
```

## [Throttling: Be a Good Cyber Citizen](#throttling)

Sending too many requests over a short period of time can get you blacklisted from the web service.  The easiest way to play nice is the [slowweb gem](https://github.com/benbjohnson/slowweb), which allows you to set domain-specific thresholds. But beware: it only works on one process, so it won't save you if you have multiple webservers or job runners making network calls to the same domain. It also uses Kernel#sleep, which may slow your web-crawler to a literal crawl.

```ruby
# maximum of one request per second
SlowWeb.limit 'www.google.com', 1, 1
SlowWeb.limit 'graph.facebook.com', 1, 1
```

The ideal way to control your network calls is to place them all on one, high-performance process that supports domain-specific throttles, callbacks and parallel requests.

## [Parallel over Serial Requests](#parallel)

Most ruby HTTP clients are serial, running one request at a time. But the process spends most of its time waiting on a response, meaning it's a perfect candidate for parallelization. At least two gems provide ruby with the ability to make network calls in parallel: [em-http-request](https://github.com/igrigorik/em-http-request) and [typhoeus](https://github.com/typhoeus/typhoeus).

```ruby
hydra = Typhoeus::Hydra.new

first_request = Typhoeus::Request.new("http://localhost:3000/posts/1.json")
first_request.on_complete do |response|
  JSON.parse(response.body)
end

second_request = Typhoeus::Request.new("http://localhost:3000/users/1.json")
second_request.on_complete do |response|
  JSON.parse(response.body)
end

hydra.queue first_request
hydra.queue second_request
hydra.run # this is a blocking call that returns once all requests are complete
```

But most likely you won't be issue the HTTP request yourself: you'll be using a gem that generates the request and parses the response. So you won't be able to parallelize your code very easily.

## [Decoupling the HTTP Client](#decouple_http_client)

Every gem made for a web API uses a specific [HTTP client](https://www.ruby-toolbox.com/categories/http_clients). I wish these gems decoupled themselves from this client by exposing two things: the generated request and how to parse the response. This would allow integrating it into a high-performance, error-safe, parallel HTTP client process.

This mythical parallel HTTP client would support domain-specific throttles, request retry thresholds, and could use a delayed_job-like queue. Anyone know of such a thing?

```ruby
class Twitter
  # Decoupling the request generation, request performance, and response parsing

  # for applications that don't care how the request is performed
  def tweet_message message
    # generate the url + data + headers
    request = tweet_message_request message

    # make the network call
    response = perform_request request

    # parse the response data into a nice Ruby object
    parse_tweet_message_response response
  end

  # for applications that don't use this class to perform the request
  def tweet_message_request message
    Request.new({
      :url => "https://api.twitter.com/statuses/update",
      :method => "POST",
      :data => { :status => message },
      :content_type => "json"
    })
  end

  # for applications that don't use this class to perform the request
  def parse_tweet_message_response response
    JSON.parse response.body

  rescue JSON::ParserError => e
    raise Twitter::Error.new("JSON response was invalid")
  end

end
```

## [Conclusion](#conclusion)

Maybe someday I'll sit down and write this mythical HTTP client to help you safely integrate webservices into your application, but for now I hope you have more insight on using Web APIs the hard way. Happy coding!
