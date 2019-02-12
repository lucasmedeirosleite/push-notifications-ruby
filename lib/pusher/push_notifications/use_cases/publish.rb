# frozen_string_literal: true

require 'caze'
require 'forwardable'

module Pusher
  module PushNotifications
    module UseCases
      class Publish
        include Caze
        extend Forwardable

        class PublishError < RuntimeError; end

        export :publish, as: :publish
        export :publish_to_interests, as: :publish_to_interests

        def initialize(interests:, payload: {})
          @interests = interests
          @payload = payload
          @user_id = Pusher::PushNotifications::UserId.new

          valid_interest_pattern = /^(_|\-|=|@|,|\.|:|[A-Z]|[a-z]|[0-9])*$/

          interests.each do |interest|
            unless valid_interest_pattern.match?(interest)
              raise PublishError, "Invalid interest name \nMax #{max_user_id_length} characters and can only contain ASCII upper/lower-case letters, numbers or one of _-=@,.:"
            end
          end

          raise PublishError, 'Must provide at least one interest' if interests.empty?
          raise PublishError, "Number of interests #{interests.length} exceeds maximum of 100" if interests.length > 100
        end

        # Publish the given payload to the specified interests.
        # <b>DEPRECATED:</b> Please use <tt>publish_to_interests</tt> instead.
        def publish
          warn '[DEPRECATION] `publish` is deprecated.  Please use `publish_to_interests` instead.'
          publish_to_interests
        end

        # Publish the given payload to the specified interests.
        def publish_to_interests
          data = { interests: interests }.merge!(payload)
          client.post('publishes', data)
        end

        private

        attr_reader :interests, :payload, :user_id
        def_delegators :@user_id, :max_user_id_length

        def client
          @client ||= PushNotifications::Client.new
        end
      end
    end
  end
end
