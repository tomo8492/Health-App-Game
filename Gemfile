# Gemfile
# VITA CITY — Fastlane 依存関係管理
# 使用方法: bundle install → bundle exec fastlane <lane>

source "https://rubygems.org"

gem "fastlane", "~> 2.220"

plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
