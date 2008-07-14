module ActiveRecord
    class Migrator
        class << self
            def migrate_data(migrations_path, target_version = nil)
                @migrating_data = true
                migrate(migrations_path, target_version)
            end
            
            def current_version
                if @migrating_data
                    Base.connection.select_value("SELECT data_version FROM #{schema_info_table_name}").to_i
                else
                    Base.connection.select_value("SELECT version FROM #{schema_info_table_name}").to_i
                end
            end
        end
        def initialize(direction, migrations_path, target_version = nil)
            raise StandardError.new("This database does not yet support migrations") unless Base.connection.supports_migrations?
            @direction, @migrations_path, @target_version = direction, migrations_path, target_version
            @migrating_data = migrations_path.include?("data")
            Base.connection.initialize_schema_information
        end
        
        def set_schema_version(version)            
            if @migrating_data 
                Base.connection.update("UPDATE #{self.class.schema_info_table_name} SET data_version = #{down? ? version.to_i - 1 : version.to_i}")
            else 
                Base.connection.update("UPDATE #{self.class.schema_info_table_name} SET version = #{down? ? version.to_i - 1 : version.to_i}")
            end
        end
    end
end

module ActiveRecord
    module ConnectionAdapters # :nodoc:
        module SchemaStatements
            
            def initialize_schema_information
                begin
                    execute "CREATE TABLE #{quote_table_name(ActiveRecord::Migrator.schema_info_table_name)} (version #{type_to_sql(:integer)}, data_version #{type_to_sql(:integer)})"
                    execute "INSERT INTO #{quote_table_name(ActiveRecord::Migrator.schema_info_table_name)} (version, data_version) VALUES(0, 0)"
                rescue ActiveRecord::StatementInvalid
                    # Schema has been initialized
                end
            end
            
            def dump_schema_information #:nodoc:
                begin
                    if (current_schema = ActiveRecord::Migrator.current_version) > 0              
                        current_data_schema = ActiveRecord::Migrator.current_version
                        return "INSERT INTO #{quote_table_name(ActiveRecord::Migrator.schema_info_table_name)} (version, data_version) VALUES (#{current_schema}, #{current_data_schema})" 
                    end
                rescue ActiveRecord::StatementInvalid 
                    # No Schema Info
                end
            end
        end
    end
end