# Include this module in an ActionController to define predicates or synonyms within an action context that 
# can be used later in the related action view. 
# @example
#     class StoreController
#       include Condi
#       ...
#     end
module Condi

  # define a method on the controller which is callable from the related view. 
  # @example define a predicate that determines whether or not to show a "free shipping" option.
  #     predicate(:show_free_shipping?) { user.new_customer? && cart.amount > 100 }
  # @example define a predicate that takes an element of a collection as an argument.
  #     predicate(:shipping?) { |item| item.status == :shipped && DeliveryService.status(item.tracking_number) !~ /arrived/ }
  # @example define a synonym that returns a css class based on item status
  #     synonym(:css_for_item_status) do |item| 
  #       if item.status == :shipped 
  #         if DeliveryService.status(item.tracking_number) !~ /arrived/
  #           "shipping"
  #         else
  #           "shipped"
  #         end
  #       else
  #         "processing"
  #       end
  #     end
  # @param [Symbol] method_name name of the predicate or synonym method. (e.g. :show_action_button?)
  # @param [Proc] block {} or do...end block.
  # @note You are not required to end a predicate with a question mark, however it is conventional in Ruby to do so.
  # @see the full example in the <a href="index.html">README</a>. 
  def predicate(method_name, &block)
    self.class.instance_eval do
      define_method(method_name, &block)
      helper_method(method_name)
    end
  end

  # a synonym is similar to a predicate but returns values besides true and false.
  alias_method :synonym, :predicate
end
