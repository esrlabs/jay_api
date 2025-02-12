# frozen_string_literal: true

require 'jay_api/git/repository'

# rubocop:disable RSpec/ContextWording (not suitable for shared contexts)
RSpec.shared_context 'JayAPI::Git::Repository with a mocked pathname' do
  let(:parent_directory) do
    instance_double(
      Pathname,
      mkpath: true
    )
  end

  let(:mocked_pathname) do
    instance_double(
      Pathname,
      absolute?: true,
      directory?: true,
      dirname: parent_directory,
      exist?: true,
      rmtree: true,
      to_s: clone_path
    )
  end

  let(:mocked_git_dir) do
    instance_double(
      Pathname,
      directory?: true,
      exist?: true
    )
  end

  before do
    allow(Pathname).to receive(:new).and_return(mocked_pathname)
    allow(mocked_pathname).to receive(:join).with('.git').and_return(mocked_git_dir)
  end
end

RSpec.shared_context 'JayAPI::Git::Repository with an initialized repository' do
  include_context 'JayAPI::Git::Repository with a mocked pathname'

  let(:mocked_git) do
    instance_double(
      Git::Base
    )
  end

  before do
    allow(Git).to receive(:clone).and_return(mocked_git)
    repository.clone!
  end
end

# rubocop:enable RSpec/ContextWording

RSpec.shared_examples_for 'JayAPI::Git::Repository#clone!' do
  include_context 'JayAPI::Git::Repository with a mocked pathname'

  let(:mocked_git) do
    instance_double(
      Git::Base
    )
  end

  before do
    allow(Git).to receive(:clone).and_return(mocked_git)
  end

  it 'returns itself' do
    expect(method_call).to eq(repository)
  end

  it 'creates the containing directory' do
    expect(parent_directory).to receive(:mkpath)
    method_call
  end

  it 'clones the repository in the specified path' do
    expect(Git).to receive(:clone).with(url, '', path: clone_path, log: mocked_logger)
    method_call
  end

  context 'when the clone_path already exists' do
    it 'deletes it' do
      expect(mocked_pathname).to receive(:rmtree)
      method_call
    end
  end

  context 'when no repository URL has been given' do
    let(:url) { nil }

    it 'raises a JayAPI::Git::Errors::MissingURLError' do
      expect { method_call }.to raise_error(
        JayAPI::Git::Errors::MissingURLError,
        'A repository URL is required to perform this operation'
      )
    end
  end
end

RSpec.shared_examples_for 'JayAPI::Git::Repository#update!' do
  include_context 'JayAPI::Git::Repository with a mocked pathname'

  let(:remotes) do
    [
      instance_double(Git::Remote, name: 'origin'),
      instance_double(Git::Remote, name: 'upstream')
    ]
  end

  let(:mocked_git) do
    instance_double(
      Git::Base,
      current_branch: 'master',
      fetch: true,
      pull: true,
      remotes: remotes
    )
  end

  before do
    allow(Git).to receive(:open).and_return(mocked_git)
  end

  it 'returns self' do
    expect(method_call).to eq(repository)
  end

  context "when the repository directory doesn't exist" do
    before do
      allow(Git).to receive(:open).and_raise(ArgumentError)
    end

    it 'raises an ArgumentError' do
      expect { method_call }.to raise_error(ArgumentError)
    end
  end

  it 'opens the repository' do
    expect(Git).to receive(:open).with(clone_path, log: mocked_logger)
    method_call
  end

  context 'when the repository is not a valid git repository' do
    before do
      allow(mocked_git).to receive(:fetch).and_raise(Git::GitExecuteError)
    end

    it 'raises a Git::GitExecuteError' do
      expect { method_call }.to raise_error(Git::GitExecuteError)
    end
  end

  it 'fetches the changes from the default remote' do
    expect(mocked_git).to receive(:fetch).with('origin')
    method_call
  end

  it 'pulls the changes on the current branch from the default remote' do
    expect(mocked_git).to receive(:pull).with('origin', 'master')
    method_call
  end
end

RSpec.shared_examples_for 'JayAPI::Git::Repository#checkout!' do
  it 'checks out to the specified commit' do
    expect(mocked_git).to receive(:checkout).with(commit_hash)
    method_call
  end
end

