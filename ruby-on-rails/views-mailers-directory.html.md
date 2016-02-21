`app/views` contains both controller and mailer directories and becomes cluttered as your application grows. I keep `app/views` better organized by moving all my `*_mailer` directories underneath `app/views/mailers`, which is accomplished with one line of code:

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default template_path: -> (e) { "mailers/#{e.class.name.underscore}" }
end
```

Now `UsersMailer` templates go into `app/views/mailers/users_mailer`.

```raw
<p class="center"><img src="before-and-after.png" alt="Before and After"/></p>

<p class="alert alert-info center mt-4e">It just feels better this way.</p>
```
