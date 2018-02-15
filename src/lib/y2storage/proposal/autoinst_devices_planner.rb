# encoding: utf-8

# Copyright (c) [2017] SUSE LLC
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

require "y2storage/disk"
require "y2storage/proposal/autoinst_disk_planner"
require "y2storage/proposal/autoinst_vg_planner"
require "y2storage/proposal/autoinst_md_planner"

module Y2Storage
  module Proposal
    # Class to generate a list of Planned::Device objects that must be allocated
    # during the AutoYaST proposal.
    #
    # The list of planned devices is generated from the information that was
    # previously obtained from the AutoYaST profile. This is completely different
    # to the guided proposal equivalent ({DevicesPlanner}), which generates the
    # planned devices based on the proposal settings and its own logic.
    class AutoinstDevicesPlanner
      include Yast::Logger

      # Constructor
      #
      # @param devicegraph [Devicegraph] Devicegraph to be used as starting point
      # @param issues_list [AutoinstIssues::List] List of AutoYaST issues to register them
      def initialize(devicegraph, issues_list)
        @devicegraph = devicegraph
        @issues_list = issues_list
      end

      # Returns an array of planned devices according to the drives map
      #
      # @param drives_map [Proposal::AutoinstDrivesMap] Drives map from AutoYaST
      # @return [Array<Planned::Device>] List of planned devices
      def planned_devices(drives_map)
        result = []
        @default_subvolumes_used = false

        drives_map.each_pair do |disk_name, drive_section|
          case drive_section.type
          when :CT_DISK
            disk = BlkDevice.find_by_name(devicegraph, disk_name)
            result.concat(planned_for_disk(disk, drive_section))
          when :CT_LVM
            result << planned_for_vg(drive_section)
          when :CT_MD
            result << planned_for_md(drive_section)
          end
        end

        remove_shadowed_subvols(result)

        result
      end

    protected

      # @return [Devicegraph] Starting devicegraph
      attr_reader :devicegraph
      # @return [AutoinstIssues::List] List of AutoYaST issues to register them
      attr_reader :issues_list

      def planned_for_disk(disk, drive)
        AutoinstDiskPlanner.new(devicegraph, issues_list).planned_for_disk(disk, drive)
      end

      def planned_for_vg(drive)
        AutoinstVGPlanner.new(devicegraph, issues_list).planned_for_vg(drive)
      end

      def planned_for_md(drive)
        AutoinstMDPlanner.new(devicegraph, issues_list).planned_for_md(drive)
      end

      def remove_shadowed_subvols(planned_devices)
        planned_devices.each do |device|
          next unless device.respond_to?(:subvolumes)

          # FIXME
          subvols_added =
            device.respond_to?(:mount_point) && device.mount_point == "/" && @default_subvolumes_used

          device.shadowed_subvolumes(planned_devices).each do |subvol|
            if subvols_added
              log.info "Default subvolume #{subvol} would be shadowed. Removing it."
            else
              # TODO: this should be reported to the user, but first we need to
              # decide how error reporting will be handled in AutoinstProposal
              log.warn "Subvolume #{subvol} from the profile would be shadowed. Removing it."
            end
            device.subvolumes.delete(subvol)
          end
        end
      end

    end
  end
end
