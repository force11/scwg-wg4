# frozen_string_literal: true

usage 'mail-invite [options] mail_path'
aliases :mail_invite, :mi
summary 'send a meeting invite via SMTP'
optional :u, :username, 'the username of the mail account used to send the mail'

class MailInvite < ::Nanoc::CLI::CommandRunner

  def run
    require 'net/smtp'
    require 'socket'
    require 'etc'
    require 'fileutils'

    @config = Nanoc::Int::ConfigLoader.new.new_from_cwd

    # Extract arguments
    if arguments.length != 1
      raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
    end

    mail_path = arguments[0]
    if !File.exist?(mail_path)
      raise(
        Nanoc::Int::Errors::GenericTrivial,
        "The invite was not sent because '#{mail_path}' was not found."
      )
    end

    output_dir = @config[:output_dir]
    if !File.fnmatch?("#{output_dir}/meetings/*/*.mail", mail_path)
      raise(
        Nanoc::Int::Errors::GenericTrivial,
        "The invite was not sent because '#{mail_path}' is not found under " \
        'the output directory or is not a mail file.'
      )
    end

    content_dir = @config[:data_sources][0][:content_dir]
    sent_mail_path = mail_path.sub(output_dir, content_dir)
    if File.exist?(sent_mail_path)
      raise Nanoc::Int::Errors::GenericTrivial, 'The invite was already sent.'
    end

    # Setup notifications
    Nanoc::Int::NotificationCenter.on(:file_created) do |file_path|
      Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
    end

    mail_message = File.read(mail_path)

    from_address = @config[:mail][:from][/<(?<address>.*)>/, 'address']
    to_address = @config[:mail][:to][/<(?<address>.*)>/, 'address']

    username = options[:username] || Etc.getlogin
    $stderr.puts "Enter the password for #{username}:"
    password = $stdin.gets.chomp

    mail_server = @config[:mail][:server]
    mail_port = @config[:mail][:port]

    $stderr.print "Sending mail via #{mail_server}:#{mail_port} to #{to_address}… "

    smtp = Net::SMTP.new(mail_server, mail_port)
    smtp.enable_starttls_auto
    smtp.set_debug_output($stderr) if debug?
    smtp.start(Socket.gethostname, username, password) do |service|
      service.send_message(mail_message, from_address, to_address)
    end

    $stderr.puts 'done'

    write(sent_mail_path, mail_message)
  end

  private

  def write(filename, content)
    File.write(filename, content)
    Nanoc::Int::NotificationCenter.post(:file_created, filename)
  end
end

runner MailInvite
