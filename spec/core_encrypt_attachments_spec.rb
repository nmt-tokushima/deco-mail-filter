require 'spec_helper'

RSpec.describe "DecoMailFilter::Core" do
  describe "#work" do
    describe "Attachment files when encrypt attachment is enabled" do
      let(:filename) { 'mail-1-attachment.txt' }
      let(:mail_before) { read_mail filename }
      let(:mail_before_parsed) { MailParser::Message.new mail_before }
      let(:config) { DecoMailFilter::Config.new attachments_encryption: true }
      let(:filter) { DecoMailFilter::Core.new config: config }
      let(:mail_after) { filter.work mail_before }
      let(:mail_after_parsed) { MailParser::Message.new mail_after }
      let(:password) { Passgen::generate symbols: true }

      before do
        allow(DecoMailFilter::Utils).to receive(:generate_password).and_return(password)
        @tmp_dir = Dir.mktmpdir
        filter.write_attachments mail_after_parsed, @tmp_dir
        @zippath = File.join @tmp_dir, 'attachments.zip'
      end

      after do
        FileUtils.rm_rf @tmp_dir
      end

      subject { DecoMailFilter::Utils.zipfile_encrypted? @zippath }

      it { is_expected.to eq true }

      describe "extracted file contains a correct file" do
        before do
          @extract_tmp_dir = Dir.mktmpdir
          DecoMailFilter::Utils.extract_zip_file @zippath, @extract_tmp_dir, password: password
        end

        after do
          FileUtils.rm_rf @extract_tmp_dir
        end

        it { expect(File.exist? File.join(@extract_tmp_dir, 'test.zip')).to eq true }
      end

      context "2 attachment files" do
        let(:filename) { 'mail-2-attachment.txt' }
        it { is_expected.to eq true }

        describe "extracted file contains a correct file" do
          before do
            @extract_tmp_dir = Dir.mktmpdir
            DecoMailFilter::Utils.extract_zip_file @zippath, @extract_tmp_dir, password: password
          end

          after do
            FileUtils.rm_rf @extract_tmp_dir
          end

          it { expect(File.exist? File.join(@extract_tmp_dir, 'test.txt')).to eq true }
          it { expect(File.exist? File.join(@extract_tmp_dir, 'test.zip')).to eq true }
        end
      end

      context "SJIS text file" do
        let(:filename) { 'mail-sjis-attachment.txt' }
        it { is_expected.to eq true }

        describe "keep SJIS" do
          before do
            @extract_tmp_dir = Dir.mktmpdir
            DecoMailFilter::Utils.extract_zip_file @zippath, @extract_tmp_dir, password: password
          end

          after do
            FileUtils.rm_rf @extract_tmp_dir
          end

          it do
            md5_before = Digest::MD5.file(File.join(__dir__, 'test-ja-sjis.txt'))
            md5_after  = Digest::MD5.file(File.join(@extract_tmp_dir, 'test-ja-sjis.txt'))
            expect(md5_after).to eq md5_before
          end
        end
      end

      context "multipart/alternative" do
        let(:filename) { 'mail-html-1-attachment.txt' }
        it { is_expected.to eq true }

        describe "content-type (type and subtype)" do
          let(:content_type_after) { mail_after_parsed.header['content-type'].first }
          let(:content_type_before) { mail_before_parsed.header['content-type'].first }

          it { expect(content_type_before.type).to eq 'multipart' }
          it { expect(content_type_before.subtype).to eq 'mixed' }
          it { expect(content_type_after.type).to eq content_type_before.type }
          it { expect(content_type_after.subtype).to eq content_type_before.subtype }
        end

        describe "extracted file contains a correct file" do
          before do
            @extract_tmp_dir = Dir.mktmpdir
            DecoMailFilter::Utils.extract_zip_file @zippath, @extract_tmp_dir, password: password
          end

          after do
            FileUtils.rm_rf @extract_tmp_dir
          end

          it { expect(File.exist? File.join(@extract_tmp_dir, 'test.zip')).to eq true }
        end

        describe "first parts are same" do
          subject { mail_after_parsed.part.first }
          let(:first_part_before) { mail_before_parsed.part.first }

          it { expect(subject.multipart?).to eq true }

          it { expect(subject.part[0].body).to eq first_part_before.part[0].body }
          it { expect(subject.part[1].body).to eq first_part_before.part[1].body }

          # NOTE: Their headers are not same completely so the following tests fail.
          # it { expect(subject.part[0].header).to eq first_part_before.part[0].header }
          # it { expect(subject.part[1].header).to eq first_part_before.part[1].header }
          # NOTE: They are same partially.
          it { expect(subject.part[0].header['content-type'].first.type).to                   eq first_part_before.part[0].header['content-type'].first.type }
          it { expect(subject.part[0].header['content-type'].first.subtype).to                eq first_part_before.part[0].header['content-type'].first.subtype }
          it { expect(subject.part[0].header['content-transfer-encoding'].first.mechanism).to eq first_part_before.part[0].header['content-transfer-encoding'].first.mechanism }
          it { expect(subject.part[1].header['content-type'].first.type).to                   eq first_part_before.part[1].header['content-type'].first.type }
          it { expect(subject.part[1].header['content-type'].first.subtype).to                eq first_part_before.part[1].header['content-type'].first.subtype }
          it { expect(subject.part[1].header['content-transfer-encoding'].first.mechanism).to eq first_part_before.part[1].header['content-transfer-encoding'].first.mechanism }
        end
      end

      describe 'keep encoding' do
        let(:filename) { 'mail-no-alternative-sjis-attachment.txt' }

        it 'assertion' do
          expect(mail_before_parsed.part.first.header['content-type'].first.raw =~ /ISO-2022-JP/).to be_truthy
        end

        it 'contains "iso-2022-jp"' do
          expect(mail_after_parsed.part.first.header['content-type'].first.raw =~ /iso-2022-jp/).to be_truthy
        end
      end
    end

    describe 'Encoding::CompatibilityError' do
      let(:mail_before) { read_mail filename }
      let(:config) { DecoMailFilter::Config.new attachments_encryption: true }
      let(:filter) { DecoMailFilter::Core.new config: config }

      describe '2-2-16' do
        let(:filename) { '2-2-16.txt' }
        it { expect { filter.work mail_before }.not_to raise_error }
      end

      describe '2-2-17' do
        let(:filename) { '2-2-17.txt' }
        it { expect { filter.work mail_before }.not_to raise_error }
      end

      describe '3-2-16' do
        let(:filename) { '3-2-16.txt' }
        it { pending; expect { filter.work mail_before }.not_to raise_error }
      end

      describe '3-2-17' do
        let(:filename) { '3-2-17.txt' }
        it { pending; expect { filter.work mail_before }.not_to raise_error }
      end
    end
  end
end
