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

require "y2storage/disk_size"
require "y2storage/boot_requirements_checker"
require "y2storage/subvol_specification"
require "y2storage/proposal_settings"
require "y2storage/proposal/autoinst_size_parser"

module Y2Storage
  module Proposal
    class AutoinstBasePlanner
      include Yast::Logger

      # Constructor
      #
      # @param devicegraph [Devicegraph] Devicegraph to be used as starting point
      # @param issues_list [AutoinstIssues::List] List of AutoYaST issues to register them
      def initialize(devicegraph, issues_list)
        @devicegraph = devicegraph
        @issues_list = issues_list
      end

    protected

      # @return [Devicegraph] Starting devicegraph
      attr_reader :devicegraph
      # @return [AutoinstIssues::List] List of AutoYaST issues to register them
      attr_reader :issues_list

      # Set all the common attributes that are shared by any device defined by
      # a <partition> section of AutoYaST (i.e. a LV, MD or partition).
      #
      # @param device  [Planned::Device] Planned device
      # @param partition_section [AutoinstProfile::PartitionSection] AutoYaST
      #   specification of the concrete device
      # @param drive_section [AutoinstProfile::DriveSection] AutoYaST drive
      #   section containing the partition one
      def device_config(device, partition_section, drive_section)
        add_common_device_attrs(device, partition_section)
        add_snapshots(device, drive_section)
        add_subvolumes_attrs(device, partition_section)
      end

      # Set common devices attributes
      #
      # This method modifies the first argument setting crypt_key, crypt_fs,
      # mount, label, uuid and filesystem.
      #
      # @param device  [Planned::Device] Planned device
      # @param section [AutoinstProfile::PartitionSection] AutoYaST specification
      def add_common_device_attrs(device, section)
        device.encryption_password = section.crypt_key if section.crypt_fs
        device.mount_point = section.mount
        device.label = section.label
        device.uuid = section.uuid
        device.filesystem_type = section.type_for_filesystem
        device.mount_by = section.type_for_mountby
        device.mkfs_options = section.mkfs_options
        device.fstab_options = section.fstab_options
      end

      # Set device attributes related to snapshots
      #
      # This method modifies the first argument
      #
      # @param device  [Planned::Device] Planned device
      # @param drive_section [AutoinstProfile::DriveSection] AutoYaST specification
      def add_snapshots(device, drive_section)
        return unless device.respond_to?(:root?) && device.root?

        # Always try to enable snapshots if possible
        snapshots = true
        snapshots = false if drive_section.enable_snapshots == false

        device.snapshots = snapshots
      end

      # Set devices attributes related to Btrfs subvolumes
      #
      # This method modifies the first argument setting default_subvolume and
      # subvolumes.
      #
      # @param device  [Planned::Device] Planned device
      # @param section [AutoinstProfile::PartitionSection] AutoYaST specification
      def add_subvolumes_attrs(device, section)
        return unless device.btrfs?

        subvol_specs = section.subvolumes
        mount = device.mount_point

        if subvol_specs.nil? && mount == "/"
          @default_subvolumes_used = true
          subvol_specs = proposal_settings.subvolumes
        end

        device.default_subvolume = section.subvolumes_prefix ||
          proposal_settings.legacy_btrfs_default_subvolume
        device.subvolumes = subvol_specs
      end

      # @param device  [Planned::Partition,Planned::LvmLV] Planned device
      # @param name    [String] Name of the device to reuse
      # @param section [AutoinstProfile::PartitionSection] AutoYaST specification
      def add_device_reuse(device, name, section)
        device.reuse = name
        device.reformat = !!section.format
        device.resize = !!section.resize if device.respond_to?(:resize=)
      end

      # Instance of {ProposalSettings} based on the current product.
      #
      # Used to ensure consistency between the guided proposal and the AutoYaST
      # one when default values are used.
      #
      # @return [ProposalSettings]
      def proposal_settings
        @proposal_settings ||= ProposalSettings.new_for_current_product
      end

      def remove_shadowed_subvols(planned_devices)
        planned_devices.each do |device|
          next unless device.respond_to?(:subvolumes)

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

      # Parse the 'size' element
      #
      # @param section [AutoinstProfile::PartitionSection]
      # @param min     [DiskSize] Minimal size
      # @param max     [DiskSize] Maximal size
      # @see AutoinstSizeParser
      def parse_size(section, min, max)
        AutoinstSizeParser.new(proposal_settings).parse(section.size, section.mount, min, max)
      end
    end
  end
end
