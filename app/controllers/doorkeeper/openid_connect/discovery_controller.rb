module Doorkeeper
  module OpenidConnect
    class DiscoveryController < ::Doorkeeper::ApplicationController
      include Doorkeeper::Helpers::Controller

      WEBFINGER_RELATION = 'http://openid.net/specs/connect/1.0/issuer'

      def provider
        render json: provider_response
      end

      def webfinger
        render json: webfinger_response
      end

      def keys
        render json: keys_response
      end

      private

      def provider_response
        doorkeeper = ::Doorkeeper.configuration
        openid_connect = ::Doorkeeper::OpenidConnect.configuration
        {
          issuer: openid_connect.issuer,
          authorization_endpoint: oauth_authorization_url(protocol: :https),
          token_endpoint: oauth_token_url(protocol: :https),
          userinfo_endpoint: oauth_userinfo_url(protocol: :https),
          jwks_uri: oauth_discovery_keys_url(protocol: :https),

          scopes_supported: doorkeeper.scopes,

          # TODO: support id_token response type
          response_types_supported: doorkeeper.authorization_response_types,
          response_modes_supported: [ 'query', 'fragment' ],

          token_endpoint_auth_methods_supported: [
            'client_secret_basic',
            'client_secret_post',

            # TODO: look into doorkeeper-jwt_assertion for these
            #'client_secret_jwt',
            #'private_key_jwt'
          ],

          # TODO: make this configurable
          subject_types_supported: [
            'public',
          ],

          # TODO: make this configurable
          id_token_signing_alg_values_supported: [
            'RS256',
          ],
        }
      end

      def webfinger_response
        {
          subject: params.require(:resource),
          links: [
            {
              rel: WEBFINGER_RELATION,
              href: root_url(protocol: :https),
            }
          ]
        }
      end

      def keys_response
        signing_key = Doorkeeper::OpenidConnect.signing_key

        {
          keys: [
            signing_key.slice(:kty, :kid, :e, :n).merge(
              use: 'sig',
              alg: Doorkeeper::OpenidConnect::SIGNING_ALGORITHM
            )
          ]
        }
      end
    end
  end
end
