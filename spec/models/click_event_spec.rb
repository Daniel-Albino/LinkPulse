require "rails_helper"

RSpec.describe ClickEvent, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:link) }
  end

  describe "counter cache" do
    let(:link) { create(:link) }

    it "increments click_events_count when created" do
      expect { create(:click_event, link: link) }
        .to change { link.reload.click_events_count }.from(0).to(1)
    end

    it "decrements click_events_count when destroyed" do
      click = create(:click_event, link: link)

      expect { click.destroy }
        .to change { link.reload.click_events_count }.from(1).to(0)
    end

    it "keeps the count consistent across several clicks" do
      create_list(:click_event, 3, link: link)

      expect(link.reload.click_events_count).to eq(link.click_events.count)
    end
  end
end
