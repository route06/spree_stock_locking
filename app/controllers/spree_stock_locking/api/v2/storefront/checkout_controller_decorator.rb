# @see https://github.com/spree/spree/blob/759a342d8c223f38f6544b880eb475db3c6f879c/api/app/controllers/spree/api/v2/storefront/checkout_controller.rb
module SpreeStockLocking
  module Api
    module V2
      module Storefront
        module CheckoutControllerDecorator
          def self.prepended(base)
            base.around_action(:lock_with_variants_ids_for_complete, only: [:next, :advance, :complete])
          end

          private

          def lock_with_variants_ids_for_complete
            if spree_current_order.confirm?
              variant_ids = spree_current_order.line_items.pluck(:variant_id)

              lock_with_variants_ids(variant_ids) do
                yield
              end
            else
              yield
            end
          rescue Redis::Lock::LockTimeout
          end

          def lock_with_variants_ids(variant_ids, &block)
            variant_id = variant_ids.shift

            if variant_id
              identifier = "variant_id:#{variant_id}"
              Redis::Lock.new(identifier, expiration: 15, timeout: 10).lock do
                lock_with_variants_ids(variant_ids, &block)
              end
            else
              yield
            end
          end
        end
      end
    end
  end
end

Spree::Api::V2::Storefront::CheckoutController.prepend(SpreeStockLocking::Api::V2::Storefront::CheckoutControllerDecorator) unless Spree::Api::V2::Storefront::CheckoutController.included_modules.include?(SpreeStockLocking::Api::V2::Storefront::CheckoutControllerDecorator)
