# frozen_string_literal: true

require 'git'
require 'logging'
require 'pathname'
require 'uri'

require_relative 'errors/invalid_repository_error'
require_relative 'errors/missing_url_error'

module JayAPI
  module Git
    # :reek:MissingSafeMethod safe method `update` is defined as alias of clone

    # Represents a Git repository. Offers a set of methods to lazy clone a
    # repository and update it when necessary. As well as a set of methods to
    # work with the repository's branches and files.
    class Repository
      attr_reader :url, :clone_location, :clone_path

      # Creates a new instance of the class.
      # @param [String, nil] url The URL of the git repository. This parameter
      #   can be +nil+ *ONLY* for repositories that already exist.
      # @param [String] clone_location The path to the location where the
      #   repository should be cloned. (A new folder with the Repository's name
      #   will be created INSIDE the given directory).
      # @param [String] clone_path The path to the directory where the
      #   repository should be cloned. (The repository will be cloned DIRECTLY
      #   in this directory).
      # @param [Logging::Logger] logger The logger for the class (as well as for
      #   the Git client).
      def initialize(url:, clone_location: nil, clone_path: nil, logger: nil)
        raise ArgumentError, 'Either clone_location or clone_path must be given' unless clone_location || clone_path
        raise ArgumentError, 'Either clone_path or url must be given' unless url || clone_path

        @url = url
        @logger = logger || Logging.logger[self]
        @clone_path = Pathname.new(clone_path || File.join(clone_location, name))
        @clone_path = Pathname.pwd.join(@clone_path) unless @clone_path.absolute?
        @clone_location = @clone_path.dirname
      end

      # @return [Boolean] True if the repository directory exists on the disk,
      #   false otherwise
      def exist?
        clone_path.exist?
      end

      # @return [Boolean] True if the repository directory directory exists and
      #   is a valid git repository, false otherwise.
      def valid?
        exist? && clone_path.directory? && git_dir.exist? && git_dir.directory?
      end

      # Clones the repository or updates it, if it already exists.
      # @raise [JayAPI::Git::Errors::MissingURLError] If no repository URL was
      #   provided.
      def clone
        valid? ? update! : clone!
      end

      alias update clone

      # Clones the repository. If the repository already exists the directory is
      # completely removed and the repository cloned again.
      # @raise [Git::GitExecuteError] If the repository cannot be cloned.
      # @raise [JayAPI::Git::Errors::MissingURLError] If no repository URL was
      #   provided.
      def clone!
        clone_path.rmtree if exist?
        clone_location.mkpath
        clone_repo
        self
      end

      # Updates the repository (without checking if it already exists or cloning
      # it beforehand).
      # @raise [ArgumentError] If the repository path doesn't exist.
      # @raise [Git::GitExecuteError] If the repository path exists but it does
      #   not contain a valid git repository.
      def update!
        open_repo
        repository.fetch(remote = repository.remotes.first.name)
        repository.pull(remote, repository.current_branch)
        self
      end

      # Checks out the specified commit. If the Repository is not yet initialized, then
      #   it will be opened or cloned depending on whether the repository exists.
      # @param [String] commit The SHA1 representing the commit.
      def checkout(commit)
        open_or_clone
        checkout!(commit)
      end

      # Checks out the specified commit.
      # @param [String] commit The SHA1 representing the commit.
      def checkout!(commit)
        raise JayAPI::Git::Errors::InvalidRepositoryError unless repository

        repository.checkout commit
      end

      # @return [String] The name of the directory in which the repository
      # was/will be cloned.
      def name
        @name ||= url ? directory_from_url : File.basename(clone_path)
      end

      # Returns the Git object that correspond to the given reference (normally
      # a Git::Object::Commit). If the Repository is not yet initialized then,
      # if the repository exists it will be open if not it will be cloned.
      # @param [String] objectish The reference to the object whose information
      #   should be retrieved. Normally this would be a SHA1 for a specific
      #   commit but it could also be a branch, a tag or any other valid git
      #   reference.
      # @raise [ArgumentError] If the Repository cannot be opened.
      # @raise [Git::GitExecuteError] If the repository cannot be cloned, or the
      #   given reference doesn't exist or is not a valid git object reference.
      # @raise [JayAPI::Git::Errors::MissingURLError] If the repository doesn't
      #   exist yet and no repository URL was provided for the cloning.
      def object(objectish)
        open_or_clone
        object!(objectish)
      end

      # Returns the Git object that correspond to the given reference (normally
      # a Git::Object::Commit).
      # @param [String] objectish The reference to the object whose information
      #   should be retrieved. Normally this would be a SHA1 for a specific
      #   commit but it could also be a branch, a tag or any other valid git
      #   reference.
      # @raise [JayAPI::Git::Errors::InvalidRepositoryError] If the repository
      #   is not a valid repository (it hasn't been initialized: cloned or
      #   open).
      # @raise [Git::GitExecuteError] If the given reference doesn't exist or is
      #   not a valid git object reference.
      def object!(objectish)
        raise JayAPI::Git::Errors::InvalidRepositoryError unless repository

        repository.object(objectish)
      end

      # Returns a Git::Branches object with the collection of branches in the
      # repository.
      # @return [Git::Branches] The collection of branches in the repository.
      # @raise [ArgumentError] If the Repository cannot be opened.
      # @raise [Git::GitExecuteError] If the repository cannot be cloned.
      # @raise [JayAPI::Git::Errors::MissingURLError] If the repository doesn't
      #   exist yet and no repository URL was provided for the cloning.
      def branches
        open_or_clone
        branches!
      end

      # Returns a Git::Branches object with the collection of branches in the
      # repository.
      # @return [Git::Branches] The collection of branches in the repository.
      # @raise [JayAPI::Git::Errors::InvalidRepositoryError] If the repository
      #   is not a valid repository (it hasn't been initialized: cloned or
      #   open).
      def branches!
        raise JayAPI::Git::Errors::InvalidRepositoryError unless repository

        repository.branches
      end

      # Returns an +Array+ of objects representing the Remote Repositories
      # linked to the repository. The array may be empty but normally it
      # contains at least one element (origin).
      # @return [Array<Git::Remote>] The collection of remote repositories
      #   linked to the repository.
      # @raise [ArgumentError] If the Repository cannot be opened.
      # @raise [Git::GitExecuteError] If the repository cannot be cloned.
      # @raise [JayAPI::Git::Errors::MissingURLError] If the repository doesn't
      #   exist yet and no repository URL was provided for the cloning.
      def remotes
        open_or_clone
        remotes!
      end

      # Returns an +Array+ of objects representing the Remote Repositories
      # linked to the repository. The array may be empty but normally it
      # contains at least one element (origin).
      # @return [Array<Git::Remote>] The collection of remote repositories
      #   linked to the repository.
      # @raise [JayAPI::Git::Errors::InvalidRepositoryError] If the repository
      #   is not a valid repository (it hasn't been initialized: cloned or
      #   open).
      def remotes!
        raise JayAPI::Git::Errors::InvalidRepositoryError unless repository

        repository.remotes
      end

      # @return [String, nil] The URL of the remote repository.
      def remote_url
        @remote_url ||= remotes.first&.url
      end

      # Returns a Git::Log object: The collection of commits in the current
      # branch or under the specified reference (if given).
      # @param [String] objectish A git reference. Normally this would be a
      #   branch's name but it could also be a tag, the SHA1 for a specific
      #   commit or any other valid git reference.
      # @param [Integer] count The maximum number of commits to return in the
      #   collection, if omitted all the commits will be returned.
      # @return [Git::Log] A Git::Log object with the collection of commits.
      # @raise [ArgumentError] If the Repository cannot be opened.
      # @raise [Git::GitExecuteError] If the repository cannot be cloned.
      # @raise [JayAPI::Git::Errors::MissingURLError] If the repository doesn't
      #   exist yet and no repository URL was provided for the cloning.
      def log(objectish: nil, count: nil)
        open_or_clone
        log!(objectish: objectish, count: count)
      end

      # Returns a Git::Log object: The collection of commits in the current
      # branch or under the specified reference (if given).
      # @param [String] objectish A git reference. Normally this would be a
      #   branch's name but it could also be a tag, the SHA1 for a specific
      #   commit or any other valid git reference.
      # @param [Integer] count The maximum number of commits to return in the
      #   collection, if omitted all the commits will be returned.
      # @return [Git::Log] A Git::Log object with the collection of commits.
      # @raise [JayAPI::Git::Errors::InvalidRepositoryError] If the repository
      #   is not a valid repository (it hasn't been initialized: cloned or
      #   open).
      def log!(objectish: nil, count: nil)
        raise JayAPI::Git::Errors::InvalidRepositoryError unless repository

        objectish ? repository.gblob(objectish).log(count) : repository.log(count)
      end

      # Adds a new worktree to the repository.
      # @param [String] path The path where the worktree should be created.
      # @param [String] branch The branch that should be checked out in the
      #   working tree. If no branch is provided the current HEAD will be
      #   checked out in a new branch.
      # @return [Git::Worktree] The object representing the newly created
      #   worktree.
      # @raise [ArgumentError] If the Repository cannot be opened.
      # @raise [Git::GitExecuteError] If the repository cannot be cloned or if
      #   the worktree cannot be created.
      # @raise [JayAPI::Git::Errors::MissingURLError] If the repository doesn't
      #   exist yet and no repository URL was provided for the cloning.
      def add_worktree(path:, branch: nil)
        open_or_clone
        add_worktree!(path: path, branch: branch)
      end

      # Adds a new worktree to the repository.
      # @param [String] path The path where the worktree should be created.
      # @param [String] branch The branch that should be checked out in the
      #   working tree. If no branch is provided the current HEAD will be
      #   checked out in a new branch.
      # @return [Git::Worktree] The object representing the newly created
      #   worktree.
      # @raise [JayAPI::Git::Errors::InvalidRepositoryError] If the repository
      #   is not a valid repository (it hasn't been initialized: cloned or
      #   open).
      # @raise [Git::GitExecuteError] If the worktree cannot be created.
      def add_worktree!(path:, branch: nil)
        raise JayAPI::Git::Errors::InvalidRepositoryError unless repository

        repository.worktree(path, branch).add
        repository.worktree(path)
      end

      # Returns the collection of worktrees linked to the repository.
      # @return [Git::Worktrees] The collection of worktrees linked to the
      #   repository.
      # @raise [ArgumentError] If the Repository cannot be opened.
      # @raise [Git::GitExecuteError] If the repository cannot be cloned.
      # @raise [JayAPI::Git::Errors::MissingURLError] If the repository doesn't
      #   exist yet and no repository URL was provided for the cloning.
      def worktrees
        open_or_clone
        worktrees!
      end

      # Returns the collection of worktrees linked to the repository.
      # @return [Git::Worktrees] The collection of worktrees linked to the
      #   repository.
      # @raise [JayAPI::Git::Errors::InvalidRepositoryError] If the repository
      #   is not a valid repository (it hasn't been initialized: cloned or
      #   open).
      def worktrees!
        raise JayAPI::Git::Errors::InvalidRepositoryError unless repository

        repository.worktrees
      end

      # Opens the repository if it is valid or clones it if it isn't
      # @return [JayAPI::Git::Repository] Self.
      # @raise [ArgumentError] If the Repository doesn't exist.
      # @raise [Git::GitExecuteError] If the repository cannot be cloned.
      # @raise [JayAPI::Git::Errors::MissingURLError] If the repository doesn't
      #   exist yet and no repository URL was provided for the cloning.
      def open_or_clone!
        open_or_clone
        self
      end

      private

      attr_reader :repository, :logger

      # Opens the repository if it is valid or clones it if it isn't
      # @raise [ArgumentError] If the Repository doesn't exist.
      # @raise [Git::GitExecuteError] If the repository cannot be cloned.
      # @raise [JayAPI::Git::Errors::MissingURLError] If the repository doesn't
      #   exist yet and no repository URL was provided for the cloning.
      def open_or_clone
        return if repository

        valid? ? open_repo : clone!
      end

      # Opens the repository and returns the Git::Base object
      # @return [Git::Base] The Git::Base object representing the repository.
      # @raise [ArgumentError] If the Repository doesn't exist.
      def open_repo
        @repository = ::Git.open(clone_path.to_s, log: logger)
      end

      # Clones the repository and returns the Git::Base object
      # @return [Git::Base] The Git::Base object representing the repository.
      # @raise [Git::GitExecuteError] If the repository cannot be cloned.
      # @raise [JayAPI::Git::Errors::MissingURLError] If no repository URL was
      #   provided.
      def clone_repo
        raise JayAPI::Git::Errors::MissingURLError, 'A repository URL is required to perform this operation' unless url

        # name needs to be passed as an empty string, otherwise the Git gem will
        # add it again at the end of the path, and we want the repository to be
        # cloned exactly in the path that we have designated.
        @repository = ::Git.clone(url, '', path: clone_path.to_s, log: logger)
      end

      def git_dir
        @git_dir ||= clone_path.join('.git')
      end

      # Derives a directory name from the Repository URL, for example:
      #
      #   git://git.local/tools/jay/jay_api.git -> jay_api
      #
      # @return [String] A directory name
      def directory_from_url
        path = URI.parse(url).path
        File.basename(path).sub('.git', '')
      end
    end
  end
end
