require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  attr_accessor :customer_success, :customers, :away_customer_success
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
    customers.sort_by! { |item| item[:score] }
    customer_success.sort_by! { |item| item[:score] }.reverse
    customers_to_costumer_succces
    top_costumer_success
  end

  private

  def customers_to_costumer_succces
    customer_success.each_with_index do |c_success, index|
      c_success.merge!(clients: 0)
      next if away_customer_success.include?(c_success[:id])

      previous_custumer = customer_success[index - 1]
      customers.each do |customer|
        if index.positive?
          if customer[:score] <= c_success[:score] && customer[:score] >= previous_custumer[:score]
            c_success[:clients] += 1
          end
        elsif customer[:score] <= c_success[:score]
          c_success[:clients] += 1
        end
      end
    end
  end

  def top_costumer_success
    rank_customer_succes = customer_success.sort_by { |c_success| c_success[:clients] }.reverse
    return 0 if rank_customer_succes.first[:clients].zero?

    rank_customer_succes.reject! { |c_success| c_success[:clients].zero? }
    return 0 if there_is_a_tie(rank_customer_succes)

    rank_customer_succes.first[:id]
  end

  def there_is_a_tie(rank_customer_succes)
    rank_customer_succes.group_by { |item| item[:clients] }.values.select { |item| item.size > 1 }.size.positive?
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
