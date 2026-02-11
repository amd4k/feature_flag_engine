module FeatureFlags
  class Evaluator
    def initialize(feature_key:, user_id:, groups:)
      @feature_key = feature_key
      @user_id = user_id
      @groups = groups
    end

    def enabled?
    feature = Feature.find_by(key: @feature_key)
    return false unless feature

    user_override = FeatureOverride.find_by(
        feature: feature,
        target_type: "User",
        target_identifier: @user_id
    )
    return user_override.enabled if user_override

    group_override = FeatureOverride
        .where(
        feature: feature,
        target_type: "Group",
        target_identifier: @groups
        )
        .order(created_at: :desc)
        .first
    return group_override.enabled if group_override

    feature.default_enabled
    end

  end
end