# frozen_string_literal: true

require "sequel/plugins/soft-deletes"
require "sequel"

RSpec.describe Sequel::Plugins::SoftDeletes, :db do
  let(:table_name) { :soft_deletes_test }

  # before(:all) do
  #   @db = Sequel.mock
  #   @c = Class.new(Sequel::Model(@db)) do
  #     set_columns([:primary_key, :deleted_at])
  #   end
  #   @c.class_eval do
  #     attr_accessor :hook_body
  #
  #     def before_soft_delete
  #       self.hook_body.call
  #     end
  #   end
  #   ds = @db.dataset.with_extend do
  #     def columns
  #       [:primary_key, :deleted_at]
  #     end
  #   end
  #   @c.dataset = ds
  #   @c.plugin(:soft_deletes, column: :deleted_at)
  #   @m = @c.new
  # end

  it "sets the soft-delete column to :soft_deleted_at if none is specified" do
    @db = Sequel.mock
    @c = Class.new(Sequel::Model(@db)) do
      set_columns([:primary_key, :deleted_at])
    end
    @c.plugin(:soft_deletes)
    expect(@c.soft_delete_column).to eq(:soft_deleted_at)
  end

  it "allows the class to override the soft-delete column" do
    @db = Sequel.mock
    @c = Class.new(Sequel::Model(@db)) do
      set_columns([:primary_key, :deleted_at])
    end
    @c.plugin(:soft_deletes, column: :deleted_at)
    expect(@c.soft_delete_column).to eq(:deleted_at)
  end

  it "defines a #soft_delete method on extended model instances" do
    @db = Sequel.mock
    @c = Class.new(Sequel::Model(@db)) do
      set_columns([:primary_key, :deleted_at])
    end
    @c.plugin(:soft_deletes)
    @m = @c.new

    expect(@m).to respond_to(:soft_delete)
  end

  context "extended model classes with a timestamp soft-delete column" do
    # let(:model_class) do
    #   mc = create_model(table_name) do
    #     primary_key :id
    #     timestamp :deleted_at
    #   end
    #   mc.plugin(:soft_deletes, column: :deleted_at)
    #   mc
    # end
    #
    before do
      @db = Sequel.mock
      @c = Class.new(Sequel::Model(@db)) do
        set_columns([:primary_key, :deleted_at])
      end
      @c.plugin(:soft_deletes, column: :deleted_at)
      ds = @db.dataset.with_extend do
        def columns
          [:primary_key, :deleted_at]
        end
      end
      @c.dataset = ds
      @m = @c.new
    end

    it "sets its column to 'now' when soft-deleted" do
      @c.all
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
    # let(:model_class) do
    #   mc = create_model(table_name) do
    #     primary_key :id
    #     timestamptz :deleted_at
    #   end
    #   mc.class_eval do
    #     attr_accessor :hook_body
    #
    #     def before_soft_delete
    #       self.hook_body.call
    #     end
    #   end
    #   mc.plugin(:soft_deletes, column: :deleted_at)
    #   mc
    # end
    #

    before do
      @db = Sequel.mock
      @c = Class.new(Sequel::Model(@db)) do
        set_columns([:primary_key, :deleted_at])
      end
      @c.class_eval do
        attr_accessor :hook_body

        def before_soft_delete
          self.hook_body.call
        end
      end
      ds = @db.dataset.with_extend do
        def columns
          [:primary_key, :deleted_at]
        end
      end
      @c.dataset = ds
      @c.plugin(:soft_deletes, column: :deleted_at)
      @m = @c.new
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
    # let(:model_class) do
    #   mc = create_model(table_name) do
    #     primary_key :id
    #     timestamptz :deleted_at
    #   end
    #   mc.class_eval do
    #     attr_accessor :hook_body
    #
    #     def after_soft_delete
    #       self.hook_body.call
    #     end
    #   end
    #   mc.plugin(:soft_deletes, column: :deleted_at)
    #   mc
    # end

    before do
      @db = Sequel.mock
      @c = Class.new(Sequel::Model(@db)) do
        set_columns([:primary_key, :deleted_at])
      end
      @c.class_eval do
        attr_accessor :hook_body

        def after_soft_delete
          self.hook_body.call
        end
      end
      ds = @db.dataset.with_extend do
        def columns
          [:primary_key, :deleted_at]
        end
      end
      @c.dataset = ds
      @c.plugin(:soft_deletes, column: :deleted_at)
      @m = @c.new
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
    # let(:model_class) do
    #   mc = create_model(table_name) do
    #     primary_key :id
    #     timestamptz :deleted_at
    #   end
    #   mc.class_eval do
    #     attr_accessor :hook_body
    #
    #     def around_soft_delete
    #       super if self.hook_body.call
    #     end
    #   end
    #   mc.plugin(:soft_deletes, column: :deleted_at)
    #   mc
    # end
    #
    before do
      @db = Sequel.mock
      @c = Class.new(Sequel::Model(@db)) do
        set_columns([:primary_key, :deleted_at])
      end
      @c.class_eval do
        attr_accessor :hook_body

        def around_soft_delete
          super if self.hook_body.call
        end
      end
      ds = @db.dataset.with_extend do
        def columns
          [:primary_key, :deleted_at]
        end
      end
      @c.dataset = ds
      @c.plugin(:soft_deletes, column: :deleted_at)
      @m = @c.new
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
    # let(:model_class) do
    #   mc = create_model(table_name) do
    #     primary_key :id
    #     timestamptz :deleted_at
    #   end
    #   mc.class_eval do
    #     attr_reader :stub_soft_deletion_blockers
    #
    #     def initialize(*)
    #       @stub_soft_deletion_blockers = []
    #       super
    #     end
    #
    #     def soft_deletion_blockers
    #       return self.stub_soft_deletion_blockers
    #     end
    #   end
    #   mc.plugin(:soft_deletes, column: :deleted_at)
    #   mc
    # end

    before do
      @db = Sequel.mock
      @c = Class.new(Sequel::Model(@db)) do
        set_columns([:primary_key, :deleted_at])
      end
      @c.class_eval do
        attr_reader :stub_soft_deletion_blockers

        def initialize(*)
          @stub_soft_deletion_blockers = []
          super
        end

        def soft_deletion_blockers
          return self.stub_soft_deletion_blockers
        end
      end
      @c.plugin(:soft_deletes, column: :deleted_at)
      @m = @c.new
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
