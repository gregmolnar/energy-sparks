module Admin
  module AlertTypes
    class SchoolAlertTypeExceptionsController < AdminController
      load_and_authorize_resource :school_alert_type_exception
      load_and_authorize_resource :alert_type

      def index
        @exceptions = SchoolAlertTypeException.where(alert_type: @alert_type)
      end

      def new_multiple
        @schools = School.all
      end

      def create_multiple
        school_ids = params[:school_ids]

        SchoolAlertTypeException.where(alert_type: @alert_type).delete_all

        school_ids.each do |school_id|
          SchoolAlertTypeException.create(alert_type: @alert_type, school_id: school_id)
        end
        redirect_to admin_alert_type_school_alert_type_exceptions_path(@alert_type)
      end

      def destroy
        @school_alert_type_exception.delete
        redirect_to admin_alert_type_school_alert_type_exceptions_path(@alert_type)
      end
    end
  end
end
