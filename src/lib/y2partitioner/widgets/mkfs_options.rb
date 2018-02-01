require "yast"
require "cwm"
require "y2storage"

module Y2Partitioner
  # Partitioner widgets
  module Widgets
    include Yast::Logger

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
            mkfs_option: "-Estride=",
            error:       _(
              "The \"Stride Length in Blocks\" value is invalid.\nSelect a value greater than 1.\n"
            ),
            help:        _(
              "<p><b>Stride Length in Blocks:</b>\n" \
              "Set RAID-related options for the file system. Currently, the only supported\n" \
              "argument is 'stride', which takes the number of blocks in a\n" \
              "RAID stripe as its argument.</p>\n"
            )
          },

          {
            fs:          %i(ext2 ext3 ext4),
            widget:      :MkfsComboBox,
            label:       _("Block &Size in Bytes"),
            values:      ["auto", "1024", "2048", "4096"],
            default:     "auto",
            mkfs_option: "-b",
            help:        _(
              "<p><b>Block Size:</b>\nSpecify the size of blocks in bytes. " \
              "Valid block size values are 1024, 2048, and 4096 bytes per block. " \
              "If auto is selected, the block size is determined by the file system size " \
              "and the expected use of the file system.</p>\n"
            )
          },

          {
            fs:          %i(ext2 ext3 ext4),
            widget:      :MkfsCheckBox,
            label:       _("Disable Regular Checks"),
            default:     false,
            tune_option: "-c 0 -i 0",
            help:        _(
              "<p><b>Disable Regular Checks:</b>\nDisable regular file system check at booting.</p>\n"
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

      def init
      end

      def store
        @all_options.map do |w|
          log.info "XXX store: new = #{w[:new_value]}"
          if w[:new_value] && w[:new_value] != w[:value]
            log.info "XXX store: #{w[:new_value]}"
          end
        end
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
        # VSpacing(1)
        VBox(
          * @all_options.map do |w|
            Left(Widgets.const_get(w[:widget]).new(@controller, w)) if w[:fs].include?(fstype)
          end.compact
        )
      end

      def fstype
        @controller.filesystem.type.to_sym
      end

      def self.store_option(filesystem, option, value)
        log.info "XXX val = #{value}"
        if option[:mkfs_option]
          opt = option[:mkfs_option]
          str = filesystem.mkfs_options
        else
          opt = option[:tune_option]
          str = filesystem.tune_options
        end

        str.gsub!(/\b#{Regexp.escape(opt)}\S*/, "")

        if value != option[:default]
          case value
          when true, false
            str << " #{opt}"
          else
            str << " #{opt}#{value}"
          end
        end

        str.gsub!(/\s{2,}/, " ")
        str.gsub!(/^\s+|\s+$/, "")

        if option[:mkfs_option]
          filesystem.mkfs_options = str
        else
          filesystem.tune_options = str
        end
      end
    end

    # a class
    class MkfsComboBox < CWM::ComboBox
      def initialize(controller, opts)
        @controller = controller
        @opts = opts
      end

      def label
        @opts[:label]
      end

      def help
        @opts[:help]
      end

      def items
        @opts[:values].map { |s| [s, s] }
      end

      def init
        self.value = @opts[:default]
      end

      def store
        MkfsOptions.store_option(@controller.filesystem, @opts, value)
      end
    end

    # a class
    class MkfsInputField < CWM::InputField
      def initialize(controller, opts)
        @controller = controller
        @opts = opts
      end

      def label
        @opts[:label]
      end

      def help
        @opts[:help]
      end

      def init
        self.value = @opts[:default]
      end

      def store
        MkfsOptions.store_option(@controller.filesystem, @opts, value)
      end
    end

    # a class
    class MkfsCheckBox < CWM::CheckBox
      def initialize(controller, opts)
        @controller = controller
        @opts = opts
      end

      def label
        @opts[:label]
      end

      def help
        @opts[:help]
      end

      def init
        self.value = @opts[:default]
      end

      def store
        MkfsOptions.store_option(@controller.filesystem, @opts, value)
      end
    end
  end
end