RSpec.shared_examples_for 'JayAPI::Git::Repository#object!' do
  context 'when the given reference is invalid' do
    before do
      allow(mocked_git).to receive(:object)
        .with(objectish).and_raise(Git::GitExecuteError)
    end

    it 'raises a Git::GitExecuteError' do
      expect { method_call }.to raise_error(Git::GitExecuteError)
    end
  end

  context 'when the given reference is valid' do
    let(:mocked_commit) do
      instance_double(Git::Object::Commit)
    end

    before do
      allow(mocked_git).to receive(:object)
        .with(objectish).and_return(mocked_commit)
    end

    it 'returns the Git::Object::Commit object' do
      expect(method_call).to eq(mocked_commit)
    end
  end
end

RSpec.shared_examples_for 'JayAPI::Git::Repository#open_or_clone' do |inner_behaviour|
  context 'when the repository is not yet initialized' do
    context "when the repository seems to be valid but it's not" do
      before do
        allow(Git).to receive(:open).and_raise(Git::GitExecuteError)
      end

      it 'raises a Git::GitExecuteError' do
        expect { method_call }.to raise_error(Git::GitExecuteError)
      end
    end

    context 'when the repository is valid' do
      before do
        allow(Git).to receive(:open).and_return(mocked_git)
      end

      it 'opens the repository' do
        expect(Git).to receive(:open)
          .with(clone_path, log: mocked_logger).and_return(mocked_git)

        method_call
      end

      it_behaves_like inner_behaviour if inner_behaviour
    end

    context 'when the repository is not valid' do
      before do
        allow(mocked_pathname).to receive(:exist?).and_return(false)

        allow(Git).to receive(:clone)
          .with(url, '', path: clone_path, log: mocked_logger).and_return(mocked_git)
      end

      context 'when the cloning fails' do
        before do
          allow(Git).to receive(:clone).and_raise(Git::GitExecuteError)
        end

        it 'raises a Git::GitExecuteError' do
          expect { method_call }.to raise_error(Git::GitExecuteError)
        end
      end

      context 'when no repository URL has been given' do
        let(:url) { nil }

        it 'raises a JayAPI::Git::Errors::MissingURLError' do
          expect { method_call }.to raise_error(
            JayAPI::Git::Errors::MissingURLError,
            'A repository URL is required to perform this operation'
          )
        end
      end

      it 'clones the repository' do
        expect(Git).to receive(:clone)
          .with(url, '', path: clone_path, log: mocked_logger).and_return(mocked_git)

        method_call
      end

      it_behaves_like inner_behaviour if inner_behaviour
    end
  end
end

RSpec.shared_examples_for 'JayAPI::Git::Repository#branches!' do
  before do
    allow(mocked_git).to receive(:branches).and_return(mocked_branches)
  end

  it 'returns the Git::Branches object' do
    expect(method_call).to eq(mocked_branches)
  end
end

RSpec.shared_examples_for 'JayAPI::Git::Repository#remotes!' do
  let(:remotes) do
    [
      instance_double(
        Git::Remote
      ),
      instance_double(
        Git::Remote
      )
    ]
  end

  before do
    allow(mocked_git).to receive(:remotes).and_return(remotes)
  end

  it 'returns an array of Git::Remote objects' do
    expect(method_call).to eq(remotes)
  end
end

RSpec.shared_examples_for 'JayAPI::Git::Repository#log!' do
  let(:mocked_log) { instance_double(Git::Log) }

  context 'with an objectish' do
    let(:mocked_blob) { instance_double(Git::Object::Blob) }
    let(:objectish) { 'feature-branch' }

    before do
      allow(mocked_git).to receive(:gblob).with(objectish).and_return(mocked_blob)
      allow(mocked_blob).to receive(:log).with(count).and_return(mocked_log)
    end

    it 'uses the gblob method to constraint the search then calls the log method' do
      expect(mocked_git).to receive(:gblob).with(objectish)
      expect(mocked_blob).to receive(:log).with(count)
      method_call
    end

    it 'returns the Git::Log object for the given reference' do
      expect(method_call).to eq(mocked_log)
    end
  end

  context 'without an objectish' do
    before do
      allow(mocked_git).to receive(:log).with(count).and_return(mocked_log)
    end

    it 'calls log on the git repository with the expected count value' do
      expect(mocked_git).to receive(:log).with(count)
      method_call
    end

    it 'returns the Git::Log object' do
      expect(method_call).to eq(mocked_log)
    end
  end
