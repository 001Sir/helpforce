class AddConfigTypeToInstallationConfigs < ActiveRecord::Migration[7.1]
  def change
    add_column :installation_configs, :config_type, :string
  end
end
