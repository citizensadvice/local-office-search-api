# frozen_string_literal: true

module LoaderHelpers
  private

  def defer_constraint_until_commit!(constraint_id)
    ActiveRecord::Base.connection.execute("SET CONSTRAINTS #{constraint_id} DEFERRED")
  end
end
