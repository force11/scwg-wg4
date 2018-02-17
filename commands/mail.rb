# frozen_string_literal: true

usage 'mail [options] mail_path'
aliases :m
summary 'send a message via SMTP'
optional :u, :username, 'the username of the mail account used to send the mail', default: 'admin'

class Mail < ::Nanoc::CLI::CommandRunner

  def run
    require 'net/smtp'
    require 'socket'

    @config = Nanoc::Int::ConfigLoader.new.new_from_cwd

    # Extract arguments
    if arguments.length != 1
      raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
    end
    mail_path = arguments[0]

    if !File.exist?(mail_path)
      raise(
        Nanoc::Int::Errors::GenericTrivial,
        "The mail was not sent because '#{mail_path}' was not found."
      )
    end

    mail_message = File.read(mail_path)

    from_address = @config[:mail][:from][/<(?<address>.*)>/, 'address']
    to_address = @config[:mail][:to][/<(?<address>.*)>/, 'address']

    username = options[:username]
    $stderr.puts "Enter the password for #{username}:"
    password = $stdin.gets.chomp

    smtp = Net::SMTP.new(@config[:mail][:server], @config[:mail][:port])
    smtp.enable_starttls_auto
    smtp.set_debug_output($stderr) if debug?
    smtp.start(Socket.gethostname, username, password) do |service|
      service.send_message(mail_message, from_address, to_address)
    end

    $stderr.puts "Mail sent successfully to #{@config[:mail][:to]}"
  end
end

runner Mail
