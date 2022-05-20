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
        data: "{{data}}"
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
      collection = mongo_client[interpolated["collection"]]
      incoming_events.each do |event|
        payload = interpolated(event)
        payload["data"]["_id"] = payload["guid"]
        result = collection.update_one(
          { _id: payload["guid"] },
          payload["data"],
          { upsert: true }
        )
      end
    end
  end
end
