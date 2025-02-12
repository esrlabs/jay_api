# frozen_string_literal: true

require 'uri'

module JayAPI
  module Git
    module Gerrit
      # Offers a set of utility methods to work with Gerrit's Gitiles URLs.
      module GitilesHelper
        GITILES_PATH = '/plugins/gitiles/'
        GITILES_REFSPEC = '/+/%<refspec>s/'

        # Returns a Gitiles URL for the given parameters
        # @param [String] repository The URL of the git repository.
        # @param [String] refspec The name of a branch or the SHA1 of a particular
        #   commit.
        # @param [String] path The path to the source file.
        # @param [Integer, String] line_number The line number
        # @return [String] The corresponding Gitiles URL.
        def gitiles_url(repository:, refspec:, path:, line_number: nil)
          # NOTE: Here File.join is being used because it takes care of cases in
          # which both strings have slash (/) at their tips and removes the double
          # slash, for example:
          #
          #   ['https://example.com/', '/path/to/file'].join('/') => https://example.com///path/to/file
          #   File.join('https://example.com/', '/path/to/file') => https://example.com/path/to/file
          #
          # Do not use URL.join because it interprets a slash at the beginning
          # of the second string as a reference to the URL's root:
          #
          #   URI.join('https://www.example.com/hello/world', '/again') => https://www.example.com/again

          @gitiles_urls ||= {}
          base_url = @gitiles_urls[repository] ||= translate_gerrit_url(repository)

          File.join(
            base_url,
            format(GITILES_REFSPEC, refspec: refspec),
            [path, line_number].compact.join('#') # If there is no line number the # will not appear in the URL
          )
        end

        # Translates a Gerrit repository URL into a Gerrit Gitiles URL for that
        # repository, for example:
        #
        # ssh://jenkins@gerrit.local:29418/tools/elite becomes
        #   https://gerrit.local/plugins/gitiles/tools/elite
        # @param [String] url Gerrit's repository URL
        # @return [String] The corresponding Gitiles URL
        def translate_gerrit_url(url)
          uri = URI.parse(url)
          path = uri.path.sub(%r{^/a/}, '/') # Removes the /a/ at the beginning of HTTP/S repository URLs
          URI::HTTPS.build(host: uri.host, path: File.join(GITILES_PATH, path)).to_s
        end
      end
    end
  end
end
