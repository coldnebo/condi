require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'mocha'

require 'action_controller'
require 'condi'

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


end