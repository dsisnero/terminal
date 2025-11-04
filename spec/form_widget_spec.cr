require "./spec_helper"

describe Terminal::FormWidget do
  describe Terminal::FormControl do
    it "creates text input control" do
      control = Terminal::FormControl.new(
        id: "name",
        type: Terminal::FormControlType::TextInput,
        label: "Name"
      )
      control.id.should eq("name")
      control.label.should eq("Name")
      control.value.should eq("")
    end

    it "validates required fields" do
      control = Terminal::FormControl.new(
        id: "email",
        type: Terminal::FormControlType::TextInput,
        label: "Email",
        required: true
      )

      control.valid?.should be_false
      control.error.should eq("Required field")

      control.value = "test@example.com"
      control.valid?.should be_true
      control.error.should be_nil
    end

    it "validates with custom validator" do
      email_validator = ->(val : String) {
        val.includes?("@") && val.includes?(".")
      }

      control = Terminal::FormControl.new(
        id: "email",
        type: Terminal::FormControlType::TextInput,
        label: "Email",
        validator: email_validator
      )

      control.value = "invalid"
      control.valid?.should be_false
      control.error.should eq("Invalid value")

      control.value = "valid@example.com"
      control.valid?.should be_true
      control.error.should be_nil
    end
  end

  describe Terminal::FormWidget do
    describe "#initialize" do
      it "creates empty form" do
        form = Terminal::FormWidget.new(id: "form1")
        form.id.should eq("form1")
        form.controls.size.should eq(0)
        form.focused_index.should eq(0)
      end

      it "accepts initial controls" do
        controls = [
          Terminal::FormControl.new(
            id: "name",
            type: Terminal::FormControlType::TextInput,
            label: "Name"
          ),
          Terminal::FormControl.new(
            id: "age",
            type: Terminal::FormControlType::TextInput,
            label: "Age"
          ),
        ]

        form = Terminal::FormWidget.new(id: "form1", controls: controls)
        form.controls.size.should eq(2)
      end
    end

    describe "#add_control" do
      it "adds control to form" do
        form = Terminal::FormWidget.new(id: "form1")

        control = Terminal::FormControl.new(
          id: "username",
          type: Terminal::FormControlType::TextInput,
          label: "Username"
        )

        form.add_control(control)
        form.controls.size.should eq(1)
        form.controls[0].id.should eq("username")
      end
    end

    describe "#handle" do
      it "navigates between controls with tab" do
        form = Terminal::FormWidget.new(
          id: "form1",
          controls: [
            Terminal::FormControl.new(id: "c1", type: Terminal::FormControlType::TextInput, label: "C1"),
            Terminal::FormControl.new(id: "c2", type: Terminal::FormControlType::TextInput, label: "C2"),
            Terminal::FormControl.new(id: "c3", type: Terminal::FormControlType::TextInput, label: "C3"),
          ]
        )

        form.focused_index.should eq(0)

        form.handle(Terminal::Msg::KeyPress.new("tab"))
        form.focused_index.should eq(1)

        form.handle(Terminal::Msg::KeyPress.new("tab"))
        form.focused_index.should eq(2)

        form.handle(Terminal::Msg::KeyPress.new("tab"))
        form.focused_index.should eq(3) # Submit button

        form.handle(Terminal::Msg::KeyPress.new("tab"))
        form.focused_index.should eq(0) # Wraps around
      end

      it "navigates with up/down arrows" do
        form = Terminal::FormWidget.new(
          id: "form1",
          controls: [
            Terminal::FormControl.new(id: "c1", type: Terminal::FormControlType::TextInput, label: "C1"),
            Terminal::FormControl.new(id: "c2", type: Terminal::FormControlType::TextInput, label: "C2"),
          ]
        )

        form.handle(Terminal::Msg::KeyPress.new("down"))
        form.focused_index.should eq(1)

        form.handle(Terminal::Msg::KeyPress.new("up"))
        form.focused_index.should eq(0)
      end

      it "inputs text into focused text control" do
        control = Terminal::FormControl.new(
          id: "name",
          type: Terminal::FormControlType::TextInput,
          label: "Name"
        )
        form = Terminal::FormWidget.new(id: "form1", controls: [control])

        form.handle(Terminal::Msg::InputEvent.new('J', Time::Span::ZERO))
        form.handle(Terminal::Msg::InputEvent.new('o', Time::Span::ZERO))
        form.handle(Terminal::Msg::InputEvent.new('h', Time::Span::ZERO))
        form.handle(Terminal::Msg::InputEvent.new('n', Time::Span::ZERO))

        form.controls[0].value.should eq("John")
      end

      it "supports cursor navigation and editing in text control" do
        control = Terminal::FormControl.new(
          id: "name",
          type: Terminal::FormControlType::TextInput,
          label: "Name"
        )
        form = Terminal::FormWidget.new(id: "form1", controls: [control])

        %w[H i].each do |ch|
          form.handle(Terminal::Msg::InputEvent.new(ch[0], Time::Span::ZERO))
        end

        form.controls[0].value.should eq("Hi")
        form.controls[0].cursor_pos.should eq(2)

        form.handle(Terminal::Msg::KeyPress.new("left"))
        form.controls[0].cursor_pos.should eq(1)

        form.handle(Terminal::Msg::InputEvent.new('!', Time::Span::ZERO))
        form.controls[0].value.should eq("H!i")
        form.controls[0].cursor_pos.should eq(2)

        form.handle(Terminal::Msg::KeyPress.new("backspace"))
        form.controls[0].value.should eq("Hi")
        form.controls[0].cursor_pos.should eq(1)

        form.handle(Terminal::Msg::KeyPress.new("delete"))
        form.controls[0].value.should eq("H")
        form.controls[0].cursor_pos.should eq(1)

        form.handle(Terminal::Msg::KeyPress.new("home"))
        form.controls[0].cursor_pos.should eq(0)

        form.handle(Terminal::Msg::KeyPress.new("end"))
        form.controls[0].cursor_pos.should eq(1)
      end

      it "deletes text with backspace" do
        control = Terminal::FormControl.new(
          id: "name",
          type: Terminal::FormControlType::TextInput,
          label: "Name",
          value: "hello"
        )
        form = Terminal::FormWidget.new(id: "form1", controls: [control])

        form.handle(Terminal::Msg::KeyPress.new("backspace"))
        form.controls[0].value.should eq("hell")
      end

      it "toggles checkbox with enter or space" do
        control = Terminal::FormControl.new(
          id: "agree",
          type: Terminal::FormControlType::Checkbox,
          label: "I agree",
          value: "false"
        )
        form = Terminal::FormWidget.new(id: "form1", controls: [control])

        form.handle(Terminal::Msg::KeyPress.new("space"))
        form.controls[0].value.should eq("true")

        form.handle(Terminal::Msg::KeyPress.new("enter"))
        form.controls[0].value.should eq("false")
      end

      it "expands and collapses dropdown with enter" do
        control = Terminal::FormControl.new(
          id: "country",
          type: Terminal::FormControlType::Dropdown,
          label: "Country",
          options: ["USA", "Canada", "Mexico"],
          value: "USA"
        )
        form = Terminal::FormWidget.new(id: "form1", controls: [control])

        form.expanded_dropdown.should be_nil

        form.handle(Terminal::Msg::KeyPress.new("enter"))
        form.expanded_dropdown.should eq("country")

        form.handle(Terminal::Msg::KeyPress.new("enter"))
        form.expanded_dropdown.should be_nil
      end

      it "navigates dropdown options when expanded" do
        control = Terminal::FormControl.new(
          id: "color",
          type: Terminal::FormControlType::Dropdown,
          label: "Color",
          options: ["Red", "Green", "Blue"],
          value: "Red"
        )
        form = Terminal::FormWidget.new(id: "form1", controls: [control])

        form.handle(Terminal::Msg::KeyPress.new("enter")) # Expand
        form.handle(Terminal::Msg::KeyPress.new("down"))
        form.controls[0].value.should eq("Green")

        form.handle(Terminal::Msg::KeyPress.new("down"))
        form.controls[0].value.should eq("Blue")

        form.handle(Terminal::Msg::KeyPress.new("up"))
        form.controls[0].value.should eq("Green")
      end

      it "submits form with valid data" do
        submitted_data : Hash(String, String)? = nil

        form = Terminal::FormWidget.new(
          id: "form1",
          controls: [
            Terminal::FormControl.new(
              id: "name",
              type: Terminal::FormControlType::TextInput,
              label: "Name",
              value: "John"
            ),
            Terminal::FormControl.new(
              id: "age",
              type: Terminal::FormControlType::TextInput,
              label: "Age",
              value: "30"
            ),
          ]
        )

        form.on_submit { |data| submitted_data = data }

        # Focus submit button
        form.focused_index = 2
        form.handle(Terminal::Msg::KeyPress.new("enter"))

        submitted_data.should_not be_nil
        submitted_data.not_nil!["name"].should eq("John")
        submitted_data.not_nil!["age"].should eq("30")
      end

      it "does not submit form with invalid data" do
        submitted_data : Hash(String, String)? = nil

        form = Terminal::FormWidget.new(
          id: "form1",
          controls: [
            Terminal::FormControl.new(
              id: "email",
              type: Terminal::FormControlType::TextInput,
              label: "Email",
              required: true,
              value: "" # Empty required field
            ),
          ]
        )

        form.on_submit { |data| submitted_data = data }

        # Focus submit button
        form.focused_index = 1
        form.handle(Terminal::Msg::KeyPress.new("enter"))

        submitted_data.should be_nil
      end
    end

    describe "#render" do
      it "renders title bar" do
        form = Terminal::FormWidget.new(
          id: "form1",
          title: "Registration Form"
        )

        grid = form.render(50, 10)
        lines_text = grid.map(&.map(&.char).join)
        lines_text.any?(&.includes?("Registration Form")).should be_true
      end

      it "wraps form content inside a bordered box" do
        form = Terminal::FormWidget.new(id: "bordered")

        grid = form.render(40, 12)
        top_row = grid.first
        bottom_row = grid.last

        top_row.first.char.should eq('┌')
        top_row.last.char.should eq('┐')
        grid[1].first.char.should eq('│')
        grid[1].last.char.should eq('│')
        bottom_row.first.char.should eq('└')
        bottom_row.last.char.should eq('┘')
      end

      it "renders all controls with labels" do
        form = Terminal::FormWidget.new(
          id: "form1",
          controls: [
            Terminal::FormControl.new(
              id: "name",
              type: Terminal::FormControlType::TextInput,
              label: "Name"
            ),
            Terminal::FormControl.new(
              id: "email",
              type: Terminal::FormControlType::TextInput,
              label: "Email"
            ),
          ]
        )

        grid = form.render(50, 20)
        lines_text = grid.map(&.map(&.char).join)

        lines_text.any?(&.includes?("Name")).should be_true
        lines_text.any?(&.includes?("Email")).should be_true
      end

      it "shows required field indicator" do
        form = Terminal::FormWidget.new(
          id: "form1",
          controls: [
            Terminal::FormControl.new(
              id: "email",
              type: Terminal::FormControlType::TextInput,
              label: "Email",
              required: true
            ),
          ]
        )

        grid = form.render(50, 20)
        lines_text = grid.map(&.map(&.char).join)

        lines_text.any?(&.includes?("Email *")).should be_true
      end

      it "renders submit button" do
        form = Terminal::FormWidget.new(
          id: "form1",
          submit_label: "Send"
        )

        grid = form.render(50, 10)
        lines_text = grid.map(&.map(&.char).join)

        lines_text.any?(&.includes?("Send")).should be_true
      end

      it "displays validation errors" do
        control = Terminal::FormControl.new(
          id: "email",
          type: Terminal::FormControlType::TextInput,
          label: "Email",
          required: true
        )
        control.valid? # Triggers validation

        form = Terminal::FormWidget.new(
          id: "form1",
          controls: [control]
        )

        grid = form.render(50, 20)
        lines_text = grid.map(&.map(&.char).join)

        lines_text.any?(&.includes?("Required field")).should be_true
      end
    end
  end
end
