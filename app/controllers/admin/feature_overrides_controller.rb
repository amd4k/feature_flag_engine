class Admin::FeatureOverridesController < ApplicationController
  def create
    feature = Feature.find(params[:feature_id])
    override = feature.feature_overrides.new(override_params)

    if override.save
      redirect_to edit_admin_feature_path(feature), notice: "Override added successfully"
    else
      redirect_to edit_admin_feature_path(feature), alert: override.errors.full_messages.to_sentence
    end

  end

  def destroy
    feature = Feature.find(params[:feature_id])
    override = feature.feature_overrides.find(params[:id])
    override.destroy
    redirect_to edit_admin_feature_path(feature), notice: "Override removed successfully"
  end

  private
    def override_params
      params.require(:feature_override)
            .permit(:target_type, :target_identifier, :enabled)
    end
end
