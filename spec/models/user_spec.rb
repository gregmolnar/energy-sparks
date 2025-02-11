require 'rails_helper'
require "cancan/matchers"

describe User do

  it 'generates display name' do
    user = create(:user, name:"Name")
    expect(user.display_name).to eql user.name

    user = create(:user, name: nil)
    expect(user.display_name).to eql user.email

    user = create(:user, name: "")
    expect(user.display_name).to eql user.email

  end

  describe 'pupil validation' do
    let(:school){ create(:school) }
    let!(:existing_pupil){ create(:pupil, pupil_password: 'testtest', school: school) }

    it 'checks for unique passwords within the school' do
      expect(build(:pupil, school: school, pupil_password: 'testtest')).to_not be_valid
      expect(build(:pupil, school: school, pupil_password: 'testtest123')).to be_valid
      expect(build(:pupil, school: create(:school), pupil_password: 'testtest')).to be_valid
    end
  end

  describe 'abilities' do
    subject(:ability) { Ability.new(user) }
    let(:user)        { nil }

    context "when is an admin" do
      let(:user) { create(:admin) }

      %w(Activity ActivityType ActivityCategory Calendar CalendarEvent School User SchoolTarget).each do |thing|
        it { is_expected.to be_able_to(:manage, thing.constantize.new) }
      end

      it { is_expected.to be_able_to(:show, create(:school, visible: false, public: true)) }
      it { is_expected.to be_able_to(:show, create(:school, visible: true, public: true)) }
      it { is_expected.to be_able_to(:show, create(:school, visible: false, public: true)) }
      it { is_expected.to be_able_to(:show, create(:school, visible: false, public: false)) }
    end

    context "as a school admin" do
      let(:school) { create(:school) }
      let(:another_school) { create(:school) }
      let(:user) { create(:school_admin, school: school) }

      let(:other_admin) { create(:school_admin, school: school) }
      let(:cluster_admin) { create(:school_admin, cluster_schools: [school]) }


      %i[index show usage suggest_activity].each do |action|
        it{ is_expected.to be_able_to(action, school) }
      end

      %w(ActivityType ActivityCategory SchoolTarget).each do |thing|
        it { is_expected.to_not be_able_to(:manage, thing.constantize.new) }
      end

      it { is_expected.to be_able_to(:manage, create(:school_target, school: school)) }
      it { is_expected.to_not be_able_to(:manage, create(:school_target, school: another_school)) }

      it { is_expected.to be_able_to(:manage, Activity.new(school: school)) }
      it { is_expected.not_to be_able_to(:manage, Activity.new(school: another_school)) }
      it { is_expected.to be_able_to(:read, ActivityCategory.new) }
      it { is_expected.to be_able_to(:show, ActivityType.new) }

      it "can manage another school admin for this school" do
        expect(subject).to be_able_to(:manage, other_admin)
      end

      it "cannot manage another school admin" do
        expect(subject).to_not be_able_to(:manage, create(:school_admin, school: another_school))
      end

      it "can manage cluster admin for this school" do
        expect(subject).to be_able_to(:manage, cluster_admin)
      end

    end

    context "when is a school user" do
      let(:school) { create(:school) }
      let(:another_school) { create(:school) }
      let(:user) { create(:staff, school: school) }

      %w(ActivityType ActivityCategory Calendar CalendarEvent School User).each do |thing|
        it { is_expected.not_to be_able_to(:manage, thing.constantize.new) }
      end

      %i[index show usage suggest_activity].each do |action|
        it{ is_expected.to be_able_to(action, school) }
      end

      it { is_expected.to be_able_to(:manage, create(:school_target, school: school)) }
      it { is_expected.to_not be_able_to(:manage, create(:school_target, school: another_school)) }

      it { is_expected.to be_able_to(:manage, Activity.new(school: school)) }
      it { is_expected.not_to be_able_to(:manage, Activity.new(school: another_school)) }
      it { is_expected.to be_able_to(:read, ActivityCategory.new) }
      it { is_expected.to be_able_to(:show, ActivityType.new) }
    end

    context "when is a guest" do
      let(:school) { create(:school) }
      let(:user) { create(:user, role: :guest) }

      %i[index show usage].each do |action|
        it { is_expected.to be_able_to(action, school) }
      end

      it { is_expected.to be_able_to(:suggest_activity, school) }
      it { is_expected.to be_able_to(:show, school) }
      it { is_expected.to be_able_to(:read, ActivityCategory.new) }
      it { is_expected.to be_able_to(:show, ActivityType.new) }
      it { is_expected.to be_able_to(:show, create(:school_target) ) }
    end
  end

  describe 'staff roles as symbols' do

    it 'returns nil if no staff role' do
      expect(User.new().staff_role_as_symbol).to be nil
    end

    it 'returns symbol if staff role' do
      staff_role_title = 'Awkward/Tricky and space'
      staff = build(:user, staff_role: build(:staff_role, title: staff_role_title))
      expect(staff.staff_role_as_symbol).to be :awkward_tricky_and_space
    end
  end

  describe 'welcome email' do
    let(:school) { create(:school) }
    let(:user) { create(:staff, school: school, confirmed_at: nil) }

    it 'sends welcome email after confirmation for school roles' do
      expect(user.confirmed?).to eql(false)
      expect(user.confirm ).to eql(true)

      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to eq('Welcome to Energy Sparks')
    end

    it 'does not send welcome email for other users' do
      other_user = create(:user, role: :guest, confirmed_at: nil)
      expect(other_user.confirmed?).to eql(false)
      expect(other_user.confirm ).to eql(true)

      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to eq('Energy Sparks: confirm your account')
    end

  end
end
