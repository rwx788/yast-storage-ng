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
    class AutoinstVGPlanner < AutoinstBasePlanner
      # Returns a planned volume group according to an AutoYaST specification
      #
      # @param drive [AutoinstProfile::DriveSection] drive section describing
      #   the volume group
      # @return [Planned::LvmVg] Planned volume group
      def planned_for_vg(drive)
        vg = Y2Storage::Planned::LvmVg.new(volume_group_name: File.basename(drive.device))

        drive.partitions.each_with_object(vg.lvs) do |lv_section, lvs|
          # TODO: fix Planned::LvmLv.initialize
          lv = Y2Storage::Planned::LvmLv.new(nil, nil)
          lv.logical_volume_name = lv_section.lv_name
          device_config(lv, lv_section, drive)
          add_lv_reuse(lv, vg.volume_group_name, lv_section) if lv_section.create == false

          next unless assign_size_to_lv(vg, lv, lv_section)
          lvs << lv
        end

        add_vg_reuse(vg, drive)
        vg
      end

      # Set 'reusing' attributes for a logical volume
      #
      # This method modifies the first argument setting the values related to
      # reusing a logical volume (reuse and format).
      #
      # @param lv      [Planned::LvmLv] Planned logical volume
      # @param vg_name [String]         Volume group name to search for the logical volume to reuse
      # @param section [AutoinstProfile::PartitionSection] AutoYaST specification
      def add_lv_reuse(lv, vg_name, section)
        lv_to_reuse = find_lv_to_reuse(devicegraph, vg_name, section)
        return unless lv_to_reuse
        lv.logical_volume_name ||= lv_to_reuse.lv_name
        lv.filesystem_type ||= lv_to_reuse.filesystem_type
        add_device_reuse(lv, lv_to_reuse.name, section)
      end

      # Set 'reusing' attributes for a volume group
      #
      # This method modifies the first argument setting the values related to
      # reusing a volume group (reuse and format).
      #
      # @param vg   [Planned::LvmVg] Planned volume group
      # @param drive [AutoinstProfile::DriveSection] drive section describing
      #   the volume group
      def add_vg_reuse(vg, drive)
        vg.make_space_policy = drive.keep_unknown_lv ? :keep : :remove

        return unless vg.make_space_policy == :keep || vg.lvs.any?(&:reuse?)
        vg_to_reuse = find_vg_to_reuse(devicegraph, vg, drive)
        vg.reuse = vg_to_reuse.vg_name if vg_to_reuse
      end

      # @param devicegraph [Devicegraph] Devicegraph to search for the volume group to reuse
      # @param vg          [Planned::LvmVg] Planned volume group
      # @param drive       [AutoinstProfile::DriveSection] drive section describing
      def find_vg_to_reuse(devicegraph, vg, drive)
        return nil unless vg.volume_group_name
        device = devicegraph.lvm_vgs.find { |v| v.vg_name == vg.volume_group_name }
        issues_list.add(:missing_reusable_device, drive) unless device
        device
      end

      # @param devicegraph [Devicegraph] Devicegraph to search for the logical volume to reuse
      # @param vg_name     [String]      Volume group name to search for the logical volume to reuse
      # @param part_section   [AutoinstProfile::PartitionSection] LV specification from AutoYaST
      def find_lv_to_reuse(devicegraph, vg_name, part_section)
        vg = devicegraph.lvm_vgs.find { |v| v.vg_name == vg_name }
        if vg.nil?
          issues_list.add(:missing_reusable_device, part_section)
          return
        end

        device =
          if part_section.lv_name
            vg.lvm_lvs.find { |v| v.lv_name == part_section.lv_name }
          elsif part_section.label
            vg.lvm_lvs.find { |v| v.filesystem_label == part_section.label }
          else
            issues_list.add(:missing_reuse_info, part_section)
            :missing_info
          end

        issues_list.add(:missing_reusable_device, part_section) unless device
        :missing_info == device ? nil : device
      end

      # Assign LV size according to AutoYaST section
      #
      # @param vg         [Planned::LvmVg] Volume group
      # @param lv         [Planned::LvmLv] Logical volume
      # @param lv_section [AutoinstProfile::PartitionSection] AutoYaST section
      # @return [Boolean] true if the size was parsed and asssigned; false it was not valid
      def assign_size_to_lv(vg, lv, lv_section)
        size_info = parse_size(lv_section, vg.extent_size, DiskSize.unlimited)

        if size_info.nil?
          issues_list.add(:invalid_value, lv_section, :size)
          return false
        end

        if size_info.percentage
          lv.percent_size = size_info.percentage
        else
          lv.min_size = size_info.min
          lv.max_size = size_info.max
        end
        lv.weight = 1 if size_info.unlimited?

        true
      end
    end
  end
end
