require "yast"
require "cwm"
require "y2storage"

module Y2Partitioner
  # Partitioner widgets
  module Widgets
    include Yast::Logger

    # a module
    module MkfsCommon
      def initialize(controller, opts)
        @controller = controller
        @opts = opts
        self.widget_id = "#{self.class}_#{object_id}"
      end

      def label
        @opts[:label]
      end

      def help
        @opts[:help]
      end

      def init
        self.value = MkfsOptions.get_option(@controller.filesystem, @opts)
      end

      def store
        MkfsOptions.set_option(@controller.filesystem, @opts, value)
      end

      def validate
        return true unless @opts[:validate] && @opts[:error]

        if !@opts[:validate][value]
          Yast::Popup.Error(format(@opts[:error], value))
          false
        else
          true
        end
      end
    end

    # a class
    class MkfsOptions < CWM::CustomWidget
      # rubocop:disable Metrics/MethodLength
      def all_options
        [
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
            fs:          %i(ext2 ext3 ext4),
            widget:      :MkfsCheckBox,
            label:       _("&Disable Regular Checks"),
            default:     false,
            tune_option: "-c 0 -i 0",
            # help text, richtext format
            help:        _(
              "<p><b>Disable Regular Checks:</b> " \
              "Disable regular file system check at booting.</p>"
            )
          }
        ]
      end
      # rubocop:enable Metrics/MethodLength

      def initialize(controller)
        textdomain "storage"
        @controller = controller
        self.handle_all_events = true
        @all_options = all_options
      end

      def help
        Yast::CWM.widgets_in_contents(contents).find_all do |w|
          w.respond_to?(:help)
        end.map(&:help).join("\n")
      end

      def opt
        [:notify]
      end

      def handle(event)
        case event["ID"]
        when :help
          Yast::Wizard.ShowHelp(help)
        end
      end

      def contents
        # FIXME: add some VSpacing(1)?
        # ???: contents is called 3 times for each dialog, so cache it
        @contents ||= VBox(
          * @all_options.map do |w|
            Left(Widgets.const_get(w[:widget]).new(@controller, w)) if w[:fs].include?(fstype)
          end.compact
        )
      end

      def self.get_option(filesystem, option)
        if option[:mkfs_option]
          opt = option[:mkfs_option]
          str = filesystem.mkfs_options
        else
          opt = option[:tune_option]
          str = filesystem.tune_options
        end

        value = option[:default]

        m = str.match(/(^|\s)#{Regexp.escape(opt)}(\S*)/)
        if m
          case option[:default]
          when true, false
            value = !option[:default]
          else
            value = m[2]
          end
        end

        log.info("XXX get: #{value}")

        value
      end

      def self.set_option(filesystem, option, value)
        log.info "XXX set: #{value}"

        if option[:mkfs_option]
          opt = option[:mkfs_option]
          str = filesystem.mkfs_options
        else
          opt = option[:tune_option]
          str = filesystem.tune_options
        end

        str.gsub!(/(^|\s+)#{Regexp.escape(opt)}\S*/, "")

        if value != option[:default]
          case value
          when true, false
            str << " #{opt}"
          else
            str << " #{opt}#{value}"
          end
        end

        str.strip!

        if option[:mkfs_option]
          filesystem.mkfs_options = str
        else
          filesystem.tune_options = str
        end
      end

    private

      def fstype
        @controller.filesystem.type.to_sym
      end
    end

    # a class
    class MkfsInputField < CWM::InputField
      include MkfsCommon
    end

    # a class
    class MkfsCheckBox < CWM::CheckBox
      include MkfsCommon
    end

    # a class
    class MkfsComboBox < CWM::ComboBox
      include MkfsCommon

      def items
        @opts[:values].map { |s| [s, s] }
      end
    end
  end
end
