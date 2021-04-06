# frozen_string_literal: true

require "active_support/core_ext/integer/time"
require "sequel/plugins/soft_deletes"
require "sequel"
require "sqlite3"

RSpec.describe Sequel::Plugins::SoftDeletes, :db do
  before(:each) do
    @db = Sequel.sqlite
  end
  after(:each) do
    @db.disconnect
  end

  let(:table_name) { :soft_deletes_test }

  it "sets the soft-delete column to :soft_deleted_at if none is specified" do
    @db.create_table(:soft_deletes_test) do
      primary_key :id
      time :deleted_at
    end
    mc = Class.new(Sequel::Model(@db[:soft_deletes_test]))
    mc.plugin(:soft_deletes)
    expect(mc.soft_delete_column).to eq(:soft_deleted_at)
  end

  it "allows the class to override the soft-delete column" do
    @db.create_table(:soft_deletes_test) do
      primary_key :id
      time :deleted_at
    end
    mc = Class.new(Sequel::Model(@db[:soft_deletes_test]))
    mc.plugin(:soft_deletes, column: :deleted_at)
    expect(mc.soft_delete_column).to eq(:deleted_at)
  end

  it "defines a #soft_delete method on extended model instances" do
    @db.create_table(:soft_deletes_test) do
      primary_key :id
      time :deleted_at
    end
    mc = Class.new(Sequel::Model(@db[:soft_deletes_test]))
    mc.plugin(:soft_deletes)
    @m = mc.new

    expect(@m).to respond_to(:soft_delete)
  end

  context "extended model classes with a timestamp soft-delete column" do
    before do
      @db.create_table(:soft_deletes_test) do
        primary_key :id
        time :deleted_at
      end
      @c = Class.new(Sequel::Model(@db[:soft_deletes_test]))
      @c.plugin(:soft_deletes, column: :deleted_at)
      @m = @c.create
    end

    it "sets its column to 'now' when soft-deleted" do
      @m.soft_delete
      expect(@m.deleted_at).to be_a(Time)
      expect(@m.deleted_at).to be_within(5.seconds).of(Time.now)
    end

    it "sets up a subset for selecting (or de-selecting) soft-deleted rows" do
      expect(@c.dataset.soft_deleted).to be_a(Sequel::Dataset)
      expect(@c.dataset.not_soft_deleted).to be_a(Sequel::Dataset)

      expect(@c.dataset.soft_deleted.all).not_to include(@m)
      expect(@c.dataset.not_soft_deleted.all).to include(@m)

      @m.soft_delete
      expect(@c.dataset.soft_deleted.all).to include(@m)
      expect(@c.dataset.not_soft_deleted.all).not_to include(@m)
    end
  end

  context "extended model classes with a 'before' soft-delete hook" do
    before do
      @db.create_table(:soft_deletes_test) do
        primary_key :id
        time :deleted_at
      end
      mc = Class.new(Sequel::Model(@db[:soft_deletes_test]))
      mc.class_eval do
        attr_accessor :hook_body

        def before_soft_delete
          self.hook_body.call
        end
      end
      mc.plugin(:soft_deletes, column: :deleted_at)
      @m = mc.new
    end

    it "has its hook called whenever an instance is soft-deleted" do
      called = false
      @m.hook_body = lambda do
        called = true
      end
      @m.soft_delete

      expect(@m).to be_is_soft_deleted
      expect(called).to eq(true)
    end

    it "is not soft-deleted if its hook returns false" do
      @m.hook_body = lambda do
        false
      end

      expect do
        @m.soft_delete
      end.to raise_error(Sequel::HookFailed, /before_soft_delete hook failed/i)

      expect(@m).not_to be_soft_deleted
    end
  end

  context "extended model classes with an 'after' soft-delete hook" do
    before do
      @db.create_table(:soft_deletes_test) do
        primary_key :id
        time :deleted_at
      end
      mc = Class.new(Sequel::Model(@db[:soft_deletes_test]))
      mc.class_eval do
        attr_accessor :hook_body

        def after_soft_delete
          self.hook_body.call
        end
      end
      mc.plugin(:soft_deletes, column: :deleted_at)
      @m = mc.new
    end

    it "has its hook called whenever an instance is soft-deleted" do
      called = false
      @m.hook_body = lambda do
        called = true
      end
      @m.soft_delete

      expect(@m).to be_is_soft_deleted
      expect(called).to eq(true)
    end

    it "is still soft-deleted even if its hook returns false" do
      @m.hook_body = lambda do
        false
      end

      expect { @m.soft_delete }.not_to raise_error

      expect(@m).to be_is_soft_deleted
    end
  end

  context "extended model classes with an 'around' soft-delete hook" do
    before do
      @db.create_table(:soft_deletes_test) do
        primary_key :id
        time :deleted_at
      end
      mc = Class.new(Sequel::Model(@db[:soft_deletes_test]))
      mc.class_eval do
        attr_accessor :hook_body

        def around_soft_delete
          super if self.hook_body.call
        end
      end
      mc.plugin(:soft_deletes, column: :deleted_at)
      @m = mc.new
    end

    it "has its hook called whenever an instance is soft-deleted" do
      called = false
      @m.hook_body = lambda do
        called = true
      end
      @m.soft_delete
      expect(@m).to be_is_soft_deleted
      expect(called).to eq(true)
    end

    it "is not soft-deleted if its hook doesn't super" do
      @m.hook_body = lambda do
        false
      end

      expect do
        @m.soft_delete
      end.to raise_error(Sequel::HookFailed, /around_soft_delete hook failed/i)

      expect(@m).not_to be_soft_deleted
    end
  end

  context "extended model classes with deletion blockers" do
    before do
      @db.create_table(:soft_deletes_test) do
        primary_key :id
        time :deleted_at
      end
      mc = Class.new(Sequel::Model(@db[:soft_deletes_test]))
      mc.class_eval do
        attr_reader :stub_soft_deletion_blockers

        def initialize(*)
          @stub_soft_deletion_blockers = []
          super
        end

        def soft_deletion_blockers
          return self.stub_soft_deletion_blockers
        end
      end
      mc.plugin(:soft_deletes, column: :deleted_at)
      @m = mc.new
    end

    it "is not soft-deleted if it has deletion blockers" do
      @m.stub_soft_deletion_blockers << "A BLOCKER"

      expect do
        @m.soft_delete
      end.to raise_error(Sequel::HookFailed, /before_soft_delete hook failed/i)

      expect(@m).not_to be_soft_deleted
    end

    it "raises an error if remove_soft_deletion_blockers hasn't been implemented" do
      expect do
        @m.remove_soft_deletion_blockers
      end.to raise_error(NotImplementedError)
    end
  end
end