end

RSpec.shared_examples_for 'JayAPI::Git::Repository#add_worktree!' do
  let(:mocked_worktree) do
    instance_double(
      Git::Worktree
    )
  end

  before do
    allow(mocked_git).to receive(:worktree).with(path, branch).and_return(mocked_worktree)
    allow(mocked_git).to receive(:worktree).with(path).and_return(mocked_worktree)
    allow(mocked_worktree).to receive(:add).and_return(true)
  end

  it 'adds a new worktree' do
    expect(mocked_git).to receive(:worktree).with(path, branch)
    expect(mocked_worktree).to receive(:add)
    method_call
  end

  context 'when the worktree cannot be created' do
    before do
      allow(mocked_git).to receive(:worktree).with(path, branch).and_raise(Git::GitExecuteError)
    end

    it 'raises a Git::GitExecuteError' do
      expect { method_call }.to raise_error(Git::GitExecuteError)
    end
  end

  it 'returns the newly created worktree' do
    expect(method_call).to eq(mocked_worktree)
  end
end

RSpec.shared_examples_for 'JayAPI::Git::Repository#worktrees!' do
  let(:mocked_worktrees) { instance_double(Git::Worktrees) }

  before do
    allow(mocked_git).to receive(:worktrees).and_return(mocked_worktrees)
  end

  it 'calls worktrees on the git repository' do
    expect(mocked_git).to receive(:worktrees)
    method_call
  end

  it 'returns the Worktrees object' do
    expect(method_call).to eq(mocked_worktrees)
  end
end

RSpec.shared_examples 'JayAPI::Git::Repository raises a JayAPI::Git::Errors::InvalidRepositoryError' do
  it 'raises a JayAPI::Git::Errors::InvalidRepositoryError' do
    expect { method_call }
      .to raise_error(JayAPI::Git::Errors::InvalidRepositoryError)
  end
end

