# frozen_string_literal: true

require_relative '../git/repository'

module JayAPI
  module RSpec
    # Git-related methods for the +TestDataCollector+
    module Git
      private

      # @return [JayAPI::Git::Repository] An instance of the +Repository+ class
      #   set to target the Git repository in the current working directory.
      def git_repository
        @git_repository ||= JayAPI::Git::Repository.new(url: nil, clone_path: Dir.pwd)
      end

      # @return [String] The SHA1 of the current revision for the repository
      #   from which RSpec is running. If JayAPI's Git library cannot obtain it
      #   then an attempt is made to get it directly from Git's CLI.
      def fetch_git_revision
        git_repository.log(count: 1).first.sha
      rescue ::Git::GitExecuteError
        # It wasn't possible to obtain the SHA1 of the repository via the Git
        # Library. it may still be possible to get it via Git's CLI.
        `git rev-parse HEAD`.chomp
      end

      # @return [String] The SHA1 of current repository's revision.
      # @see #fetch_git_revision
      def git_revision
        @git_revision ||= fetch_git_revision
      end

      # Attempts to get the URL of the first remote associated with the Git
      # repository in the current working directory.
      # @return [String] The URL of the remote, or an empty string if the
      #   attempt fails.
      def remote_from_command
        `git remote get-url $(git remote show | head -n 1)`.chomp
      end

      # @return [String] The URL of the first remote associated with the
      #   repository from which
      def fetch_git_remote
        git_repository.remote_url || remote_from_command
      rescue ::Git::GitExecuteError
        # It wasn't possible to obtain the repository's remote URL via the Git
        # Library. it may still be possible to get it via Git's CLI.
        remote_from_command
      end

      # @return [String] The URL of the first remote associated with the current
      #   repository.
      # @see #fetch_git_remote
      def git_remote
        @git_remote ||= fetch_git_remote
      end
    end
  end
end
