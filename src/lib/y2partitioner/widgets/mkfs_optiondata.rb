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
            "<p><b>Stride Length in Blocks:</b> " \
            "Set RAID-related options for the file system. Currently, the only supported " \
            "argument is 'stride', which takes the number of blocks in a " \
            "RAID stripe as its argument.</p>"
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
            "<p><b>Block Size:</b> " \
            "Specify the size of blocks in bytes. " \
            "If auto is selected, the block size is determined by the file system size " \
            "and the expected use of the file system.</p>"
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
            "<p><b>Bytes per Inode:</b> " \
            "Specify the bytes to inode ratio. YaST creates an inode for every " \
            "&lt;bytes-per-inode&gt; bytes of space on the disk. The larger the " \
            "bytes-per-inode ratio, the fewer inodes will be created.  Generally, this " \
            "value should not be smaller than the block size of the file system, or else " \
            "too many inodes will be created. It is not possible to expand the number of " \
            "inodes on a file system after its creation. So be sure to enter a reasonable " \
            "value for this parameter.</p>"
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
            "<p><b>Percentage of Blocks Reserved for root:</b> " \
            "Specify the percentage of blocks reserved for the super user. " \
            "The default is computed so that normally 1 GiB is reserved. " \
            "Upper limit for reserved default is 5.0, lowest reserved default is 0.1.</p>"
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
            "<p><b>Inode Size:</b> " \
            "This option specifies the inode size of the file system.</p>"
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
            "<p><b>Disable Regular Checks:</b> " \
            "Disable regular file system check at booting.</p>"
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
            "<p><b>Directory Index:</b> " \
            "Enables use of hashed b-trees to speed up lookups in large directories.</p>"
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
            "<p><b>No Journal:</b> " \
            "Suppressed use of journaling on filesystem. " \
            "Only activate this when you really know what you are doing.</p>"
          )
        },



      ]

      def self.options_for(fs)
        FOO.find_all { |x| x[:fs].include?(fs) }
      end
    end
  end
end
