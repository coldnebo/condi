# Include this module in an ActionController to define predicates or synonyms within an action context that 
# can be used later in the related action view. 
# @example
#     class StoreController
#       include Condi
#       ...
#     end
module Condi

  # define a method on the controller which is callable from the related view and returns a true or false value. 
  # @example define a predicate that determines whether or not to show a "free shipping" option.
  #     predicate(:show_free_shipping?) { user.new_customer? && cart.amount > 100 }
  # @example define a predicate that takes an element of a collection as an argument.
  #     predicate(:shipping?) { |item| @items.count >= 3 && 
  #        item.status == :shipped && 
  #        DeliveryService.status(item.tracking_number) !~ /arrived/ }
  # @example define a synonym that returns a css class based on item status
  #     synonym(:css_for_item_status) do |item| 
  #       if @items.count >= 3 && item.status == :shipped 
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
  # @note A *synonym* is an alias for defining methods that return values other than true or false.
  # @note You are not required to end a predicate with a question mark, however it is conventional in Ruby to do so.
  # @note Predicates can only be called during the request scope they are defined in, otherwise a RuntimeError is raised. This restriction prevents the associated closures from inadvertently leaking previous request data when the controller classes are cached (i.e. in production).
  # @note Predicates are semantically lambdas and may contain returns.
  # @see the full example in the <a href="index.html">README</a>. 
  def predicate(method_name, &block)
    self.class.instance_eval do
      # this is the request id at the moment the predicate is defined
      request_id = eval("request.object_id",block.binding)

      # We need to keep the block impl as a method/lambda so that it supports returns 
      # by using this particular invocation of define_method...
      method_name_impl = "impl_#{method_name}".to_sym
      define_method(method_name_impl, &block)

      # Next, this invocation of define_method creates a Proc, which
      # wraps the impl and allows us to check the request id.
      define_method(method_name) do |*args|
        # this is the request id at the moment the predicate is called
        check_request_id = request.object_id
        # if they don't match, raise an error!
        unless check_request_id == request_id
          raise RuntimeError, "predicate '#{method_name}' cannot be called outside of the request scope it was defined in (#{request_id}). please redefine the predicate in this request scope (#{check_request_id}).", caller(2)
        end
        send(method_name_impl, *args)
      end

      # finally, expose the wrapped predicate to the view.
      helper_method(method_name)
    end
  end

  # a synonym can be used to define methods that return values besides true and false. 
  alias_method :synonym, :predicate
end
