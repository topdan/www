* [Why?](#why)
* [The Implementation](#the-implementation)
  * [Model Design](#model-design)
  * [Griddler Setup](#griddler)
  * [Background Jobs](#background-jobs)
  * [Mandrill Setup](#mandrill-setup)
* [Rounding the Edges](#rounding-the-edges)
  * [Unsubscribe](#unsubscribe)
  * [Email Digests](#email-digests)
  * [Web Archives](#web-archives)
* [Future Considerations](#future-considerations)
* [Wrap-Up](#wrap-up)

## [Why?](#why)

Even though mailing lists have been around since ARPANET, they remain a viable way for groups to communicate. Modern web applications contain dynamic user groups and should leverage email to facilitate communication within them.

Many web applications already send email notifications, and __the best applications support replying to that email:__

* Github allows developers to discuss issues and pull-requests
* Craigslist allows buyers and sellers to communicate anonymously
* [Tender](https://tenderapp.com/) (not Tinder) allows support to address customer issues
* Basecamp allows all sorts of project discussion

```raw
<p class="alert alert-info">If your web application sends emails, <strong>you should handle the reply button</strong> and often the best user-experience encourages its use.</p>
```

## [The Implementation](#the-implementation)

Only the largest companies run email servers, while others send and receive emails using third-party services. We'll use [ActionMailer](http://guides.rubyonrails.org/action_mailer_basics.html#sending-emails) to send emails and [the griddler gem](https://github.com/thoughtbot/griddler) to receive emails through [MailChimp's Mandrill](https://mandrill.com/) service.

### [Model Design](#model-design)

Your application probably already separates users into groups, whether by admins, accounts, trial users, or long-term customers, but for this tutorial we'll use a more general design.

[Users](#user) have [memberships](#membership) to [groups](#group). Group members generate [discussions](#discussion) by sending [messages](#message). Five models total, here's the database schema:

#### [](#the-schema)

```ruby
# db/migrations/20150221052903_create_group_discussions.rb

create_table :users do |t|
  t.string :name
  t.string :email
  t.timestamps
end

create_table :groups do |t|
  t.string   :name
  t.string   :email
  t.datetime :digest_last_sent_at
  t.timestamps
end

create_table :memberships do |t|
  t.integer :user_id
  t.integer :group_id
  t.boolean :receives_every_message, default: false
  t.boolean :receives_digest,        default: false
  t.string  :token,                  null: false
  t.timestamps
end

create_table :discussions do |t|
  t.integer :group_id
  t.string  :email
  t.string  :subject
  t.timestamps
end

create_table :messages do |t|
  t.integer :discussion_id
  t.integer :from_id
  t.text    :content
  t.timestamps
end
```

#### [User](#user)

A user has a name and an email address that can send messages to groups they have a membership in.

```ruby
class User < ActiveRecord::Base

  has_many :memberships
  has_many :groups,        through: :memberships
  has_many :sent_messages, foreign_key: 'from_id'

  validates :name,  presence: true, format: {with: %r(^[\w\ ]+$)}
  validates :email, presence: true, uniqueness: true

end
```

#### [Group](#group)

Groups have an email address and users that are allowed create discussions by emailing it.

```ruby
class Group < ActiveRecord::Base

  has_many :memberships, dependent: :destroy
  has_many :users,       through: :memberships
  has_many :discussions, dependent: :destroy
  has_many :messages,    through: :discussions

  validates :name,  presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true

end
```

#### [Membership](#membership)

Memberships give users access to groups and also indicate what emails the user would like to receive from the group.

```ruby
class Membership < ActiveRecord::Base

  belongs_to :user
  belongs_to :group

  validates :user_id,  presence: true, uniqueness: {scope: :group_id, message: 'is already a member of this group'}
  validates :group_id, presence: true
  validates :token,    presence: true

  before_validation :generate_token, on: :create

  private

  def generate_token
    loop do
      self.token = SecureRandom.hex(64)
      break if Membership.where(token: token).any?
    end
  end

end
```

#### [Discussion](#discussion)

A discussion is a collection of messages within a group. Users add messages to the discussion by emailing it.

```ruby
class Discussion < ActiveRecord::Base

  belongs_to :group

  has_many :messages, dependent: :destroy

  validates :email,   presence: true
  validates :subject, presence: true

  before_validation :generate_unique_email, on: :create

  private

  # if the group's email is admins@your-domain.com,
  # its discussion emails are admins-:unique-hex:@your-domain.com
  def generate_unique_email
    loop do
      self.email = group.email.sub('@', "-#{SecureRandom.hex(32)}@")
      break if Discussion.where(email: email).any?
    end if group
  end

end
```

#### [Message](#message)

A message is text sent by a user inside a group discussion.

```ruby
class Message < ActiveRecord::Base

  belongs_to :discussion
  belongs_to :from, class_name: 'User'

  validates :from_id, presence: true
  validates :content, presence: true

end
```

### [Griddler Setup](#griddler)

[The griddler gem](https://github.com/thoughtbot/griddler) smooths the process of receiving emails from third-party services such as Mandrill, SendGrid, Mailgun, and Postmark. I prefer Mandrill's simple but powerful interface, and MailChimp being my neighbor in Atlanta doesn't hurt.

First, add griddler and [griddler's mandrill adapter](https://github.com/wingrunr21/griddler-mandrill) to your Gemfile and run `bundle install`

```ruby
# Gemfile

gem 'griddler'
gem 'griddler-mandrill'
```

Next, add the routes Mandrill will use to communicate to your app through griddler.

```ruby
# config/routes.rb

# verifies during initial setup
get '/mandrill', to: proc { [200, {}, ["OK"]] }

# indicates a single received email
post '/mandrill', to: 'griddler/emails#create'
```

Finally, configure griddler to send received emails to the background job queue.

```ruby
# config/initializers/griddler.rb

class Griddler::EmailProcessor
  def initialize(email)
    @email = email
  end

  def process
    ReceiveEmailJob.perform_later({
      'from'    => @email.from,
      'to'      => @email.to,
      'subject' => @email.subject,
      'body'    => @email.raw_body,
    })
  end
end

Griddler.configure do |config|
  config.email_service = :mandrill
  config.processor_class = Griddler::EmailProcessor
end
```

For more information on griddler, please refer to [thoughtbot's blog post](https://robots.thoughtbot.com/handle-incoming-email-with-griddler) and [the github repository](https://github.com/thoughtbot/griddler).

### [Background Jobs](#background-jobs)

Our mailing list logic lives in background jobs and is actually rather simple:

* Ignore emails if the sender doesn't belong to the group
* If addressed to a group, create a new discussion and the initial message
* If addressed to a discussion, create a new message
* If neither a group or discussion is found, ignore it
* Forward created messages to others in the group

```ruby
class ReceiveEmailJob < ActiveJob::Base
  queue_as :default

  def perform(email)
    @from = User.where(email: email['from']['email']).first
    return unless @from # unknown sender

    @subject = email['subject']
    @body = email['body']

    email['to'].each do |to|
      try_group(to['email']) || try_discussion(to['email'])
    end
  end

  private

  def try_group(email)
    group = Group.where(email: email).first
    return unless allow_messages_to?(group)

    discussion = group.discussions.new(subject: @subject)
    message = discussion.messages.new(from: @from, content: @body)

    forward(message) if discussion.save
  end

  def try_discussion(email)
    discussion = Discussion.where(email: email).first
    group = discussion.group if discussion
    return unless allow_messages_to?(group)

    message = discussion.messages.new(from: @from, content: @body)

    forward(message) if message.save
  end

  def allow_messages_to?(group)
    group && group.memberships.where(user_id: @from).any?
  end

  def forward(message)
    ForwardMessageJob.perform_now(message)
  end

end
```

```ruby
class ForwardMessageJob < ActiveJob::Base
  queue_as :default

  def perform(message)
    @message = message

    memberships.each do |membership|
      # spawn a new job for each email in case any fail to send
      GroupsMailer.new_message(membership, message).deliver_later
    end
  end

  private

  def memberships
    @message.group.memberships.
      where(receives_every_message: true).
      where('user_id != ?', @message.from)
  end

end
```

Outgoing emails follow the [Action Mailer Basics](http://guides.rubyonrails.org/action_mailer_basics.html), though notice the "from name" is the sender but the "from email" is the discussion, ensuring replies are  handled properly by our application.

```ruby
# app/mailers/groups_mailer.rb
class GroupsMailer < ApplicationMailer

  def new_message(membership, message)
    @membership = member
    @message = message
    @discussion = @message.discussion

    mail({
      to: @membership.user.email,
      from: %("#{@message.from.name}" <#{@discussion.email}>),
      subject: @discussion.subject
    })
  end

end
```

```erb
<!-- app/views/groups_mailer/new_message.html.erb -->
<%= simple_format @message.content %>
```

### [Mandrill Setup](#mandrill-setup)

Your top-level domain is probably already using an email service like gmail, so it's best to establish a subdomain like `app.your-domain.com` for sending and receiving emails programmatically. Follow Mandrill's documentation to setup your account:

1. [Creating a Mandrill Account](https://mandrill.com/signup/)
1. [Setting up a Sending Domain](http://help.mandrill.com/entries/21650603-How-do-I-get-started-with-Mandrill-#set-up-sending-domains-optional)
1. [Adding an Inbound Domain](http://help.mandrill.com/entries/21699367-Inbound-Email-Processing-Overview)
1. [Adding a New Route to your Inbound Domain](http://help.mandrill.com/entries/21699367-Inbound-Email-Processing-Overview#adding-routes)

The end result should be:

* Sending domain `app.your-domain.com` marked `DKIM valid` and `SPF valid`
* Inbound domain `app.your-domain.com` marked `MX valid` with a verified route `*@app.your-domain.com` with a webhook URL of `https://your-app.com/mandrill`

```raw
<p class="alert alert-info">Your production environment is now setup to run mailing lists from <code>*@app.your-domain.com</code></p>
```

## [Rounding the Edges](#rounding-the-edges)

A few more steps before we have a proper, user-friendly mailing list:

* [Unsubscribe](#unsubscribe)
* [Email Digests](#email-digests)
* [Web Archives](#web-archives)

### [Unsubscribe](#unsubscribe)

If you're sending emails then you should always allow recipients to opt-out, and many countries have [written the practice into law](http://en.wikipedia.org/wiki/CAN-SPAM_Act_of_2003). Most email services provide unsubscribe functionality, but using it results in the user unsubscribing from _all future emails_, not just ones from a certain group.

Allowing a user to opt-out of a group's emails with one click is easy:

```ruby
# config/routes.rb
get 'subscriptions/:id/unsubscribe', to: 'subscriptions#destroy', as: 'unsubscribe'
```

```ruby
# app/controllers/subscriptions_controller.rb
class SubscriptionsController < ApplicationController

  def destroy
    # the membership token uniquely identifies the membership
    # without being easy for others to guess.
    @membership = Membership.where(token: params[:id]).first

    if @membership
      @membership.receives_every_message = false
      @membership.receives_digest = false
      @membership.save(validate: false)
    end
  end

end
```

```erb
<!-- app/views/subscriptions/destroy.html.erb -->
<p>You've unsubscribed from this group's emails.</p>
```

```
<!-- Add this the bottom of app/views/groups_mailer/new_message.html.erb -->
<p><%= link_to 'Unsubscribe', unsubscribe_url(id: @membership.token) %></p>
```

### [Email Digests](#email-digests)

Email digests contain all messages since the previous digest. We'll generate a daily digest using [the whenever gem](https://github.com/javan/whenever) which manages scheduled tasks defined inside `config/schedule.rb`

```ruby
# app/mailers/groups_mailer.rb
class GroupsMailer < ApplicationMailer

  def digest(membership, timeframe)
    @membership = membership
    @group = membership.group
    @messages = @group.messages.where(created_at: timeframe).order(:discussion_id, :created_at)

    mail({
      to: @membership.user.email,
      from: %("#{@group.name}" <#{@group.email}>),
      subject: "Message Digest"
    })
  end

end
```

```erb
<!-- app/views/groups_mailer/digest.html.erb -->
<%= @messages.each do |message| %>
  <p>Subject: <%= message.discussion.subject %></p>
  <p>From: <%= message.from.name %></p>
  <p>Timestamp: <%= message.created_at.to_s(:timestamp) %></p>
  <%= simple_format message.content %>
  <hr>
<% end %>

<p><%= link_to 'Unsubscribe', unsubscribe_url(id: @membership.token) %></p>
```

```ruby
# lib/tasks/groups.rake
namespace :groups do
  namespace :digest do

    task send: :environment do
      Groups.find_each do |group|
        now = Time.now
        last_sent = group.digest_last_sent_at || now - 1.week
        timeframe = (last_sent..now)

        next if group.messages.where(created_at: timeframe).empty?

        group.memberships.where(receives_digest: true).find_each do |membership|
          GroupsMailer.digest(membership, timeframe).deliver_later
        end

        group.digest_last_sent_at = now
        group.save(validate: false)
      end
    end

  end
end
```

```ruby
# config/schedule.rb
every 1.day, at: '4:30 am' do
  rake "groups:digest:send"
end
```

### [Web Archives](#web-archives)

Since we're storing all the messages in the database, let's display the full history of group discussions within our application for new and old members to browse:

```ruby
# config/routes.rb

resources :groups, only: 'index' do
  resources :discussions, only: %w(index show)
end
```

```ruby
# app/controllers/groups_controller.rb
class GroupsController < ApplicationController

  def index
    @groups = Group.order(:name)
  end

end
```

```ruby
# app/controllers/discussions_controller.rb
class DiscussionsController < ApplicationController

  before_action :load_group

  def index
    @discussions = @group.discussions.order(created_at: :desc)
  end

  def show
    @discussion = @group.discussions.find(params[:id])
    @messages = @discussion.messages.order(:created_at)
  end

  private

  def load_group
    @group = Group.find(params[:id])
  end

end
```

```erb
<!-- app/views/groups/index.html.erb -->

<ul>
<% @groups.each do |group| %>
  <li><%= link_to group.name, discussions_path(group) %></li>
<% end %>
</ul>
```

```erb
<!-- app/views/discussions/index.html.erb -->

<h1><%= @group.name %></h1>

<ul>
<% @discussions.each do |discussion| %>
  <li><%= link_to discussion.subject, discussion_path(@group, discussion) %></li>
<% end %>
</ul>
```

```erb
<!-- app/views/discussions/show.html.erb -->

<h1><%= @discussion.subject %></h1>

<% @messages.each do |message| %>
  <p>From: <%= message.from.name %></p>
  <p>Timestamp: <%= message.created_at.to_s(:timestamp) %></p>

  <%= simple_format message.content %>
<% end %>
```

## [Future Considerations](#future-considerations)

Now we've wrapped up the basic mailing list functionality, though there's plenty more to think about:

* How are groups managed?
* How do users enable the daily digest?
* Should we support attachments?
* Can users be deleted?
* Can non-members view an archive?
* Can users create messages inside the archive?
* How can we ensure only Mandrill can post received emails?

All these questions can be approached using standard Ruby on Rails MVC, and none are especially difficult with the existing design.

## [Wrap-Up](#wrap-up)

Here's what we made:

* Groups of users can have discussions via email
* Daily digests are sent to members that don't want to see every message individually
* Unsubscribe links allow members to stop receiving a group's emails
* A web archive exposes a group's complete discussion history

Essentially we have the most important parts of Google Groups, but the real possibilities come to light when you think beyond generic groups and messages. __You can send and receive emails in your existing application:__

* How are your users grouped?
* How can email help these groups communicate?
* What could have an email address?
* What would be convenient for your users to post from their inbox?

Start working the respond button into your application's workflow. `no-reply@your-app.com` is no longer a viable option. __Support the reply button__ if you actually care about what your customers have to say, or at the very least use `please-reply@your-app.com` and forward it to an intern.
