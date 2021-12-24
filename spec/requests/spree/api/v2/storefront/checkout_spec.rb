# Derived from https://github.com/spree/spree/blob/v4.3.0/api/spec/requests/spree/api/v2/storefront/checkout_spec.rb

require 'spec_helper'

describe 'API V2 Storefront Checkout Spec', type: :request do
  let(:store) { Spree::Store.default }
  let(:currency) { store.default_currency }
  let(:user)  { create(:user) }
  let(:order) { create(:order, user: user, store: store, currency: currency) }
  let(:payment) { create(:payment, amount: order.total, order: order) }
  let(:shipment) { create(:shipment, order: order) }

  let(:address) do
    {
      firstname: 'John',
      lastname: 'Doe',
      address1: '7735 Old Georgetown Road',
      city: 'Bethesda',
      phone: '3014445002',
      zipcode: '20814',
      state_id: state.id,
      country_iso: country.iso
    }
  end

  let(:payment_source_attributes) do
    {
      number: '4111111111111111',
      month: 1.month.from_now.month,
      year: 1.month.from_now.year,
      verification_value: '123',
      name: 'Spree Commerce'
    }
  end
  let(:payment_params) do
    {
      order: {
        payments_attributes: [
          {
            payment_method_id: payment_method.id
          }
        ]
      },
      payment_source: {
        payment_method.id.to_s => payment_source_attributes
      }
    }
  end

  include_context 'API v2 tokens'

  describe 'checkout#next' do
    let(:execute) { patch '/api/v2/storefront/checkout/next', headers: headers }

    shared_examples 'perform next' do
      context 'without line items' do
        before do
          order.line_items.destroy_all
          execute
        end

        it_behaves_like 'returns 422 HTTP status'

        it 'cannot transition to address without a line item' do
          expect(json_response['error']).to include(Spree.t(:there_are_no_items_for_this_order))
        end
      end

      context 'with line_items and email' do
        before { execute }

        it_behaves_like 'returns 200 HTTP status'
        it_behaves_like 'returns valid cart JSON'

        it 'can transition an order to the next state' do
          expect(order.reload.state).to eq('address')
          expect(json_response['data']).to have_attribute(:state).with_value('address')
        end
      end

      context 'without payment info' do
        before do
          order.update_column(:state, 'payment')
          execute
        end

        it_behaves_like 'returns 422 HTTP status'

        it 'returns an error' do
          expect(json_response['error']).to include(Spree.t(:no_payment_found))
        end

        it 'doesnt advance pass payment state' do
          expect(order.reload.state).to eq('payment')
        end
      end

      it_behaves_like 'no current order'
    end

    context 'as a guest user' do
      include_context 'creates guest order with guest token'

      it_behaves_like 'perform next'
    end

    context 'as a signed in user' do
      include_context 'creates order with line item'

      it_behaves_like 'perform next'
    end
  end

  describe 'checkout#advance' do
    let(:execute) { patch '/api/v2/storefront/checkout/advance', headers: headers }

    shared_examples 'perform advance' do
      before do
        order.update_column(:state, 'payment')
      end

      context 'with payment data' do
        before do
          payment
          execute
        end

        it_behaves_like 'returns 200 HTTP status'
        it_behaves_like 'returns valid cart JSON'

        it 'advances an order till complete or confirm step' do
          expect(order.reload.state).to eq('confirm')
          expect(json_response['data']).to have_attribute(:state).with_value('confirm')
        end
      end

      context 'without payment data' do
        before { execute }

        it_behaves_like 'returns 200 HTTP status'
        it_behaves_like 'returns valid cart JSON'

        it 'doesnt advance pass payment state' do
          expect(order.reload.state).to eq('payment')
          expect(json_response['data']).to have_attribute(:state).with_value('payment')
        end
      end

      it_behaves_like 'no current order'
    end

    context 'as a guest user' do
      include_context 'creates guest order with guest token'

      it_behaves_like 'perform advance'
    end

    context 'as a signed in user' do
      include_context 'creates order with line item'

      it_behaves_like 'perform advance'
    end
  end

  describe 'checkout#complete' do
    let(:execute) { patch '/api/v2/storefront/checkout/complete', headers: headers }

    shared_examples 'perform complete' do
      before do
        order.update_column(:state, 'confirm')
      end

      context 'with payment data' do
        before do
          payment
          shipment
          execute
        end

        it_behaves_like 'returns 200 HTTP status'
        it_behaves_like 'returns valid cart JSON'

        it 'completes an order' do
          expect(order.reload.state).to eq('complete')
          expect(order.completed_at).not_to be_nil
          expect(json_response['data']).to have_attribute(:state).with_value('complete')
        end
      end

      context 'without payment data' do
        before { execute }

        it_behaves_like 'returns 422 HTTP status'

        it 'returns an error' do
          expect(json_response['error']).to include(Spree.t(:no_payment_found))
        end

        it 'doesnt completes an order' do
          expect(order.reload.state).not_to eq('complete')
          expect(order.completed_at).to be_nil
        end
      end

      it_behaves_like 'no current order'
    end

    context 'as a guest user' do
      include_context 'creates guest order with guest token'

      it_behaves_like 'perform complete'
    end

    context 'as a signed in user' do
      include_context 'creates order with line item'

      it_behaves_like 'perform complete'
    end
  end
end
