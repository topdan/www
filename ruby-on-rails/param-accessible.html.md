```raw
<p class="alert alert-danger">
  <span class="label label-important">Update</span> This article was written prior to DHH releasing the <a href="https://github.com/rails/strong_parameters">strong_parameters</a> gem, which also moves the responsibility from the model to controller, though it doesn't use a <code>*_filter</code> approach. I suggest you use <code>strong_parameters</code>.
</p>
```

## [homakov starts a firestorm](#homakov)

On March 2012, [homakov pushed a commit](https://github.com/rails/rails/commit/b83965785db1eec019edf1fc272b1aa393e6dc57) that launched a thousand opinions. He gamed the github.com security system to give himself write access to the Rails repository. The security flaw he exposed is a well-documented [Rails security consideration,](http://guides.rubyonrails.org/security.html#mass-assignment) but what caused such an uproar was the victim: github.com, one of the flagship Ruby on Rails development teams. If they can accidently expose such a security hole then anyone can. Could Rails provide more help?

## [attr_accessible isn't the problem](#attr_accessible)

Proposed solutions normally center around how Rails could strengthen `attr_accessible`. Here's one of [the more thorough descriptions](https://gist.github.com/1978709) of the problem and how to prevent it. At the end of the article, he links to [a gist by Yehuda Katz](https://gist.github.com/1974187) that brings up the central point: user supplied parameters are a concern of the controller not the model.

<p class="alert alert-notice">
  <strong>Quick Sidebar:</strong>

  I use attr_accessible when the assignment is handled within the model, such as an id, created_at, updated_at, and counter_caches. Controllers, seed files and unit tests never need to set these attributes, but they could by explicitly using the attribute writer.
</p>

## [param_protected: Moving Protection to the Controller](#param_protected)

The [param_protected](https://github.com/cjbottaro/param_protected) gem adds `param_protected` and `param_accessible` to `ActionController::Base` which override `params`. It supports parameter nesting, regexes and if, unless, only, and except options. It takes a large step in the right direction: now the protection is in the proper class!

__But I think param_protected falls short:__

* The user is not told if a parameter they supplied was invalid. Web API's should not silently ignore user input.
* Remove param_protected because it only encourages security holes by allowing controllers to accept new attributes by default. If the developer means to expose a new attribute in a specific controller, they should edit that controller.
* Lastly, I don't like internal implementation of replacing ActionController#params. I'd rather leave such a central rails method unchanged and use a more flexible and accepted approach: before_filters.

## [param_accessible: Securing by default "The Rails Way"](#param_accessible)

I decided to fix my problems with param_protected, but since I don't want the param_protected method and I wanted to change the internal implementation, I made an entirely new gem: [param_accessible](https://github.com/topdan/param_accessible).

The gem integrates into your Rails application with a before_filter and supports nested attributes, regexes and the if, unless, only, and except options. It also stops any request with invalid parameters by throwing an exception, which can be handled the same way as ActiveRecord::RecordNotFound, giving the developer flexibility and the client a detailed explanation of what they did wrong and how to fix it.

For more information see the example code below or check out the gem [here](https://github.com/topdan/param_accessible). It should get your application secure quickly, easily, and in a friendly manner.

## [param_accessible: Example](#examples)

```ruby
#
# app/controllers/application_controller.rb
#
class ApplicationController < ActionController::Base

  # make create and update actions across your application secure by default
  before_filter :ensure_params_are_accessible, :only => [:create, :update]

  # expose your common application parameters
  param_accessible :page, :sort

  # this error is thrown when the user submits an inaccessible param
  rescue_from ParamAccessible::Error, :with => :handle_param_not_accessible

  protected

  def handle_param_not_accessible e
    flash[:error] = "You gave me some invalid parameters: #{e.inaccessible_params.join(', ')}"
    redirect_to :back
  end

end
```

```ruby
#
# app/controllers/users_controller.rb
#
class UsersController < ApplicationController

  # these attributes are available for everyone
  param_accessible :user => [:name, :email, :password, :password_confirmation]

  # attributes are only available if the controller instance method is_admin? is true
  param_accessible :user => [:is_admin, :is_locked_out], :if => :is_admin?

  def update
    @user = User.find(params[:id])

    # this is now safe!
    if @user.update_attributes(params[:user])
      ...
    else
      ...
    end
  end
end
```

```ruby
#
# app/controllers/demo_controller.rb
#
class DemoController < ApplicationController

  # rescue_from ParamAccessible::Error and respond with a 406 Not Acceptable status
  # and HTML, JSON, XML, or JS compatible explanation of which parameters were invalid
  include ParamAccessible::NotAcceptableHelper

  param_accessible :foo, :if => :is_admin
  param_accessible :bar, :unless => :logged_in?
  param_accessible :baz, :only => :show
  param_accessible :nut, :except => :index

end
```

```ruby
#
# app/controllers/insecure_controller.rb
#
class InsecureController < ApplicationController

  # skip the filter in ApplicationController to avoid the accessible parameter checks
  skip_before_filter :ensure_params_are_accessible

end
```
