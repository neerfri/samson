# frozen_string_literal: true
module GroupScope
  def self.included(base)
    base.validates :scope_type, inclusion: ["Environment", "DeployGroup", nil]
    base.belongs_to :scope, polymorphic: true, optional: true
  end

  def self.split(scoped_type_and_id)
    scoped_type_and_id.split("-", 2)
  end

  # used to assign direct from form values
  def scope_type_and_id=(value)
    self.scope_type, self.scope_id = GroupScope.split(value.to_s)
  end

  def scope_type_and_id
    return unless scope_type && scope_id
    "#{scope_type}-#{scope_id}"
  end

  def matches_scope?(deploy_group)
    return true unless scope_id # for all
    return false unless deploy_group # unscoped -> no specific groups

    case scope_type
    when "DeployGroup" then scope_id == deploy_group.id # matches deploy group
    when "Environment" then scope_id == deploy_group.environment_id # matches deploy group's environment
    else raise "Unsupported scope #{scope_type}"
    end
  end

  def priority
    [
      (project? ? 0 : 1),
      case scope_type
      when nil then 2
      when "Environment" then 1
      when "DeployGroup" then 0
      else raise "Unsupported scope #{scope_type}"
      end
    ]
  end

  def as_json(options = nil)
    super({methods: [:scope]}.merge(options || {}))
  end
end
