# coding: utf-8
require 'active_support/core_ext'
require 'pp'
require 'openssl'
require 'pry'
require 'hashie'
require 'pony'
require 'cinch'

$setting = Hashie::Mash.new(YAML.load(ARGF))
$levels = {}

class HagureMetalAppeared
  include Cinch::Plugin

  listen_to :join
  def listen(m)
    return unless m.user.nick == $setting.irc.nick
    Channel($setting.irc.channels.first).notice "はぐれメタルがあらわれた！"
  end
end

class HagureMetalEscaped
  include Cinch::Plugin

  timer $setting.timeout, method: :quit
  def quit
    bot.quit 'はぐれメタルはにげだした！'
  end
end

class HagureMetalDamaged
  include Cinch::Plugin

  def initialize(*args)
    @hp = 5
    @attackers = []
    super
  end

  listen_to :privmsg
  def listen(m)
    return unless m.message.include?($setting.irc.nick)
    if @attackers.last != m.user.nick && @hp > 0
      Channel($setting.irc.channels.first).notice "#{m.user.nick}のこうげき！　はぐれメタルに１のダメージ！"
      @hp -= 1
      @attackers << m.user.nick
      if @hp <= 0
        Channel($setting.irc.channels.first).notice 'はぐれメタルをやっつけた！'
        @attackers.uniq.each do |attacker|
          $levels[attacker] = $levels[attacker].to_i + 1
          Channel($setting.irc.channels.first).notice "#{attacker}のレベルが#{$levels[attacker]}にあがった！"
        end
        sleep(10)
        bot.quit
      end
    else
      Channel($setting.irc.channels.first).notice "#{m.user.nick}のこうげき！　ミス！"
    end
  end
end

loop do
  cinch = Cinch::Bot.new do
    configure do |c|
      c.server = $setting.irc.server
      c.port = $setting.irc.port
      c.secure = $setting.irc.secure
      c.ssl.use = $setting.irc.ssl_use
      c.user = $setting.irc.user
      c.nick = $setting.irc.nick
      c.realname = $setting.irc.realname
      c.password = $setting.irc.password
      c.channels = $setting.irc.channels
      c.plugins.plugins = [HagureMetalAppeared, HagureMetalEscaped, HagureMetalDamaged]
    end
  end

  cinch.start

  sleep $setting.average_interval * 2 * rand
end
