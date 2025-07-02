class CreateConversationAgentAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_agent_assignments do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :helpforce_agent, null: false, foreign_key: true
      t.text :assignment_reason
      t.decimal :confidence_score, precision: 5, scale: 2
      t.boolean :auto_assigned, default: false
      t.boolean :active, default: true
      t.datetime :assigned_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :unassigned_at
      t.json :assignment_metadata, default: {}

      t.timestamps
    end

    add_index :conversation_agent_assignments, [:conversation_id, :active]
    add_index :conversation_agent_assignments, [:helpforce_agent_id, :assigned_at]
    add_index :conversation_agent_assignments, :auto_assigned
    add_index :conversation_agent_assignments, :confidence_score
  end
end