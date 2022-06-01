module Agents
  class NotionList < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!

    default_schedule "12h"
    gem_dependency_check { defined?(Notion::Client) }
    form_configurable :access_token
    form_configurable :filters, type: :text
    form_configurable :sorts, type: :text
    form_configurable :model, type: :array, values: %w(users databases)

    description <<-MD
      List Notion Data
    MD

    def default_options
      {
        access_token: "",
        filters: "",
        sorts: "",
        model: "databases"
      }
    end

    def validate_options
    end

    def working?
      received_event_without_error?
    end

    def check
      notion_client = Notion::Client.new(token: interpolated["access_token"])
      metas = { model: "notion_#{interpolated["model"]}" }
      notion_options = {}
      notion_options[:filter] = JSON.parse(interpolated["filters"]) unless interpolated["filters"].empty?
      notion_options[:sorts]= JSON.parse(interpolated["sorts"]) unless interpolated["sorts"].empty?
      case options["model"]
      when "users"
        notion_client.users_list(**notion_options).each do |page|
          attribute = page.first
          next if attribute != "results"
          rows = page.last
          next if rows.nil?

          rows.each do |user|
            create_event payload: {
              metas: metas,
              data: user.as_json
            }
          end
        end
      when "databases"
        additional_filters = { property: 'object', value: 'database' }
        if notion_options[:filter].nil?
          notion_options[:filter] = additional_filters
        else
          notion_options[:filter] = {and: [additional_filters, notion_options[:filter]]}
        end
        notion_client.search(**notion_options).each do |database_search|
          attribute = database_search.first
          next if attribute != "results"

          rows = database_search.last
          next if rows.nil?
          rows.each do |database|
            title = database["title"].map do |rich_text|
              rich_text["plain_text"]
            end.join("")
            database["database_title"] = title
            database["database_type"] = title.gsub(/\[(\w+)\]/).first
            create_event payload: {
              metas: metas,
              data: database
            }
          end
        end
      end
   end
  end
end