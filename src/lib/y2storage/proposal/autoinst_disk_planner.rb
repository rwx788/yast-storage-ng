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

require "y2storage/proposal/autoinst_base_planner"

module Y2Storage
  module Proposal
    class AutoinstDiskPlanner < AutoinstBasePlanner
      # Returns an array of planned partitions for a given disk
      #
      # @param disk [Disk,Dasd] Disk to place the partitions on
      # @param drive [AutoinstProfile::DriveSection] drive section describing
      #   the layout for the disk
      # @return [Array<Planned::Partition>] List of planned partitions
      def planned_for_disk(disk, drive)
        result = []
        drive.partitions.each_with_index do |partition_section|
          # TODO: fix Planned::Partition.initialize
          partition = Y2Storage::Planned::Partition.new(nil, nil)

          next unless assign_size_to_partition(disk, partition, partition_section)

          # TODO: partition.bootable is not in the AutoYaST profile. Check if
          # there's some logic to set it in the old code.

          partition.disk = disk.name
          partition.partition_id = partition_section.id_for_partition
          partition.lvm_volume_group_name = partition_section.lvm_group
          partition.raid_name = partition_section.raid_name

          device_config(partition, partition_section, drive)
          add_partition_reuse(partition, partition_section) if partition_section.create == false

          result << partition
        end

        result
      end

      # Set 'reusing' attributes for a partition
      #
      # This method modifies the first argument setting the values related to
      # reusing a partition (reuse and format).
      #
      # @param partition [Planned::Partition] Planned partition
      # @param section   [AutoinstProfile::PartitionSection] AutoYaST specification
      def add_partition_reuse(partition, section)
        partition_to_reuse = find_partition_to_reuse(devicegraph, section)
        return unless partition_to_reuse
        partition.filesystem_type ||= partition_to_reuse.filesystem_type
        add_device_reuse(partition, partition_to_reuse.name, section)
      end

      # @param devicegraph [Devicegraph] Devicegraph to search for the partition to reuse
      # @param part_section [AutoinstProfile::PartitionSection] Partition specification
      #   from AutoYaST
      def find_partition_to_reuse(devicegraph, part_section)
        device =
          if part_section.partition_nr
            devicegraph.partitions.find { |i| i.number == part_section.partition_nr }
          elsif part_section.label
            devicegraph.partitions.find { |i| i.filesystem_label == part_section.label }
          else
            issues_list.add(:missing_reuse_info, part_section)
            nil
          end

        issues_list.add(:missing_reusable_device, part_section) unless device
        device
      end

      # @return [DiskSize] Minimal partition size
      PARTITION_MIN_SIZE = DiskSize.B(1).freeze

      # Assign disk size according to AutoYaSt section
      #
      # @param disk        [Disk,Dasd]          Disk to put the partitions on
      # @param partition   [Planned::Partition] Partition to assign the size to
      # @param part_section   [AutoinstProfile::PartitionSection] Partition specification from AutoYaST
      def assign_size_to_partition(disk, partition, part_section)
        size_info = parse_size(part_section, PARTITION_MIN_SIZE, disk.size)

        if size_info.nil?
          issues_list.add(:invalid_value, part_section, :size)
          return false
        end

        partition.min_size = size_info.min
        partition.max_size = size_info.max
        partition.weight = 1 if size_info.unlimited?
        true
      end

    end
  end
end
