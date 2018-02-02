require "yast"
require "cwm"
require "y2storage"
require "y2partitioner/widgets/mkfs_optiondata"

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
      def initialize(controller)
        textdomain "storage"
        @controller = controller
        self.handle_all_events = true
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
          * MkfsOptiondata.options_for(fstype).map do |w|
            Left(Widgets.const_get(w[:widget]).new(@controller, w))
          end
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