RSpec.describe JayAPI::Git::Repository do
  subject(:repository) do
    described_class.new(url: url, clone_path: clone_path, clone_location: clone_location, logger: logger)
  end

  let(:url) { 'ssh://gerrit.local:29418/tools/jay/jay_api' }
  let(:clone_path) { '/Workspace/jay_api' }
  let(:clone_location) { nil }

  # rubocop:disable RSpec/VerifiedDoubles (Cannot be used with logger because of meta-programming)
  let(:mocked_logger) do
    double(
      Logging::Logger,
      info: true
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  let(:logger) { mocked_logger }

  shared_examples_for '#open_or_clone! when it is returning self' do
    it 'returns self' do
      expect(method_call).to be repository
    end
  end

  describe '#open_or_clone!' do
    subject(:method_call) { repository.open_or_clone! }

    include_context 'JayAPI::Git::Repository with a mocked pathname'

    let(:mocked_git) do
      instance_double(
        Git::Base
      )
    end

    it_behaves_like 'JayAPI::Git::Repository#open_or_clone', '#open_or_clone! when it is returning self'
  end

  describe '#initialize' do
    let(:pwd) { Pathname.new('/Workspace') }

    before do
      allow(Pathname).to receive(:pwd).and_return(pwd)
    end

    context 'when neither clone_location nor clone_path are given' do
      let(:clone_path) { nil }

      it 'raises an ArgumentError' do
        expect { repository }.to raise_error(ArgumentError, 'Either clone_location or clone_path must be given')
      end
    end

    context 'when neither url nor clone_path are given' do
      let(:clone_location) { '/Workspace/repos' }
      let(:clone_path) { nil }
      let(:url) { nil }

      it 'raises an ArgumentError' do
        expect { repository }.to raise_error(ArgumentError, 'Either clone_path or url must be given')
      end
    end

    context 'when no logger is given' do
      let(:logger) { nil }

      it 'creates a new logger for the class' do
        expect(Logging.logger).to receive(:[]).with(described_class)
        repository
      end
    end

    context 'when a logger is given' do
      it 'does not create a new logger for the class' do
        expect(Logging.logger).not_to receive(:[])
        repository
      end
    end

    context 'when a clone_path is given' do
      context 'when the given clone_path is absolute' do
        it 'creates a Pathname out of the given clone_path' do
          expect(repository.clone_path).to be_a(Pathname)
          expect(repository.clone_path.to_s).to eq(clone_path)
        end
      end

      context 'when the given clone_path is relative' do
        let(:clone_path) { 'jay_api' }

        it 'creates an absolute pathname out of it by appending the clone_path to the current working directory' do
          expect(repository.clone_path).to be_absolute
          expect(repository.clone_path.to_s).to eq("#{pwd}/#{clone_path}")
        end
      end

      it 'constructs the clone_location from the given clone_path' do
        expect(repository.clone_location).to be_a(Pathname)
        expect(repository.clone_location.to_s).to eq('/Workspace')
      end
    end

    context 'when clone_location is given' do
      let(:clone_location) { '/Workspace/repos' }

      context 'when clone_path is given as well' do
        it 'ignores the given clone_location and uses the clone_path instead' do
          expect(repository.clone_path.to_s).to eq(clone_path)
        end

        it 'constructs the clone_location out of the built clone_path' do
          expect(repository.clone_location).to be_a(Pathname)
          expect(repository.clone_location.to_s).to eq('/Workspace')
        end
      end

      context 'when clone_path is not given' do
        let(:clone_path) { nil }

        context 'when the clone_location is absolute' do
          it 'creates a clone_path by appending the repository name to the clone_location' do
            expect(repository.clone_path.to_s).to eq("#{clone_location}/jay_api")
          end

          it 'constructs the clone_location out of the built clone_path' do
            expect(repository.clone_location).to be_a(Pathname)
            expect(repository.clone_location.to_s).to eq(clone_location)
          end
        end

        context 'when the clone_location is relative' do
          let(:clone_location) { 'tools' }

          it 'creates a clone_path with the current working directory, the clone_path and the repository name' do
            expect(repository.clone_path.to_s).to eq "#{pwd}/#{clone_location}/jay_api"
            expect(repository.clone_path).to be_absolute
          end

          it 'constructs the clone_location out of the built clone_path' do
            expect(repository.clone_location).to be_a(Pathname)
            expect(repository.clone_location.to_s).to eq("#{pwd}/#{clone_location}")
          end
        end
      end
    end
  end

  describe '#exist?' do
    include_context 'JayAPI::Git::Repository with a mocked pathname'

    context 'when the clone_path exists' do
      before do
        allow(mocked_pathname).to receive(:exist?).and_return(true)
      end

      it 'returns true' do
        expect(repository.exist?).to be true
      end
    end

    context "when the clone_path doesn't exist" do
      before do
        allow(mocked_pathname).to receive(:exist?).and_return(false)
      end

      it 'return false' do
        expect(repository.exist?).to be false
      end
    end
  end

  describe '#valid?' do
    include_context 'JayAPI::Git::Repository with a mocked pathname'

    context 'when the clone_path does not exist' do
      before do
        allow(mocked_pathname).to receive(:exist?).and_return(false)
      end

      it 'returns false' do
        expect(repository.valid?).to be false
      end
    end

    context 'when the clone_path is not a directory' do
      before do
        allow(mocked_pathname).to receive(:directory?).and_return(false)
      end

      it 'returns false' do
        expect(repository.valid?).to be false
      end
    end

    context "when the clone_path doesn't have a git directory inside" do
      before do
        allow(mocked_git_dir).to receive(:exist?).and_return(false)
      end

      it 'return false' do
        expect(repository.valid?).to be false
      end
    end

    context 'when the .git file inside of the clone_path is not a directory' do
      before do
        allow(mocked_git_dir).to receive(:directory?).and_return(false)
      end

      it 'return false' do
        expect(repository.valid?).to be false
      end
    end

    context 'when both the clone_path and the .git directory exists and are directories' do
      it 'return true' do
        expect(repository.valid?).to be true
      end
    end
  end

  describe '#clone!' do
    subject(:method_call) { repository.clone! }

    it_behaves_like 'JayAPI::Git::Repository#clone!'
  end

  describe '#update!' do
    subject(:method_call) { repository.update! }

    it_behaves_like 'JayAPI::Git::Repository#update!'
  end

  describe '#clone' do
    subject(:method_call) { repository.clone }

    context 'when the clone_path is a valid git repository' do
      it_behaves_like 'JayAPI::Git::Repository#update!'
    end

    context 'when the clone_path is not a valid git repository' do
      before do
        allow(mocked_pathname).to receive(:directory?).and_return(false)
      end

      it_behaves_like 'JayAPI::Git::Repository#clone!'
    end
  end

  describe '#update' do
    it 'is an alias for clone' do
      expect(described_class.methods(:update)).to eq(described_class.methods(:clone))
    end
  end

  describe '#checkout' do
    subject(:method_call) { repository.checkout(commit_hash) }

    include_context 'JayAPI::Git::Repository with a mocked pathname'

    let(:commit_hash) { 'c35a5c13' }
    let(:mocked_git) do
      instance_double(Git::Base)
    end

    before { allow(mocked_git).to receive(:checkout) }

    it_behaves_like 'JayAPI::Git::Repository#open_or_clone', 'JayAPI::Git::Repository#checkout!'
  end

  describe '#checkout!' do
    subject(:method_call) { repository.checkout!(commit_hash) }

    let(:commit_hash) { '75b1c325a7' }

    context 'when the repository is not yet initialized' do
      include_examples 'JayAPI::Git::Repository raises a JayAPI::Git::Errors::InvalidRepositoryError'
    end

    context 'when the repository is already initialized' do
      include_context 'JayAPI::Git::Repository with an initialized repository'
      it_behaves_like 'JayAPI::Git::Repository#checkout!'
    end
  end

  describe '#name' do
    context 'when no repository URL has been given' do
      it 'extracts the name from the clone path' do
        expect(repository.name).to eq('jay_api')
      end
    end

    context "when the repository URL doesn't end in .git" do
      it 'returns the correct repository name' do
        expect(repository.name).to eq('jay_api')
      end
    end

    context 'when the repository URL ends in .git' do
      let(:url) { 'ssh://gerrit.local:29418/tools/jay/jay_api.git' }

      it 'returns the correct repository name' do
        expect(repository.name).to eq('jay_api')
      end
    end
  end

  describe '#object!' do
    subject(:method_call) { repository.object!(objectish) }

    let(:objectish) { '75b1c325a7' }

    context 'when the repository is not yet initialized' do
      include_examples 'JayAPI::Git::Repository raises a JayAPI::Git::Errors::InvalidRepositoryError'
    end

    context 'when the repository is already initialized' do
      include_context 'JayAPI::Git::Repository with an initialized repository'
      it_behaves_like 'JayAPI::Git::Repository#object!'
    end
  end

  describe '#object' do
    subject(:method_call) { repository.object(objectish) }

    include_context 'JayAPI::Git::Repository with a mocked pathname'

    let(:mocked_commit) do
      instance_double(Git::Object::Commit)
    end

    let(:mocked_git) do
      instance_double(
        Git::Base,
        object: mocked_commit
      )
    end

    let(:objectish) { '7000f1172b' }

    it_behaves_like 'JayAPI::Git::Repository#open_or_clone', 'JayAPI::Git::Repository#object!'
  end

  describe '#branches!' do
    subject(:method_call) { repository.branches! }

    context 'when the repository is not yet initialized' do
      include_examples 'JayAPI::Git::Repository raises a JayAPI::Git::Errors::InvalidRepositoryError'
    end

    context 'when the repository has already been initialized' do
      include_context 'JayAPI::Git::Repository with an initialized repository'

      let(:mocked_branches) do
        instance_double(
          Git::Branches
        )
      end

      it_behaves_like 'JayAPI::Git::Repository#branches!'
    end
  end

  describe '#branches' do
    subject(:method_call) { repository.branches }

    include_context 'JayAPI::Git::Repository with a mocked pathname'

    let(:mocked_branches) do
      instance_double(
        Git::Branches
      )
    end

    let(:mocked_git) do
      instance_double(
        Git::Base,
        branches: mocked_branches
      )
    end

    it_behaves_like 'JayAPI::Git::Repository#open_or_clone', 'JayAPI::Git::Repository#branches!'
  end

  describe '#remotes' do
    subject(:method_call) { repository.remotes }

    include_context 'JayAPI::Git::Repository with a mocked pathname'

    let(:mocked_git) do
      instance_double(
        Git::Base,
        remotes: []
      )
    end

    it_behaves_like 'JayAPI::Git::Repository#open_or_clone', 'JayAPI::Git::Repository#remotes!'
  end

  describe '#remotes!' do
    subject(:method_call) { repository.remotes! }

    context 'when the repository is not yet initialized' do
      include_examples 'JayAPI::Git::Repository raises a JayAPI::Git::Errors::InvalidRepositoryError'
    end

    context 'when the repository has already been initialized' do
      include_context 'JayAPI::Git::Repository with an initialized repository'

      it_behaves_like 'JayAPI::Git::Repository#remotes!'
    end
  end

  describe '#log!' do
    subject(:method_call) { repository.log!(objectish: objectish, count: count) }

    let(:objectish) { nil }

    let(:count) do
      count = rand(0..10)
      count.positive? ? count : nil
    end

    context 'when the repository is not yet initialized' do
      include_examples 'JayAPI::Git::Repository raises a JayAPI::Git::Errors::InvalidRepositoryError'
    end

    context 'when the repository has already been initialized' do
      include_context 'JayAPI::Git::Repository with an initialized repository'
      it_behaves_like 'JayAPI::Git::Repository#log!'
    end
  end

  describe '#log' do
    subject(:method_call) { repository.log(objectish: objectish, count: count) }

    include_context 'JayAPI::Git::Repository with a mocked pathname'

    let(:objectish) { nil }

    let(:count) do
      count = rand(0..10)
      count.positive? ? count : nil
    end

    let(:mocked_log) { instance_double(Git::Log) }

    let(:mocked_git) do
      instance_double(
        Git::Base,
        log: mocked_log
      )
    end

    it_behaves_like 'JayAPI::Git::Repository#open_or_clone', 'JayAPI::Git::Repository#log!'
  end

  describe '#add_worktree!' do
    subject(:method_call) { repository.add_worktree!(path: path, branch: branch) }

    let(:path) { '/tmp/worktree' }
    let(:branch) { 'feature-branch' }

    context 'when the repository is not yet initialized' do
      include_examples 'JayAPI::Git::Repository raises a JayAPI::Git::Errors::InvalidRepositoryError'
    end

    context 'when the repository has already been initialized' do
      include_context 'JayAPI::Git::Repository with an initialized repository'
      it_behaves_like 'JayAPI::Git::Repository#add_worktree!'
    end
  end

  describe '#add_worktree' do
    subject(:method_call) { repository.add_worktree(path: path, branch: branch) }

    include_context 'JayAPI::Git::Repository with a mocked pathname'

    let(:path) { '/tmp/worktree' }
    let(:branch) { nil }

    let(:mocked_worktree) do
      instance_double(
        Git::Worktree,
        add: true
      )
    end

    let(:mocked_git) do
      instance_double(
        Git::Base,
        worktree: mocked_worktree
      )
    end

    it_behaves_like 'JayAPI::Git::Repository#open_or_clone', 'JayAPI::Git::Repository#add_worktree!'
  end

  describe '#worktrees!' do
    subject(:method_call) { repository.worktrees! }

    context 'when the repository is not yet initialized' do
      include_examples 'JayAPI::Git::Repository raises a JayAPI::Git::Errors::InvalidRepositoryError'
    end

    context 'when the repository has already been initialized' do
      include_context 'JayAPI::Git::Repository with an initialized repository'
      it_behaves_like 'JayAPI::Git::Repository#worktrees!'
    end
  end

  describe '#worktrees' do
    subject(:method_call) { repository.worktrees }

    include_context 'JayAPI::Git::Repository with a mocked pathname'

    let(:mocked_worktrees) { instance_double(Git::Worktree) }

    let(:mocked_git) do
      instance_double(
        Git::Base,
        worktrees: mocked_worktrees
      )
    end

    it_behaves_like 'JayAPI::Git::Repository#open_or_clone', 'JayAPI::Git::Repository#worktrees!'
  end

  describe '#remote_url' do
    subject(:method_call) { repository.remote_url }

    include_context 'JayAPI::Git::Repository with an initialized repository'

    let(:remote_url) { 'www.gerrit.com' }
    let(:remote_object) { instance_double(Git::Remote, url: remote_url) }
    let(:remotes) { [remote_object] }

    let(:mocked_git) do
      instance_double(
        Git::Base,
        remotes: remotes
      )
    end

    context 'when a remote object exist' do
      it 'returns the remote URL' do
        expect(method_call).to eq(remote_url)
      end
    end

    context 'when a remote object does not exist' do
      let(:remotes) { [] }

      it 'returns nil' do
        expect(method_call).to be_nil
      end
    end
  end
end
