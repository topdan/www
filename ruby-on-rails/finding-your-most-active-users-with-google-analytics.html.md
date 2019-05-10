* [Introduction](#the-introduction)
* [Tracking User IDs](#tracking-user-ids)
* [Querying Google Analytics](#querying-google-analytics)
* [Generating an Email](#generating-an-email)
* [Scheduling the Email](#scheduling-the-email)
* [Conclusion](#conclusion)

## [Introduction](#the-introduction)

You're using Google Analytics to track your web app's visitors, but you don't have visitors: you have users. Don't you want to know what they are doing? Who are your most active users? What do they use the most? Who should you contact directly about a feature improvement? Whose usage has dropped off?

## [Tracking User IDs](#tracking-user-ids)

Google Analytics accepts custom, site-specific data. It's really simple, just add one line to the snippet Google Analytics provides. The new Google Analytics snippet uses [custom dimensions](https://developers.google.com/analytics/devguides/collection/analyticsjs/custom-dims-mets), which you need to [set up explicitly](https://support.google.com/analytics/answer/2709829?hl=en). The older snippet uses [custom variables](https://developers.google.com/analytics/devguides/collection/gajs/gaTrackingCustomVariables), which doesn't require any set up.

```javascript
// For New Snippets
ga('set', 'dimension1', <%= current_user.id %>);

// For Older Snippets
_gaq.push(['_setCustomVar', 1, 'User', <%= current_user.id %>, 1]);
```

## [Querying Google Analytics](#querying-google-analytics)

Now that you're associating a specific user with each pageview, you can use the Google Analytics API to group pageviews by user. I use [garb](https://rubygems.org/gems/garb).

```ruby
# For Newer Snippets
class UserActivity
  extend Garb::Model
  extend Garb::Queryable

  metrics :pageviews, :uniquePageviews
  dimensions :dimension1

  def initialize(struct)
    @pageviews = struct.pageviews.to_i

    @user_id = struct.dimension1.to_i
    @user_id = nil if @user_id == 0
  end

  def user
    @user ||= User.where(id: @user_id).first if @user_id
  end

  def email
    user.email if user
  end

end
```

```ruby
# For Older Snippets
class UserActivity
  extend Garb::Model
  extend Garb::Queryable

  metrics :pageviews, :uniquePageviews
  dimensions :customVarName1, :customVarValue1

  def initialize(struct)
    @pageviews = struct.pageviews.to_i

    @user_id = struct.custom_var_value1.to_i if struct.custom_var_name1 == 'User'
    @user_id = nil if @user_id == 0
  end

  def user
    @user ||= User.where(id: @user_id).first if @user_id
  end

  def email
    user.email if user
  end

end
```

```ruby
module Garb::Queryable

  # Instead of returning a Struct, return instances of the given class
  def query(profile, options = {})
    results(profile, options).inject([]) do |arr, result|
      arr << new(result)
    end
  end

end
```

## [Generating an Email](#generating-an-email)

Emails are a passive way of tracking information. You don't need to go anywhere: it comes to you and fits nicely into most people's daily routines. Let's run a Rake task that authenticates with GA and delivers an email via ActionMailer.

```ruby
class AnalyticsMailer < ActionMailer::Base

  def user_activity_report(to_email, profile)
    # Back one week from midnight last night
    start_at = Date.today - 1.week
    end_at = Date.today

    @activities = UserActivity.query(profile, start_date: start_at, end_date: end_at)
    @activities.sort! {|a, b| b.pageviews <=> a.pageviews }
    return if @activities.empty?

    mail_to({
      to: to_email,
      subject: "[#{profile.name}] User Activity"
    })
  end

end
```

```
<!-- views/analytics_mailer/user_activity_report.html.erb -->
<h2>Active Users</h2>

<table>
  <thead>
    <tr>
      <th>Email</th>
      <th>Pageviews</th>
      <th>Unique Pageviews</th>
    </tr>
  </thead>
  <tbody>
    <% @activities.each do |activity| %>
    <tr>
      <td><%= activity.email %></td>
      <td><%= activity.pageviews %></td>
      <td><%= activity.unique_pageviews %></td>
    </tr>
    <% end %>
  </tbody>
</table>
```

```ruby
# lib/tasks/analytics.rake
namespace :analytics do
  namespace :user_activity_report do

    desc 'Delivers the user activity report'
    task deliver: :environment do
      email = 'dan@cunning.cc'
      password = 'use-two-factor-auth-instead'
      site_name = 'dan.cunning.cc' # name of your Google Analytics "Property"

      Garb::Session.login(email, password)
      # Garb::Session.api_key = api_key # required for 2-step authentication

      profiles = Garb::Management::Profile.all
      profile = profiles.detect {|p| p.name == site_name }

      AnalyticsMailer.user_activity_report(email, profile).deliver
    end
  end
end
```

## [Scheduling the Email](#scheduling-the-email)

The [whenever](http://rubygems.org/gems/whenever) gem provides a slick interface for managing your application's [cronjobs](http://en.wikipedia.org/wiki/Cron), with an easy integration into Capistrano.

```ruby
# config/schedule.rb
every :monday, at: "8:00am" do
  rake "analytics:user_activity_report:deliver"
end
```

```ruby
# config/deploy/production.rb
require "whenever/capistrano"
```

## [Conclusion](#conclusion)

Now you'll get an email every Monday morning telling you who your most active users were last week. The email takes just a couple seconds to browse over and can really improve and target your customer service and product development.

Finding your most active users is only the beginning. Google Analytics can answer a lot more questions:

* How much time did a user spend on each page? What was the average?
* What individual pages did a specific someone use? In what order?
* Who are the major users of a specific page?
* Who had 50% more/less pageviews this week than last week?

[Check out all the Dimensions & Metrics](https://developers.google.com/analytics/devguides/reporting/core/dimsmets)
