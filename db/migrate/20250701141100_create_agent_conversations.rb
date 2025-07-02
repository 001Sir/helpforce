class CreateAgentConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_conversations do |t|
      t.references :helpforce_agent, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.text :message_content
      t.text :response_content
      t.string :ai_provider
      t.string :ai_model
      t.decimal :response_time, precision: 8, scale: 3
      t.integer :tokens_used
      t.decimal :confidence_score, precision: 5, scale: 4
      t.json :metadata, default: {}
      t.boolean :was_helpful
      t.text :feedback

      t.timestamps
    end

    add_index :agent_conversations, [:helpforce_agent_id, :created_at]
    add_index :agent_conversations, [:conversation_id, :created_at]
    add_index :agent_conversations, :ai_provider
    add_index :agent_conversations, :response_time
  end
end