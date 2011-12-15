# Include this module in an ActionController to define predicates within an action that 
# can be used later in the related action view. For example:
#     class StoreController
#       include Condi
#       ...
#     end
module Condi

  # define a predicate (instance method) on the controller which is callable from the related view. 
  # @example define a predicate that determines whether or not to show a "free shipping" option.
  #       predicate(:show_free_shipping?) { user.new_customer? && cart.amount > 100 }
  # @param [Symbol] method_name name of the predicate method. (e.g. :show_action_button?)
  # @param [Proc] block {} or do...end block that evaluates to true or false.
  # @note You are not required to end your method name in a question mark, however it is conventional to do so.
  # @see the full example in the README 
  def predicate(method_name, &block)
    self.class.instance_eval do
      define_method(method_name, &block)
      helper_method(method_name)
    end
  end
end
