require 'rails_helper'

RSpec.describe "Admin::FeatureOverrides", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/admin/feature_overrides/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/admin/feature_overrides/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
