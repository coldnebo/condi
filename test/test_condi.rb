require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'mocha'

require 'action_controller'
require 'condi'

require 'ostruct'

#require 'ruby-debug'


class CondiTest < Test::Unit::TestCase
  
  def setup
    @controller_class = Class.new(::ActionController::Base)
    @controller_class.instance_eval do
      include Condi
    end
    @controller_instance = @controller_class.new
  end

  def test_included_properly
    assert @controller_instance.respond_to?(:predicate)
  end

  def test_simple_predicate
    @controller_instance.instance_eval do 
      predicate(:always_true?) { true }
    end

    assert @controller_instance.respond_to?(:always_true?)
    assert @controller_instance.always_true? == true
  end

  def test_instance_variable_predicate
    @controller_instance.instance_eval do 
      @var = 5
      predicate(:is_var_5?) { @var == 5 }
    end
    
    assert @controller_instance.respond_to?(:is_var_5?)
    assert @controller_instance.is_var_5? == true    
  end

  def test_local_variable_predicate
    @controller_instance.instance_eval do 
      var = "Mary"
      predicate(:is_mary?) { (var =~ /Mary/) == 0 }
    end

    assert @controller_instance.respond_to?(:is_mary?)
    assert @controller_instance.is_mary? == true    
  end

  def test_complex_multiline_predicate
    @controller_instance.instance_eval do 
      # simulating loaded AR objects in a controller method.
      @customer = Object.new
      def @customer.new_customer?
        true 
      end
      @cart = Object.new
      def @cart.amount
        105
      end
      predicate(:show_free_shipping?) do
        @customer.new_customer? && @cart.amount > 100 
      end
    end
    
    assert @controller_instance.respond_to?(:show_free_shipping?)
    assert @controller_instance.show_free_shipping? == true    
  end

  def test_exception_within_predicate
    @controller_instance.instance_eval do
      predicate(:blows_up?) do
        raise "blew up!"
      end
    end

    assert @controller_instance.respond_to?(:blows_up?)
    assert_raise RuntimeError do
      puts "ah ha!" if @controller_instance.blows_up?
    end    
  end

  # predicates can be used with collections!
  def test_collection_predicate
    @controller_instance.instance_eval do
      predicate(:is_usa?) do |location|
        case location
          when :arizona then true
          when :massachusetts then true
          else false
        end
      end
    end

    assert @controller_instance.respond_to?(:is_usa?)

    @locations = [:arizona, :massachusetts, :england]
    expected_values = [true, true, false]
    @locations.each_with_index do |location,i|
      assert @controller_instance.is_usa?(location) == expected_values[i]
    end
  end

  # `synonym` is an alias for `predicate` for when you want to return something besides a boolean.
  def test_synonyms
    @controller_instance.instance_eval do
      synonym(:css_for_item_status) do |item| 
        if item.status == :shipped 
          if item.delivery_status !~ /arrived/
            "shipping"
          else
            "shipped"
          end
        else
          "processing"
        end
      end
    end

    item = OpenStruct.new
    item.status = :shipped
    item.delivery_status = "order left Ohio. checkin MN. checkin AZ."
    assert @controller_instance.css_for_item_status(item) == "shipping"

    item = OpenStruct.new
    item.status = :shipped
    item.delivery_status = "order left Ohio. checkin MN. checkin AZ. arrived HI."
    assert @controller_instance.css_for_item_status(item) == "shipped"

    item = OpenStruct.new
    item.status = :awaiting_payment
    item.delivery_status = ""
    assert @controller_instance.css_for_item_status(item) == "processing"
  end
  

end