A __minimum viable test suite__ fails when important holes in its coverage are identified, and with Rails applications the most important holes are untested routes. Here's a quick script to ensure every route is hit during a full run of `rspec`:

```ruby
# spec/support/minimum_viable_test_suite.rb

# singleton class that tracks hit routes
class ControllerCoverageSupport
  attr_reader :hits

  def initialize
    @hits = Set.new
  end

  def hit!(controller, action)
    @hits << "#{controller}##{action}"
  end

  def endpoints
    @endpoints ||= begin
      set = Set.new
      Rails.application.routes.routes.each do |route|
        controller = route.defaults[:controller]
        action = route.defaults[:action]
        next unless controller && action

        set << "#{controller}##{action}"
      end
      set
    end
  end

  def misses
    endpoints - hits
  end

  class << self
    def instance
      @instance ||= self.new
    end
  end
end

# listen to action controller
ActiveSupport::Notifications.subscribe /process_action.action_controller/ do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  controller = event.payload[:controller]
  controller = controller[0 .. -'Controller'.length - 1].underscore
  action = event.payload[:action]

  ControllerCoverageSupport.instance.hit!(controller, action)
end

# fail the test suite if you ran the entire test suite and missed any routes
at_exit do
  coverage = ControllerCoverageSupport.instance

  # ARGV is empty when running `rspec` as opposed to `rspec ./spec/my_spec.rb`
  if ARGV.empty? && coverage.misses.any?
    puts "Only #{coverage.hits.count} of #{coverage.endpoints.count} endpoints were hit"
    abort "  Missed controller action(s): #{ControllerCoverageSupport.instance.misses.to_a.sort.join(', ')}"
  end
end
```

Not the prettiest code in the world, but it gets the job done: __rspec will now fail when any routes are missed__. Of course, it doesn't ensure the routes are exhaustively tested. Tools like [simplecov](https://github.com/colszowka/simplecov) can help that but automating failure there is tricky:

* [Placing a minimum coverage threshold](https://github.com/colszowka/simplecov/issues/373) just sets a ticking timebomb waiting for one unlucky commit
* [Ensuring commits don't decrease the code coverage](https://github.com/colszowka/simplecov/issues/11) triggers when removing well-covered code

Convincing your team to enforce _a minimum viable test suite_ should be easy: it's hard to argue testing an endpoint is unnecessary. Here are a few more rules I could see enforcing:

* Every `ActiveJob::Base` subclass is performed
* Every `ActiveRecord::Base` subclass is created, updated, and destroyed
* Every `app/views` template is rendered

```raw
<div class="alert alert-success">
  <p>Let me know at <a href="mailto:dan@topdan.com">dan@topdan.com</a> what you think of minimum viable test suites:</p>

  <ul class="mt-1e">
    <li>Are there existing solutions?</li>
    <li>What other rules would you enforce?</li>
    <li>Are you interested in a cleaner implementation published as a gem?</li>
  </ul>
</div>
```
