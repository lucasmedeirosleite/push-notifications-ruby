# frozen_string_literal: true

module Pusher
  module PushNotifications
    module UseCases
      class Publish
        class PublishError < RuntimeError; end

        class << self
          def publish(*args, **kwargs)
            new(*args, **kwargs).publish
          end

          def publish_to_interests(*args, **kwargs)
            new(*args, **kwargs).publish_to_interests
          end
        end

        def initialize(interests:, payload: {})
          @interests = interests
          @payload = payload
          @user_id = Pusher::PushNotifications::UserId.new

          valid_interest_pattern = /^(_|-|=|@|,|\.|:|[A-Z]|[a-z]|[0-9])*$/

          interests.each do |interest|
            next if valid_interest_pattern.match?(interest)

            raise PublishError,
                  "Invalid interest name \nMax #{UserId::MAX_USER_ID_LENGTH}" \
                  ' characters and can only contain ASCII upper/lower-case' \
                  ' letters, numbers or one of _-=@,.:'
          end

          raise PublishError, 'Must provide at least one interest' if interests.empty?

          if interests.length > 100
            raise PublishError, "Number of interests #{interests.length}" \
            ' exceeds maximum of 100'
          end
        end

        # Publish the given payload to the specified interests.
        # <b>DEPRECATED:</b> Please use <tt>publish_to_interests</tt> instead.
        def publish
          warn "[DEPRECATION] `publish` is deprecated. \
Please use `publish_to_interests` instead."
          publish_to_interests
        end

        # Publish the given payload to the specified interests.
        def publish_to_interests
          data = { interests: interests }.merge!(payload)
          client.post('publishes', data)
        end

        private

        attr_reader :interests, :payload

        def client
          @client ||= PushNotifications::Client.new
        end
      end
    end
  end
end
