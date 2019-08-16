module AuroraBootstrapper
  class Database
    def initialize( database_name:, client:, blacklisted_tables: [], blacklisted_fields: [] )
      @database_name      = database_name
      @blacklisted_tables = blacklisted_tables
      @blacklisted_fields = blacklisted_fields
      @client             = client
    end

    def table_names
      @table_names ||= @client.query( "SHOW TABLES IN #{@database_name}" ).map do | row |
        row[ "Tables_in_#{@database_name}" ]
      end.reject do | table_name |
        blacklisted_table?( table_name )
      end
    end

    def export!( into_bucket )
      table_names.all? do | table_name |
        table = Table.new database_name: @database_name,
                             table_name: table_name,
                                 client: @client,
                     blacklisted_fields: @blacklisted_fields

        table.export!( into_bucket: into_bucket )
      end
    end

    def blacklisted_table?( table_name )
      @blacklisted_tables.any? do | blacklisted_table |
        # blacklisted tables can be in the format of "table" or "database.table"
        
        bl_table_name    = blacklisted_table
        bl_database_name = @database_name

        if blacklisted_table.match( /\/.*\// )
          regexp         = blacklisted_table.slice(1...-1)
          qualified_name = "#{@database_name}.#{table_name}"

          bl_table_name  = qualified_name.match( /#{regexp}/ ) ? table_name : false
        
        elsif blacklisted_table.match( /[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+/ )
          bl_database_name, bl_table_name = blacklisted_table.split(".")
        end

        bl_table_name    == table_name &&
        bl_database_name == @database_name
      end
    end
  end
end
