
Condi
=====

Condi is a gem that you use with Rails to make it easier to cleanly implement conditional elements in a view.

Condi allows you to define predicates in the controller that are callable in the view without relying on unneeded instance variables or business logic in the views.  Because the predicates are defined dynamically during a controller action, they are easy to find and easy to use without hopping around multiple files.

API Doc: {Condi}

Copyright (C) 2011 by Larry Kyrala. MIT Licensed.

Example
-------

For example, say you have a User who has various roles and a shopping Cart that contains items. Your StoreController loads the current User and Cart objects, and your store view displays the User and Cart information.  But let's say that orders over a certain amount for new customers should show a "free ground shipping" option.  With Condi you can do the following:

`app/controllers/store_controller.rb:`

    class StoreController
      include Condi
      
      def checkout
        user = User.find(user_id)
        cart = Cart.find(cart_id)
        predicate(:show_free_shipping?) { user.new_customer? && cart.amount > 100 }
      end
    end

`app/views/store/checkout.html.erb:`

    <% form_for @cart do |f| %>
      <% if show_free_shipping? %>
        <%= f.radio_button("cart", "shipping", "free_ground") %>
      <% end %>
    <% end %> 

The Problem
-----------

Sometimes, pieces of your UI need to be enabled or disabled depending on certain criteria.  Usually these criteria come from Models loaded during actions in your Controllers.  

Here's a typical implementation of the above example without Condi:

    class StoreController
      def checkout
        @user = User.find(user_id)
        @cart = Cart.find(cart_id)
      end
    end

    <% form_for @cart do |f| %>
      <% if @user.new_customer? && @cart.amount > 100 %>
        <%= f.radio_button("cart", "shipping", "free_ground") %>
      <% end %>
    <% end %> 

Not the cleanest approach since business logic is in our views now.  What's another alternative?  Maybe we can stick a predicate for displaying ground shipping on the Cart model instead?

    class Cart
      def show_free_shipping?(new_customer)
        new_customer && amount > 100
      end
    end

    <% form_for @cart do |f| %>
      <% if @cart.show_free_shipping?(@user.new_customer?) %>
        <%= f.radio_button("cart", "shipping", "free_ground") %>
      <% end %>
    <% end %> 

We haven't gained much except shuffling arguments around.


Or, we could put the predicate in a helper and remove the args:

    class StoreHelper
      def show_free_shipping?
        @user.new_customer? && @cart.amount > 100
      end
    end
  
    <% form_for @cart do |f| %>
      <% if show_free_shipping? %>
        <%= f.radio_button("cart", "shipping", "free_ground") %>
      <% end %>
    <% end %> 

This is a little better, but now we have variables set up in the controller and business logic in the helper.  It would be nicer if we could define the predicate in the controller where it is used, in the context of what the action has loaded (either into instance variables or locals).  Also if we have a large data-driven UI, we may have many such conditional UI predicates.  Managing them all can become quite complex.


Solution
--------

The way Condi solves this problem is to allow you to define predicates in the controller that are accessible in the view.

    class StoreController
      include Condi

      def checkout
        user = User.find(user_id)
        cart = Cart.find(cart_id)
        predicate(:show_free_shipping?) { user.new_customer? && cart.amount > 100 }
      end
    end

The `predicate` call creates a closure around the state we've loaded in the controller and makes it available to the view later without cluttering up the helper namespace or forcing the view to contain business logic.

    <% form_for @cart do |f| %>
      <% if show_free_shipping? %>
        <%= f.radio_button("cart", "shipping", "free_ground") %>
      <% end %>
    <% end %> 

How does this work?  Behind the scenes, `predicate` defines an instance method on the controller and then marks it as a `helper_method` which allows Rails to call the predicate from the view.  Since the predicate is dynamically added, you don't have to worry about the controller instance containing any more predicates than you defined in that particular action, so it's easy to manage.

Advantages
----------

* Because predicates are closures, there is less of a chance that helpers and controllers and views get "mixed up" -- i.e. someone copies some code from one view to another but forgets to set the correct instance variables in the controller.

* Also, the Model shouldn't define such predicates, because they control behavior in the view, not to mention that predicates can orchestrate several Models together with business logic.  The Controller is arguably a better place to define such predicates from an MVC perspective.

* Condi makes it simple to define predicates in the Controller and call them from the view without cluttering the helper namespace and creating a maze of unique names for every action.  Condi is more flexible.

* Another important advantage of the predicate being defined as an instance method on the Controller during an action-view execution is that the predicate method will never exist on the Controller for subsequent actions -- hence the predicate can never be inadvertently called as an action itself.




