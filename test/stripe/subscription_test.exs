defmodule Stripe.SubscriptionTest do
  use ExUnit.Case

  #these tests are dependent on the execution order
  # ExUnit.configure w/ seed: 0 was set
  setup_all do
    Helper.create_test_plans
    customer = Helper.create_test_customer "subscription_test@localhost"
    {:ok, sub1} = Stripe.Subscriptions.create customer.id, "test-std"
    {:ok, sub2} = Stripe.Subscriptions.create customer.id, "test-dlx"
    {:ok, sub3} = Stripe.Subscriptions.create customer.id, "test-dlx"

    on_exit fn ->
      Helper.delete_test_plans
      Stripe.Subscriptions.cancel customer.id, sub1.id
      Stripe.Subscriptions.cancel customer.id, sub2.id
      Stripe.Customers.delete customer.id
    end

     {:ok, [ customer: customer, sub1: sub1, sub2: sub2, sub3: sub3 ] }
  end

  @tag disabled: false
  test "Count works", %{customer: customer, sub1: _, sub2: _}  do
    case Stripe.Subscriptions.count customer.id do
      {:ok, cnt} -> assert cnt == 3
      {:error, err} -> flunk err
    end
  end

  @tag disabled: false
  test "Retrieving single works", %{customer: customer, sub1: sub1, sub2: _} do
    case Stripe.Subscriptions.get customer.id, sub1.id do
      {:ok, found} -> assert found.id
      {:error, err} -> flunk err
    end
  end

    @tag disabled: false
    test "Retrieve all works", %{customer: customer} do
    case Stripe.Subscriptions.all customer.id do
        {:ok, subs} ->
            assert Enum.count(subs) == 3
        {:error, err} -> flunk err
    end
  end

  @tag disabled: false
  test "Creating works", %{customer: _, sub1: sub1, sub2: _} do
    assert sub1.id
  end

  @tag disabled: false
  test "Updating works", %{customer: customer, sub1: sub1, sub2: _} do
    case Stripe.Subscriptions.change customer.id, sub1.id,  "test-dlx" do
      {:ok, changed} -> assert changed.plan["id"] == "test-dlx"
      {:error, err} -> flunk err
    end
  end

  @tag disabled: false
  test "Cancel works", %{customer: customer, sub1: sub1, sub2: _} do
    case Stripe.Subscriptions.cancel customer.id, sub1.id do
      {:ok, canceled_sub} -> assert canceled_sub.id
      {:error, err} -> flunk err
    end
  end

  @tag disabled: false
  test "Cancel at period end works", %{customer: customer, sub3: sub3} do
    case Stripe.Subscriptions.cancel(customer.id, sub3.id, [at_period_end: true]) do
      {:ok, canceled_sub} ->
        assert canceled_sub[:status] == "active"
        assert canceled_sub[:cancel_at_period_end] == true
      {:error, err} -> flunk err
    end
  end

  @tag disable: false
  test "Change creditcards works", %{customer: c, sub2: sub2} do
    source = [
      object: "card",
      number: "4012888888881881",
      exp_year: "20",
      exp_month: "12",
    ]
    case Stripe.Subscriptions.change_payment_source(c.id, sub2.id, source) do
      {:ok, res} ->
        assert res[:status] == "active"
      {:error, err} -> flunk err
    end
  end
  @tag disabled: false
  test "Cancel all works", %{customer: customer,  sub1: _, sub2: _} do
    Stripe.Subscriptions.cancel_all customer.id
    {:ok, cnt} = Stripe.Subscriptions.count(customer.id)
    assert cnt == 0
  end
end
