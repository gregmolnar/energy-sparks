module Onboarding
  class CompletionController < BaseController
    skip_before_action :check_complete, only: :show

    def new
      @school = @school_onboarding.school
      @users = @school_onboarding.school.users.reject {|u| u.id == current_user.id || u.pupil? }
      @pupil = @school_onboarding.school.users.pupil.first
      @meters = @school.meters
      @school_times = @school.school_times.sort_by {|time| SchoolTime.days[time.day]}
      if @school.calendar
        @inset_days = @school.calendar.calendar_events.inset_days.order(:start_date, :end_date)
      end
    end

    def create
      users = @school_onboarding.school.users.reject {|u| u.id == current_user.id || u.pupil? }
      onboarding_service.complete_onboarding(@school_onboarding, users)
      redirect_to onboarding_completion_path(@school_onboarding)
    end

    def show
      if @school_onboarding.school.visible?
        redirect_to school_path(@school_onboarding.school), notice: 'Your school is now active!'
      else
        :show
      end
    end

    private

    def onboarding_service
      @onboarding_service ||= Onboarding::Service.new
    end
  end
end
