module Agents
  class NotionDb < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!

    default_schedule "12h"
    gem_dependency_check { defined?(Notion::Client) }

    form_configurable :access_token
    form_configurable :database_id
    form_configurable :database_name
    form_configurable :should_emit, type: :text

    description <<-MD
      Fetch notion database
    MD

    def default_options
      {
        access_token: "",
        should_emit: "{% if data.id %}true{% endif %}",
        database_id: "{{data.id}}",
        database_name: "{{data.database_type}}",
      }
    end
    def validate_options
    end

    def working?
      received_event_without_error?
    end

    def receive(incoming_events)
      notion_client = Notion::Client.new(token: interpolated["access_token"])
      metas = { model: "notion_data" }


      incoming_events.each do |event|
        payload = interpolated(event)
        collection = interpolated["collection"]
        should_emit = payload["should_emit"]
        database_id = payload["database_id"]
        database_name = payload["database_name"]
        metas[:database_id] = database_id
        metas[:database_name] = database_name

        next unless should_emit == "true"


        notion_client.database_query(database_id: database_id) do |page|
          page_json = page.as_json
          next if page_json["results"].nil?
          results = page_json["results"].each do |result|
            to_send = parse_notion_result(result)
            metas[:notion_id] = result["id"]
            metas[:notion_type] = result["object"]
            metas[:archived] = result["archived"]
            metas[:notion_url] = result["url"]
            create_event payload: {
              metas: metas,
              data: to_send["properties"]
            }
          end
        end
      end
    end
    private
      def parse_notion_result(result)
        result["created_by"] = result.dig("created_by", "id")
        result["last_edited_by"] = result.dig("last_edited_by", "id")
        result["icon"] = result.dig("icon", "file", "url")
        result["properties"] = result["properties"].map do |key, value|
          type = value.dig("type")
          case type
          when "multi_select"
            Hash[key, value["multi_select"].map do |option|
              option["name"]
            end]
          when "last_edited_time"
            Hash[key, value.dig("last_edited_time")]
          when "created_by"
            Hash[key, value.dig("created_by", "id")]
          when "title"
            Hash[key, value["title"].map do |paragraph|
              paragraph.dig("plain_text")
            end.join("")]
          when "number"
            Hash[key, value.dig("number")]
          when "relation"
            Hash[key, value["relation"].map do |relation|
              relation.dig("id")
            end.join("")]
          when "date"
            [
              Hash["#{key} (START)", value.dig("date", "start")],
              Hash["#{key} (END)", value.dig("date", "end")]
            ].reduce(:merge)
          when "select"
            Hash[key, value.dig("select", "name")]
          when "rich_text"
            Hash[key, value["rich_text"].map do |paragraph|
              paragraph.dig("plain_text")
            end.join("")]
          else
            Hash[key, value]
          end
        end.reduce(:merge)
        result
      end
  end
end
