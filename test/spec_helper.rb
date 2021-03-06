# Copyright (c) 2016 SUSE LLC.
#  All Rights Reserved.

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 2 or 3 of the GNU General
#  Public License as published by the Free Software Foundation.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.

#  To contact Novell about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

# Set the paths
SRC_PATH = File.expand_path("../../src", __FILE__)
DATA_PATH = File.expand_path("../data", __FILE__)
TEST_PATH = File.expand_path("..", __FILE__)
ENV["Y2DIR"] = SRC_PATH

# make sure we run the tests in English locale
# (some tests check the output which is marked for translation)
ENV["LC_ALL"] = "en_US.UTF-8"

LIBS_TO_SKIP = ["y2packager/repository"]

# Hack to avoid to require some files
#
# This is here to avoid a cyclic dependency with yast-installation at build time.
# Storage-ng does not include a BuildRequires for yast-installation, so the require
# for files defined by that package must be avoided.
module Kernel
  alias_method :old_require, :require

  def require(path)
    old_require(path) unless LIBS_TO_SKIP.include?(path)
  end
end

require "yast"
require "yast/rspec"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
  end

  # track all ruby files under src
  SimpleCov.track_files("#{SRC_PATH}/lib/**/*.rb")

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
end

require_relative "support/storage_helpers"

RSpec.configure do |c|
  c.include Yast::RSpec::StorageHelpers

  # Y2Packager is not loaded in tests to avoid cyclic dependencies with
  # yast-installation package at build time. Here, all usage of Y2Packager
  # is mocked.
  c.before do
    stub_const("Y2Packager::Repository", double("Y2Packager::Repository"))
    allow(Y2Packager::Repository).to receive(:all).and_return([])
  end

  # Some tests use ProposalSettings#new_for_current_product to initialize
  # the settings. That method sets some default values when there is not
  # imported features (i.e., when control.xml is not found).
  #
  # The product features could be modified during testing. Due to there are
  # tests reling on settings with pristine default values, it is necessary to
  # reset the product features to not interfer in the results.
  c.after(:all) do
    Yast::ProductFeatures.Import({})
  end
end
