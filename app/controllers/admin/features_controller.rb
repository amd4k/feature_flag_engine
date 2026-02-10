class Admin::FeaturesController < ApplicationController
  def index
    @features = Feature.order(:key)
  end

  def new
    @feature = Feature.new
  end

  def create
    @feature = Feature.new(feature_params)
    if @feature.save
      redirect_to admin_features_path, notice: "Feature created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
  end

  private
  def feature_params
    params.require(:feature).permit(:key, :default_enabled)
  end
end
