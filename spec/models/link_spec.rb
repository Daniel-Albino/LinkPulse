require "rails_helper"

RSpec.describe Link, type: :model do
  describe "validations" do
    subject { build(:link) }

    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_uniqueness_of(:url) }

    it "accepts http and https URLs" do
      expect(build(:link, url: "http://example.com")).to be_valid
      expect(build(:link, url: "https://example.com/a/b?c=d")).to be_valid
    end

    it "rejects a string that is not a URL" do
      link = build(:link, url: "batatas")

      expect(link).not_to be_valid
      expect(link.errors[:url]).to be_present
    end

    it "rejects a URL with no host" do
      expect(build(:link, url: "https://")).not_to be_valid
    end

    # The reason the scheme is restricted: these would otherwise be stored and
    # handed straight back to whoever clicks the short link.
    it "rejects javascript: and data: schemes" do
      expect(build(:link, url: "javascript:alert(1)")).not_to be_valid
      expect(build(:link, url: "data:text/html,<script>alert(1)</script>")).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:click_events).dependent(:destroy) }

    it "deletes its click events when destroyed" do
      link = create(:link)
      create(:click_event, link: link)

      expect { link.destroy }.to change(ClickEvent, :count).by(-1)
    end
  end

  describe "short_code generation" do
    it "assigns a short code after create" do
      link = create(:link)

      expect(link.short_code).to be_present
    end

    it "gives different links different codes" do
      codes = create_list(:link, 5).map(&:short_code)

      expect(codes.uniq.length).to eq(5)
    end

    it "encodes the record id in base62" do
      link = create(:link)
      alphabet = [("0".."9"), ("A".."Z"), ("a".."z")].flat_map(&:to_a).join

      decoded = link.short_code.chars.reduce(0) { |acc, c| (acc * 62) + alphabet.index(c) }
      expect(decoded).to eq(link.id)
    end

    it "persists the code to the database" do
      link = create(:link)

      expect(link.reload.short_code).to eq(link.short_code)
    end
  end

  describe "#create_short_url" do
    it "builds a URL containing the short code" do
      link = create(:link)

      expect(link.create_short_url).to end_with("/l/#{link.short_code}")
      expect(link.create_short_url).to start_with("http")
    end
  end

  describe "default scope" do
    it "orders by creation date descending" do
      old = create(:link, created_at: 2.days.ago)
      recent = create(:link, created_at: 1.hour.ago)

      expect(described_class.all.to_a).to eq([recent, old])
    end
  end
end
