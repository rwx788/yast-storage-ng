require "yast"

module Y2Partitioner
  module Widgets
    # a class
    class MkfsOptiondata
      extend Yast::I18n

      FOO = [
        {
          fs:          %i(ext2 ext3 ext4),
          widget:      :MkfsInputField,
          label:       _("Stride &Length in Blocks"),
          default:     "none",
          validate:    lambda do |x|
            (x.match?(/^\d+$/) && x.to_i > 1) || x == "none"
          end,
          mkfs_option: "-Estride=",
          error:       _(
            "The \"Stride Length in Blocks\" value is invalid.\n" \
            "Select a value greater than 1 or 'none'.\n"
          ),
          # help text, richtext format
          help:        _(
            "Set RAID-related options for the file system. Currently, the only supported " \
            "argument is 'stride', which takes the number of blocks in a " \
            "RAID stripe as its argument."
          )
        },

        {
          fs:          %i(ext2 ext3 ext4),
          widget:      :MkfsComboBox,
          label:       _("Block &Size in Bytes"),
          values:      %w(auto 1024 2048 4096 8192 16384 32768),
          default:     "auto",
          mkfs_option: "-b",
          # help text, richtext format
          help:        _(
            "Specify the size of blocks in bytes. " \
            "If auto is selected, the block size is determined by the file system size " \
            "and the expected use of the file system."
          )
        },

        {
          fs:          %i(ext2 ext3 ext4),
          widget:      :MkfsComboBox,
          label:       _("Bytes per &Inode"),
          values:      %w(auto 1024 2048 4096 8192 16384 32768),
          default:     "auto",
          mkfs_option: "-i",
          # help text, richtext format
          help:        _(
            "Specify the bytes to inode ratio. YaST creates an inode for every " \
            "&lt;bytes-per-inode&gt; bytes of space on the disk. The larger the " \
            "bytes-per-inode ratio, the fewer inodes will be created.  Generally, this " \
            "value should not be smaller than the block size of the file system, or else " \
            "too many inodes will be created. It is not possible to expand the number of " \
            "inodes on a file system after its creation. So be sure to enter a reasonable " \
            "value for this parameter."
          )
        },

        {
          fs:          %i(ext3 ext4),
          widget:      :MkfsComboBox,
          label:       _("&Inode Size"),
          values:      %w(default 128 256 512 1024),
          default:     "default",
          mkfs_option: "-I",
          # help text, richtext format
          help:        _(
            "This option specifies the inode size of the file system."
          )
        },

        {
          fs:          %i(ext2 ext3 ext4),
          widget:      :MkfsInputField,
          label:       _("Percentage of Blocks &Reserved for root"),
          default:     "auto",
          validate:    lambda do |x|
            (x.match?(/^\d+(\.\d*)?$/) && x.to_f >= 0 && x.to_f <= 99) || x == "auto"
          end,
          mkfs_option: "-m",
          error:       _(
            "The \"Percentage of Blocks Reserved for root\" value is incorrect.\n" \
            "Allowed are float numbers no larger than 99 (e.g. 0.5).\n"
          ),
          # help text, richtext format
          help:        _(
            "Specify the percentage of blocks reserved for the super user. " \
            "The default is computed so that normally 1 GiB is reserved. " \
            "Upper limit for reserved default is 5.0, lowest reserved default is 0.1."
          )
        },

        {
          fs:          %i(ext2 ext3 ext4),
          widget:      :MkfsCheckBox,
          label:       _("Disable Regular &Checks"),
          default:     false,
          tune_option: "-c 0 -i 0",
          # help text, richtext format
          help:        _(
            "Disable regular file system check at booting."
          )
        },

        {
          fs:          %i(ext3 ext4),
          widget:      :MkfsCheckBox,
          label:       _("&Directory Index Feature"),
          default:     false,
          mkfs_option: "-O dir_index",
          # help text, richtext format
          help:        _(
            "Enables use of hashed b-trees to speed up lookups in large directories."
          )
        },

        {
          fs:          %i(ext4),
          widget:      :MkfsCheckBox,
          label:       _("&No Journal"),
          default:     false,
          mkfs_option: "-O ^has_journal",
          # help text, richtext format
          help:        _(
            "Suppressed use of journaling on filesystem. " \
            "Only activate this when you really know what you are doing."
          )
        },

        {
          fs:          %i(xfs),
          widget:      :MkfsComboBox,
          label:       _("Block &Size in Bytes"),
          values:      %w(auto 512 1024 2048 4096 8192 16384 32768),
          default:     "auto",
          mkfs_option: "-bsize=",
          # help text, richtext format
          help:        _(
            "Specify the size of blocks in bytes. " \
            "If auto is selected, the standard block size of 4096 is used."
          )
        },

        {
          fs:          %i(xfs),
          widget:      :MkfsComboBox,
          label:       _("&Inode Size"),
          values:      %w(auto 256 512 1024 2048),
          default:     "auto",
          mkfs_option: "-isize=",
          # help text, richtext format
          help:        _(
            "This option specifies the inode size of the file system."
          )
        },

        {
          fs:          %i(xfs),
          widget:      :MkfsInputField,
          label:       _("&Percentage of Inode Space"),
          default:     "auto",
          validate:    lambda do |x|
            (x.match?(/^\d+$/) && x.to_i <= 100) || x == "auto"
          end,
          mkfs_option: "-imaxpct=",
          error:       _(
            "Choose a value between 0 and 100, or 'auto'."
          ),
          # help text, richtext format
          help:        _(
            "This option specifies the maximum percentage " \
            "of space in the file system that can be allocated to inodes. " \
            "Choose a value between 0 and 100, or 'auto'. " \
            "A value of 0 means that there are no restrictions on inode space."
          )
        },

        {
          fs:          %i(xfs),
          widget:      :MkfsCheckBox,
          label:       _("Inodes &Aligned"),
          default:     true,
          mkfs_option: "-ialign=0",
          # help text, richtext format
          help:        _(
            "This option is used to specify whether inode allocation is aligned. " \
            "By default inodes are aligned as this is more efficient than unaligned access. " \
            "But yhis option can be used to turn off inode alignment when the filesystem "\
            "needs to be mountable by an old version of IRIX that does not have the "\
            "inode alignment feature."
          )
        },

        {
          fs:          %i(vfat),
          widget:      :MkfsComboBox,
          label:       _("Number of &FATs"),
          values:      %w(auto 1 2),
          default:     "auto",
          mkfs_option: "-f",
          # help text, richtext format
          help:        _(
            "Specify the number of file allocation tables. " \
            "The default is 2."
          )
        },

        {
          fs:          %i(vfat),
          widget:      :MkfsComboBox,
          label:       _("FAT &Size"),
          values:      %w(auto 12 16 32),
          default:     "auto",
          mkfs_option: "-F",
          # help text, richtext format
          help:        _(
            "Specifies the size of the file allocation tables entries (12, 16, or 32 bit). " \
            "If 'auto' is specified, a suitable value is chosen dependng on the file system size."
          )
        },

        {
          fs:          %i(vfat),
          widget:      :MkfsInputField,
          label:       _("Root &Dir Entries"),
          default:     "auto",
          validate:    lambda do |x|
            (x.match?(/^\d+$/) && x.to_i >= 112) || x == "auto"
          end,
          mkfs_option: "-r",
          error:       _(
            "The minimum number of entries is 112."
          ),
          # help text, richtext format
          help:        _(
            "Select the number of entries available in the root directory. " \
            "Choose a value that is at least 112, or 'auto'."
          )
        }
      ]

      def self.options_for(filesystem)
        fs = filesystem.type.to_sym
        FOO.find_all { |x| x[:fs].include?(fs) }
      end
    end
  end
end
