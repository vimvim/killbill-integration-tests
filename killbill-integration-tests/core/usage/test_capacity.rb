$LOAD_PATH.unshift File.expand_path('../../..', __FILE__)

require 'test_base'

module KillBillIntegrationTests

  class TestCapacity < Base

    def setup

      @user = 'TestCapacity'

      # Don't put a date too far back in the past - AvaTax won't tax it otherwise
      setup_base(@user, DEFAULT_MULTI_TENANT_INFO, '2015-01-01')

      upload_catalog("usage/Capacity.xml", false, @user, @options)

      # Create account
      @account = create_account(@user, @options)
      add_payment_method(@account.account_id, '__EXTERNAL_PAYMENT__', true, nil, @user, @options)
      @account = get_account(@account.account_id, false, false, @options)

    end

    def teardown
      teardown_base
    end



    def test_basic

      bp = create_entitlement('basic-monthly')

      usage_input = [{:unit_type => 'members',
                      :usage_records => [{:record_date => '2015-01-01', :amount => 6},
                                         {:record_date => '2015-01-02', :amount => 3},
                                         {:record_date => '2015-01-03', :amount => 10},
                                         {:record_date => '2015-01-07', :amount => 8},
                                         {:record_date => '2015-01-09', :amount => 7},
                                         {:record_date => '2015-01-11', :amount => 5},
                                         {:record_date => '2015-01-13', :amount => 4},
                                         {:record_date => '2015-01-15', :amount => 3},
                                         {:record_date => '2015-01-17', :amount => 8}]
                     }]

      record_usage(bp.subscription_id, usage_input, @user, @options)

      kb_clock_add_months(1, nil, @options)
      wait_for_expected_clause(1, @account, @options, &@proc_account_invoices_nb)

      all_invoices = @account.invoices(true, @options)
      sort_invoices!(all_invoices)
      assert_equal(1, all_invoices.size)
      first_invoice = all_invoices[0]

      check_invoice_no_balance(first_invoice, 1.00, 'USD', '2015-02-01')
      check_usage_invoice_item(first_invoice.items[0], first_invoice.invoice_id, 1.00, 'USD', 'USAGE', 'basic-monthly', 'basic-monthly-evergreen', 'basic-monthly-usage1', '2015-01-01', '2015-02-01')

      usage_input = [{:unit_type => 'members',
                      :usage_records => [{:record_date => '2015-02-01', :amount => 6},
                                         {:record_date => '2015-02-02', :amount => 20},
                                         {:record_date => '2015-02-03', :amount => 20},
                                         {:record_date => '2015-02-04', :amount => 50},
                                         {:record_date => '2015-02-07', :amount => 20},
                                         {:record_date => '2015-02-11', :amount => 20},
                                         {:record_date => '2015-02-17', :amount => 50},
                                         {:record_date => '2015-02-24', :amount => 20},
                                         {:record_date => '2015-02-28', :amount => 8}]
                     }]

      record_usage(bp.subscription_id, usage_input, @user, @options)

      kb_clock_add_months(1, nil, @options)
      wait_for_expected_clause(2, @account, @options, &@proc_account_invoices_nb)

      all_invoices = @account.invoices(true, @options)
      sort_invoices!(all_invoices)
      assert_equal(2, all_invoices.size)
      second_invoice = all_invoices[1]

      check_invoice_no_balance(second_invoice, 5.00, 'USD', '2015-03-01')
      check_usage_invoice_item(second_invoice.items[0], second_invoice.invoice_id, 5.00, 'USD', 'USAGE', 'basic-monthly', 'basic-monthly-evergreen', 'basic-monthly-usage1', '2015-02-01', '2015-03-01')


      usage_input = [{:unit_type => 'members',
                      :usage_records => [{:record_date => '2015-03-01', :amount => 6},
                                         {:record_date => '2015-03-02', :amount => 20},
                                         {:record_date => '2015-03-03', :amount => 20},
                                         {:record_date => '2015-03-04', :amount => 50},
                                         {:record_date => '2015-03-07', :amount => 20},
                                         {:record_date => '2015-03-11', :amount => 20},
                                         {:record_date => '2015-03-17', :amount => 50},
                                         {:record_date => '2015-03-24', :amount => 20},
                                         {:record_date => '2015-03-31', :amount => 51}]
                     }]

      record_usage(bp.subscription_id, usage_input, @user, @options)

      kb_clock_add_months(1, nil, @options)
      wait_for_expected_clause(3, @account, @options, &@proc_account_invoices_nb)

      all_invoices = @account.invoices(true, @options)
      sort_invoices!(all_invoices)
      assert_equal(3, all_invoices.size)
      third_invoice = all_invoices[2]

      check_invoice_no_balance(third_invoice, 10.00, 'USD', '2015-04-01')
      check_usage_invoice_item(third_invoice.items[0], third_invoice.invoice_id, 10.00, 'USD', 'USAGE', 'basic-monthly', 'basic-monthly-evergreen', 'basic-monthly-usage1', '2015-03-01', '2015-04-01')
    end

    def test_multiple_units

      bp = create_entitlement('basic-monthly')

      # Both unit are part of tier 1
      usage_input = [{:unit_type => 'members',
                      :usage_records => [{:record_date => '2015-01-01', :amount => 6},
                                         {:record_date => '2015-01-07', :amount => 3},
                                         {:record_date => '2015-01-15', :amount => 10},
                                         {:record_date => '2015-01-23', :amount => 8}]
                     },
                     {:unit_type => 'bandwith-meg-sec',
                      :usage_records => [{:record_date => '2015-01-02', :amount => 100},
                                         {:record_date => '2015-01-07', :amount => 3},
                                         {:record_date => '2015-01-15', :amount => 10},
                                         {:record_date => '2015-01-25', :amount => 50}]
                     }]

      record_usage(bp.subscription_id, usage_input, @user, @options)

      kb_clock_add_months(1, nil, @options)
      wait_for_expected_clause(1, @account, @options, &@proc_account_invoices_nb)

      all_invoices = @account.invoices(true, @options)
      sort_invoices!(all_invoices)
      assert_equal(1, all_invoices.size)
      first_invoice = all_invoices[0]

      check_invoice_no_balance(first_invoice, 1.00, 'USD', '2015-02-01')
      check_usage_invoice_item(first_invoice.items[0], first_invoice.invoice_id, 1.00, 'USD', 'USAGE', 'basic-monthly', 'basic-monthly-evergreen', 'basic-monthly-usage1', '2015-01-01', '2015-02-01')

      # Unit members is still part of tier 1 but bandwith-meg-sec is not
      usage_input = [{:unit_type => 'members',
                      :usage_records => [{:record_date => '2015-02-01', :amount => 6},
                                         {:record_date => '2015-02-12', :amount => 10},
                                         {:record_date => '2015-02-15', :amount => 10},
                                         {:record_date => '2015-02-17', :amount => 9},
                                         {:record_date => '2015-02-22', :amount => 0},
                                         {:record_date => '2015-02-27', :amount => 8}]
                     },
                     {:unit_type => 'bandwith-meg-sec',
                      :usage_records => [{:record_date => '2015-02-02', :amount => 101},
                                         {:record_date => '2015-02-07', :amount => 3},
                                         {:record_date => '2015-02-15', :amount => 10},
                                         {:record_date => '2015-02-25', :amount => 50}]
                     }]

      record_usage(bp.subscription_id, usage_input, @user, @options)

      kb_clock_add_months(1, nil, @options)
      wait_for_expected_clause(2, @account, @options, &@proc_account_invoices_nb)

      all_invoices = @account.invoices(true, @options)
      sort_invoices!(all_invoices)
      assert_equal(2, all_invoices.size)
      second_invoice = all_invoices[1]

      check_invoice_no_balance(second_invoice, 5.00, 'USD', '2015-03-01')
      check_usage_invoice_item(second_invoice.items[0], second_invoice.invoice_id, 5.00, 'USD', 'USAGE', 'basic-monthly', 'basic-monthly-evergreen', 'basic-monthly-usage1', '2015-02-01', '2015-03-01')

    end


    private

    def create_entitlement(plan_name)
      result = KillBillClient::Model::Subscription.new
      result.account_id = @account.account_id
      result.plan_name = plan_name
      result.create(@user, nil, nil, nil, nil, @options)
    end


    def find_usage_ii(subscription_id, items)
      filtered = items.select do |ii|
        ii.subscription_id == subscription_id && ii.item_type == 'USAGE'
      end
      assert_equal(1, filtered.size)
      return filtered[0]
    end


  end
end
