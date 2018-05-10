require 'rspec'

RSpec.describe "sanitize" do
  before do
    # For STDIN and STDOUT test
    # ref. https://qiita.com/key-amb/items/a134e2c3bea172b3deeb
    $stdin = StringIO.new(stdin_str)
    $stdout = StringIO.new

    $VERBOSE = nil
    # To disable a warning of "already initialized constant DUMMY_MAIL_TO"
    # ref. https://stackoverflow.com/questions/9236264/how-to-disable-warning-for-redefining-a-constant-when-loading-a-file
    load './sanitize.rb'
    $VERBOSE = false

    @stdout_string = $stdout.string
    $stdin = STDIN
    $stdout = STDOUT
  end

  test_address = 'test@example.com'
  test_address_2 = 'test2@example.com'

  describe "To address" do
    subject { MailParser::Message.new(@stdout_string).header.raw('to').map(&:chomp) }

    describe "1 To address doesn't change" do
      let(:stdin_str) do
        <<~EOF
        To: #{test_address}
        Subject: Test subject
        Content-type: text/plain
        
        Test body
        EOF
      end

      it { is_expected.to eq [test_address] }
    end

    describe "2 To addresses changes to 1 dummy address" do
      let(:stdin_str) do
        <<~EOF
        To: #{test_address}, #{test_address_2}
        Subject: Test subject
        Content-type: text/plain
        
        Test body
        EOF
      end

      it { is_expected.to eq [DUMMY_MAIL_TO] }
    end

    describe "1 To address and 1 CC address change to 1 dummy address" do
      let(:stdin_str) do
        <<~EOF
        To: #{test_address}
        Cc: #{test_address_2}
        Subject: Test subject
        Content-type: text/plain
        
        Test body
        EOF
      end

      it { is_expected.to eq [DUMMY_MAIL_TO] }
    end
  end

  describe "Cc address" do
    let(:stdin_str) do
      <<~EOF
      To: #{test_address}
      Cc: #{test_address_2}
      Subject: Test subject
      Content-type: text/plain
      
      Test body
      EOF
    end

    it { expect(MailParser::Message.new(@stdout_string).header['cc']).to be_nil }
  end
end
