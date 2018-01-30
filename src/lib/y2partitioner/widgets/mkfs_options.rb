require "yast"
require "cwm"
require "y2storage"

module Y2Partitioner
  # Partitioner widgets
  module Widgets
    include Yast::Logger

    class MkfsOptions < CWM::CustomWidget
      def initialize(controller)
        @controller = controller

        self.handle_all_events = true
      end

      def init
      end

      def help
        Yast::CWM.widgets_in_contents([self]).find_all {
          |w| w != self && w.respond_to?(:help)
        }.map(&:help).join("\n")
      end

      def handle(event)
        case event["ID"]
        when :help
          Yast::Wizard.ShowHelp(help)
        end
      end

      def contents
        VBox(
          Left(XXX.new(@controller)),
          VSpacing(1),
          Left(XXX.new(@controller)),
          VSpacing(1),
          Left(XXX.new(@controller))
        )
      end
    end

    # Input field to set the partition Label
    class XXX < CWM::ComboBox
      FOO = ["foo", "bar", "xxx"].freeze

      def initialize(controller)
        textdomain "storage"
        @controller = controller
      end

      def filesystem
        @controller.filesystem
      end

      def label
        _("XXX")
      end

      def opt
      end

      def help
       "<p>be <b>cool</b></p>"
      end

      def items
        FOO.map { |s| [s, "X#{s}X"] }
      end

      def init
        self.value = filesystem.mkfs_options || "foo"
      end

      def store
        filesystem.mkfs_options = self.value
      end

    end

  end
end
