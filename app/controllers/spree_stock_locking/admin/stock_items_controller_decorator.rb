# @see https://github.com/spree/spree/blob/759a342d8c223f38f6544b880eb475db3c6f879c/backend/app/controllers/spree/admin/stock_items_controller.rb
module SpreeStockLocking::Admin::StockItemsControllerDecorator
  def self.prepended(base)
    base.around_action(:lock_with_variant_ids_for_request_params, only: [:create])
    base.around_action(:lock_with_variant_ids_for_stock_item, only: [:update, :destroy])
  end

  private

  # @param variant_ids [Array] Get a lock with each variant
  def lock_with_variant_ids(variant_ids, &block)
    variant_id = variant_ids.shift
    if variant_id
      identifier = "variant_id:#{variant_id}"
      # Since the lock mechanism of redis-objects uses blocks,
      # use recursion to handle multiple variant_ids.
      Redis::Lock.new(identifier, expiration: 15, timeout: 10).lock do
        lock_with_variant_ids(variant_ids, &block)
      end
    else
      yield
    end
  end

  def lock_with_variant_ids_for_stock_item
    variant_ids = [stock_item.variant_id]
    lock_with_variant_ids(variant_ids) do
      yield
    end
  rescue Redis::Lock::LockTimeout
  end

  def lock_with_variant_ids_for_request_params
    variant_ids = [::Spree::Variant.find(params[:variant_id]).id]
    lock_with_variant_ids(variant_ids) do
      yield
    end
  rescue Redis::Lock::LockTimeout
  end
end

Spree::Admin::StockItemsController.prepend(SpreeStockLocking::Admin::StockItemsControllerDecorator) unless Spree::Admin::StockItemsController.included_modules.include?(SpreeStockLocking::Admin::StockItemsControllerDecorator)
