require 'spec_helper'

RSpec.describe Spree::Admin::StockItemsController do
  let(:admin) { create(:admin_user, password: "password") }
  let(:product) { create(:product) }
  let(:variant) { create(:variant, product: product) }
  let(:stock_item) {
    item = variant.stock_items.last
    item.adjust_count_on_hand(10)
    item
  }

  before do
    sign_in admin
    visit "/admin/products/#{stock_item.product.slug}/stock"
  end

  it "increase stock" do
    expect(find("tr#stock-item-#{stock_item.id} > td:nth-child(2)")).to have_content(10)
    click_button Spree.t(:add_stock)
    expect(find("tr#stock-item-#{stock_item.id} > td:nth-child(2)")).to have_content(11)

    # reload
    visit current_path

    expect(find("tr#stock-item-#{stock_item.id} > td:nth-child(2)")).to have_content(11)
  end

  it "change `backorderable`" do
    checkbox = find("input[name='stock_item[backorderable]']")
    expect(checkbox).to be_checked
    checkbox.uncheck

    # reload
    visit current_path

    expect(checkbox).not_to be_checked
  end

  it "destroy stocks" do
    expect(all("tr#stock-item-#{stock_item.id}").size).to eq(1)
    find('a.btn.btn-danger').click
    accept_alert

    # reload
    visit current_path

    expect(all("tbody > tr").size).to eq(0)
  end
end
