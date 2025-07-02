class CreateHelpforceAgents < ActiveRecord::Migration[7.1]
  def change
    create_table :helpforce_agents do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :agent_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :category
      t.string :status, default: 'active'
      t.string :ai_provider, default: 'openai'
      t.string :ai_model
      t.text :custom_prompt
      t.decimal :temperature, precision: 3, scale: 2, default: 0.7
      t.integer :max_tokens, default: 2000
      t.json :configuration, default: {}
      t.json :metrics_data, default: {}
      t.datetime :last_used_at
      t.boolean :auto_respond, default: false
      t.json :trigger_conditions, default: {}

      t.timestamps
    end

    add_index :helpforce_agents, [:account_id, :agent_id], unique: true
    add_index :helpforce_agents, [:account_id, :category]
    add_index :helpforce_agents, [:account_id, :status]
    add_index :helpforce_agents, :ai_provider
  end
end