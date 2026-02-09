require "rails_helper"

RSpec.describe FeatureFlags::Evaluator do
  describe "#enabled?" do
    let!(:feature) do
      Feature.create!(
        key: "dark_mode",
        default_enabled: false
      )
    end

    context "when there are no overrides" do
      it "returns the default value" do
        evaluator = FeatureFlags::Evaluator.new(
          feature_key: "dark_mode",
          user_id: "user_1",
          groups: []
        )

        expect(evaluator.enabled?).to eq(false)
      end
    end

    context "when a group override exists" do
      before do
        FeatureOverride.create!(
          feature: feature,
          target_type: "Group",
          target_identifier: "admin",
          enabled: true
        )
      end

      it "enables the feature for users in that group" do
        evaluator = FeatureFlags::Evaluator.new(
          feature_key: "dark_mode",
          user_id: "user_2",
          groups: ["admin"]
        )

        expect(evaluator.enabled?).to eq(true)
      end
    end

    context "when a user override exists" do
      before do
        FeatureOverride.create!(
          feature: feature,
          target_type: "User",
          target_identifier: "user_3",
          enabled: true
        )
      end

      it "uses the user override over the default" do
        evaluator = FeatureFlags::Evaluator.new(
          feature_key: "dark_mode",
          user_id: "user_3",
          groups: []
        )

        expect(evaluator.enabled?).to eq(true)
      end
    end

    context "when both user and group overrides exist" do
      before do
        FeatureOverride.create!(
          feature: feature,
          target_type: "Group",
          target_identifier: "admin",
          enabled: false
        )

        FeatureOverride.create!(
          feature: feature,
          target_type: "User",
          target_identifier: "user_4",
          enabled: true
        )
      end

      it "prefers the user override" do
        evaluator = FeatureFlags::Evaluator.new(
          feature_key: "dark_mode",
          user_id: "user_4",
          groups: ["admin"]
        )

        expect(evaluator.enabled?).to eq(true)
      end
    end
  end
end