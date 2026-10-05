# frozen_string_literal: true

# Migration to populate issue estimated_hours based on Mistral compute time estimation
# Formula: estimated_hours = (LENGTH(subject) + LENGTH(description)) / 120.0
# Rationale: 
# - Mistral processes ~30 tokens/second
# - 1 token ≈ 4 characters
# - Scaling factor: 1 second compute time ≈ 1 hour human time estimate
# - Therefore: chars / 4 / 30 / 3600 * 3600 = chars / 120

class AddMistralComputeTimeEstimates < ActiveRecord::Migration[7.0]
  def up
    # Update all issues with NULL estimated_hours
    Issue.where(estimated_hours: nil).find_each do |issue|
      total_length = issue.subject.length + (issue.description || "").length
      # Avoid division by zero and ensure reasonable minimum
      issue.estimated_hours = [total_length / 120.0, 0.1].max
      issue.save!(validate: false)
    end
  end

  def down
    # Set estimated_hours back to NULL for all issues updated by this migration
    Issue.where.not(estimated_hours: nil).update_all(estimated_hours: nil)
  end
end
