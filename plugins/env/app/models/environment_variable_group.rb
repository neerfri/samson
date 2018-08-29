# frozen_string_literal: true
class EnvironmentVariableGroup < ActiveRecord::Base
  include AcceptsEnvironmentVariables
  extend AuditOnAssociation

  audits_on_association(
    :projects,
    :environment_variable_groups,
    audit_name: :environment_variables,
    &:serialized_environment_variables
  )

  default_scope -> { order(:name) }

  has_many :project_environment_variable_groups, dependent: :destroy
  has_many :projects, through: :project_environment_variable_groups

  validates :name, presence: true

  def variable_names
    environment_variables.sort_by(&:id).map(&:name).uniq
  end

  def as_json(options = nil)
    super({methods: [:variable_names]}.merge(options || {}))
  end
end
