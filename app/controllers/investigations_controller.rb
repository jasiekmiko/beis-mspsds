class InvestigationsController < ApplicationController
  include InvestigationsHelper
  helper_method :sort_column, :sort_direction

  before_action :set_search_params, only: %i[index]
  before_action :set_investigation, only: %i[show edit update destroy assign update_assignee status]
  before_action :create_investigation, only: %i[create]

  # GET /investigations
  # GET /investigations.json
  # GET /investigations.xlsx
  def index
    @investigations = search_for_investigations(20)
  end

  # GET /investigations/1
  # GET /investigations/1.json
  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: @investigation.id.to_s
      end
    end
  end

  # GET /investigations/new
  def new
    @investigation = Investigation.new
  end

  # GET /investigations/1/edit
  def edit; end

  # GET /investigations/1/status
  def status; end

  # GET /investigations/1/assign
  def assign
    redirect_to investigation_path(@investigation) if @investigation.is_closed
    @assignee = @investigation.assignee
  end

  # POST /investigations/1/update_assignee
  def update_assignee
    assignee = User.find_by(email: params[:email].downcase)
    @investigation.assignee = assignee
    save_and_respond "Assignee was successfully updated."
    record_assignment
    NotifyMailer.assigned_investigation(@investigation, assignee).deliver if assignee.present?
  end

  # POST /investigations
  # POST /investigations.json
  def create
    respond_to do |format|
      if @investigation.save
        format.html { redirect_to @investigation, notice: "Investigation was successfully created." }
        format.json { render :show, status: :created, location: @investigation }
      else
        format.html { render :new }
        format.json { render json: @investigation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /investigations/1
  # PATCH/PUT /investigations/1.json
  def update
    respond_to do |format|
      if @investigation.update(investigation_params)
        format.html { redirect_to @investigation, notice: "Investigation was successfully updated." }
        format.json { render :show, status: :ok, location: @investigation }
      else
        format.html { render :edit }
        format.json { render json: @investigation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /investigations/1
  # DELETE /investigations/1.json
  def destroy
    authorize @investigation
    @investigation.destroy
    respond_to do |format|
      format.html { redirect_to investigations_url, notice: "Investigation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

private

  # Use callbacks to share common setup or constraints between actions.
  def save_and_respond(notice)
    respond_to do |format|
      if @investigation.save
        format.html { redirect_to @investigation, notice: notice }
        format.json { render :show, status: :ok, location: @investigation }
      else
        format.html { render :show }
        format.json { render json: @investigation.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_investigation
    @investigation = Investigation.new(investigation_params)
    @investigation.source = UserSource.new(user: current_user)
  end

  def set_investigation
    @investigation = Investigation.find(params[:id])
  end

  def record_assignment
    @investigation.activities.create(
      source: UserSource.new(user: current_user),
      activity_type: :assign,
      notes: "Assigned to #{@investigation.assignee.present? ? @investigation.assignee.email : 'Unassigned'}"
    )
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def investigation_params
    params.require(:investigation).permit(
      :title, :description, :risk_overview, :image, :risk_level, :sensitivity, :is_closed,
      product_ids: [],
      business_ids: []
    )
  end
end
