class CreateAgentMetrics < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_metrics do |t|
      t.references :helpforce_agent, null: false, foreign_key: true
      t.string :metric_type, null: false
      t.decimal :value, precision: 10, scale: 4
      t.json :metadata, default: {}
      t.date :metric_date
      t.datetime :recorded_at, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :agent_metrics, [:helpforce_agent_id, :metric_type, :metric_date], 
              name: 'index_agent_metrics_on_agent_type_date'
    add_index :agent_metrics, [:helpforce_agent_id, :recorded_at]
    add_index :agent_metrics, :metric_type
  end
end