
Condi
=====

Condi is a gem that you use with Rails to make it easier to cleanly implement conditional elements in a view.

Condi allows you to define boolean-valued *predicates* in the controller that are callable in the view without relying on unneeded instance variables or business logic in the views.  Because the predicates are defined dynamically during a controller action, they are easy to find and easy to use without hopping around multiple files.

Condi also allows definition of *synonyms* that can return any value (not just booleans).


API Doc: {Condi}

Copyright (C) 2012 by Larry Kyrala. MIT Licensed.

Installation
------------

    gem install condi


A Simple Example
----------------

For example, say you have a User who has various roles and a shopping Cart that contains items. Your StoreController loads the current User and Cart objects, and your store view displays the User and Cart information.  But let's say that orders over a certain amount for new customers should show a "free ground shipping" option.  With Condi you can define a `predicate` that does the following:

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


Predicates with Arguments
-------------------------

Say you would like to monitor your cart status and highlight items that are shipped but haven't arrived yet.  You would like to hand the collection of items off to a partial, but how can you use
a predicate in this situation? You need a predicate with an argument!

`app/controllers/store_controller.rb:`

    class StoreController
      include Condi
      
      def items
        cart = Cart.find(cart_id)
        @items = cart.items
        predicate(:shipping?) { |item| item.status == :shipped && DeliveryService.status(item.tracking_number) !~ /arrived/ }
      end
    end

`app/views/store/items.html.erb:`

    <table>
      <%= render :partial => "item", :collection => @items %>
    </table>

`app/views/store/_item.html.erb:`
    
    <% if shipping?(item) %>
      <tr class="shipping">
    <% else %>
      <tr>
    <% end %>
      <td><%= item.to_s %></td>
    </tr>
 

Synonyms: defining blocks that return non-boolean values
--------------------------------------------------------

Although the previous example works, wouldn't it be nicer if we could simply define a `synonym` that
returns the css class we need for a given item?

`app/controllers/store_controller.rb:`

    class StoreController
      include Condi
      
      def items
        cart = Cart.find(cart_id)
        @items = cart.items
        synonym(:css_for_item_status) do |item| 
          if item.status == :shipped 
            if DeliveryService.status(item.tracking_number) !~ /arrived/
              "shipping"
            else
              "shipped"
            end
          else
            "processing"
          end
        end
      end
    end

`app/views/store/_item.html.erb:`
    
    <tr class="<%= css_for_item_status %>">
      <td><%= item.to_s %></td>
    </tr>


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

We haven't gained much except shuffling arguments around and we're coupling Carts with Users unnecessarily.


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

* Because predicates are closures, you only have to worry about setting context once in the controller action instead of coordinating context across multiple files. This keeps your views functional and makes them easier to refactor without breaking existing business logic.

* Placing predicates in the Controller allows them to orchestrate multiple Models without breaking encapsulation between Models.  The Controller is arguably a better place to define such predicates from an MVC perspective.

* Condi makes it simple to define predicates and synonyms in the Controller and call them from the view without cluttering the helper namespace and creating a maze of unique names for every action.  Condi is more flexible.

* Another advantage of the predicate being defined dynamically on the Controller is that the predicate can never be inadvertently called as an action itself.  Condi offers better encapsulation of state.

* Condi works with Rails 2 and Rails 3 apps equally well.


Disadvantages
-------------

* Controllers may become "thicker" than you might like.

* It may be awkward to share predicates across multiple actions.  But if you think about it, it is awkward to share context as well.  Filters are a common solution for both problems.  You can define your predicates in a before_filter method to ensure that both the context and the predicates will be sharable. 


Background
----------

Condi is something I wanted to explore as a response to the general problem of implementing *business logic* and rules in Rails apps. 

* Rules-engines exist (i.e. `rools`), but are heavier-weight than Condi and can be complex to use.

* Rails `cells` is a promising component framework, but is also on the heavy side and may not fit well with legacy apps.

* Render-partial locals are a decent lighter-weight alternative to `cells`, but can sometimes be tricky to keep consistent across multiple controller action contexts.

* Doing the "right thing" isn't always an option in business logic.  If a customer wants to pay you a ton of money but your business model doesn't support it, are you going to refuse the money or change your business model? 

* If business logic turns into a mess, at least we can strive to contain the rules in one place/context so that we can identify which problems are due to inconsistency in the business rules and which are due to coding errors.

