# encoding: utf-8

# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "y2storage/autoinst_issues/issue"

module Y2Storage
  module AutoinstIssues
    # There is no enough disk space to build the storage proposal
    class CouldNotCreateBoot < Issue
      def initialize(*args)
        super
        textdomain "storage"
      end

      # Fatal problem
      #
      # @return [Symbol] :warn
      # @see Issue#severity
      def severity
        :warn
      end

      # Return the error message to be displayed
      #
      # FIXME: we could add the list of boot devices that are required.
      #
      # @return [String] Error message
      # @see Issue#message
      def message
        _("Not possible to add a boot partition. Your system might not boot properly.")
      end
    end
  end
end
