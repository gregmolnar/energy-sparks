module Schools
  class ActivityTypesController < ApplicationController
    load_resource :school
    load_and_authorize_resource

    # GET /activity_types
    def index
      @activity_types = @activity_types.includes(:activity_category).order("activity_categories.name", :name)
    end

    # GET /activity_types/1
    def show
      @recorded = Activity.where(activity_type: @activity_type).count
      @school_count = Activity.select(:school_id).where(activity_type: @activity_type).distinct.count
    end
  end
end
