## Common Mistake

```raw
<p class="alert alert-danger centered"><strong>Can you spot the bug?</strong></p>
```

```
<%= form_for @post do |f| %>

  <%= @post.errors.full_messages.join(', ') %>

  <p>
    <%= f.label :user_name, 'Author' %>
    <%= f.text_field :user_name %>
  </p>

  <p>
    <%= f.submit %>
  </p>

<% end %>
```

`full_messages` will display "User name can't be blank" while the text field is labeled "Author" which will likely cause confusion.

## Proper Implementation

While the [FormBuilder's label method](http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-label) accepts `content_or_options`, __I consider "content" deprecated__ due to error message display and localization concerns. Here's the proper implementation:

```yaml
# config/locales/en.yml
activerecord:
  attributes:
    post:
      user_name: Author
```

```
<%= form_for @post do |f| %>

  <%= @post.errors.full_messages.join(', ') %>

  <p>
    <%= f.label :user_name %>
    <%= f.text_field :user_name %>
  </p>

  <p>
    <%= f.submit %>
  </p>

<% end %>
```

With that change you're properly set up for new language support and the field names in the error messages will match your labels.
