module Agents
  class Mongodb < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!

    default_schedule "12h"
    gem_dependency_check { defined?(Mongo::Client) }
    form_configurable :host
    form_configurable :database
    form_configurable :user
    form_configurable :password
    form_configurable :collection

    form_configurable :guid
    form_configurable :data
    form_configurable :should_emit, type: :text

    description <<-MD
      Mongo DB agent
    MD

    def default_options
      {
        host: "",
        database: "",
        user: "",
        password: "",
        collection: "",
        guid: "{{guid}}",
        data: "{{data}}",
        should_emit: "{% if guid %}true{% endif %}",
      }
    end

    def validate_options
    end

    def working?
      received_event_without_error?
    end

    #    def check
    #    end

    def receive(incoming_events)
      Mongo::Logger.logger.level = ::Logger::FATAL
      mongo_client = Mongo::Client.new(
        [ interpolated["host"] ],
        user: interpolated["user"],
        password: interpolated["password"],
        database: interpolated["database"],
        auth_source: "admin"
      )
      incoming_events.each do |event|
        payload = interpolated(event)
        should_emit = payload["should_emit"]
        next unless should_emit == "true"

        collection = interpolated["collection"]
        guid = payload["guid"]
        matches = guid.split("/")
        if matches.size > 1
          collection = matches.first
        end
        client = mongo_client[collection]
        payload["data"]["_id"] = guid
        result = client.update_one(
          { _id: payload["guid"] },
          payload["data"],
          { upsert: true }
        )
      end
    end
  end
end
