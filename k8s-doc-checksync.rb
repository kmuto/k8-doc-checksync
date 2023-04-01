#!/usr/bin/env ruby
# Copyright 2023 Kenshi Muto
require 'git'

language = ARGV[1] || 'ja'
upstream_branch =  'main'

Git.configure do |config|
  # config.git_ssh = '/path/to/ssh/script'
end

class MyGitError < Exception
end

def log(s)
  STDERR.puts s unless ENV['QUIET']
end

def update_upstream(g, upstream_branch)
  log("Fetching #{upstream_branch}...")
  begin
    g.pull
  rescue Git::GitExecuteError => e
    raise MyGitError.new("Missing branch #{upstream_branch} or something wrong. #{e.message.to_s}")
  end
end

def check_upstream(g, upstream_branch)
  gitlog = g.gblob(upstream_branch).log.first
  log("Newest commit of #{upstream_branch} is #{gitlog.sha[0..8]} at #{gitlog.date}")
end

def check_workdir(dir, translated_name)
  if !File.exist?(File.join(dir, 'content', 'en')) || !File.exist?(File.join(dir, 'content', translated_name))
    raise MyGitError.new('Missing content folders at current place')
  end
end

def get_filelist(g, dir, max_count: 10000)
  files = {}
  log("Scanning #{dir}... (It takes a time)")
  count = 0
  Dir.chdir(dir) do
    Dir.glob(['**/*.md', '**/*.yaml', '**/*.json', '**/*.go', '**/*.js', '**/Dockerfile']).each do |entry|
      begin
        files[entry] = g.gblob(entry).log.first.date
      rescue MyGitError => e
        files[entry] = "! #{e.message}"
      end
      count += 1
      if count == max_count
        break
      end
    end
  end
  files
end

def compare_files(origin: {}, translated: {})
  report = []
  checked = {}
  origin.keys.sort.each do |k|
    if translated[k]
      if origin[k] <= translated[k]
        report << {name: k, origin_at: origin[k], translated_at: translated[k], status: 'OK'}
      else
        report << {name: k, origin_at: origin[k], translated_at: translated[k], status: 'BEHIND'}
      end
      checked[k] = true
    else
      report << {name: k, origin_at: origin[k], translated_at: nil, status: 'UNTRANSLATED'}
      checked[k] = true
    end
  end

  translated.keys.each do |k|
    next if checked[k]
      report << {name: k, origin_at: nil, translated_at: translated[k], status: 'MISSINGORIGIN'}
  end

  report
end

def report_html(report, webbase: 'https://kubernetes.io', gitbase: 'https://github.com/kubernetes/website/tree/main/content', originname: 'en', translatedname: 'ja', messages: '')
  return <<EOT
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Translation status: #{originname} -&gt; #{translatedname}</title>
<link rel="stylesheet" href="checksync.css" tyle="text/css">
</head>
<body>
<h1>Translation status: #{originname} -&gt; #{translatedname}</h1>

#{messages}

<div class="table">
<table>
<tr class="header"><th>Status</th><th>Filename</th><th>Origin</th><th>Translated</th></tr>
#{each_tr(report, gitbase: gitbase, originname: originname, translatedname: translatedname)}
</table>
</div>
<address>Updated at #{Time.now}</address>
</body>
</html>
EOT
end

def each_tr(report, webbase: 'https://kubernetes.io', gitbase: 'https://github.com/kubernetes/website/tree/main/content', originname: 'en', translatedname: 'ja')
  ret = []

  report.each do |r|
    case r[:status]
    when 'OK'
      ret << %Q(<tr><td class="uptodate">up to date</td><td><a href="#{webbase}/#{r[:name].sub('.md', '')}" target="checksyncweb">#{r[:name]}</td><td><a href="#{gitbase}/#{originname}/#{r[:name]}" target="checksyncgit">#{r[:origin_at]}</a></td><td><a href="#{gitbase}/#{translatedname}/#{r[:name]}" target="checksyncgit">#{r[:translated_at]}</a></td></tr>)
    when 'BEHIND'
      ret << %Q(<tr><td class="behind#{days_range(r[:origin_at], r[:translated_at])}">behind</td><td><a href="#{webbase}/#{r[:name].sub('.md', '')}" target="checksyncweb">#{r[:name]}</a></td><td><a href="#{gitbase}/#{originname}/#{r[:name]}" target="checksyncgit">#{r[:origin_at]}</a></td><td><a href="#{gitbase}/#{translatedname}/#{r[:name]}" target="checksyncgit">#{r[:translated_at]}</a></td></tr>)
    when 'UNTRANSLATED'
      ret << %Q(<tr><td class="untranslated">untranslated</td><td><a href="#{webbase}/#{r[:name].sub('.md', '')}" target="checksyncweb">#{r[:name]}</a></td><td><a href="#{gitbase}/#{originname}/#{r[:name]}" target="checksyncgit">#{r[:origin_at]}</a></td><td>-</td></tr>)
    when 'MISSINGORIGIN'
      ret << %Q(<tr><td class="missing">missing</td><td><a href="#{webbase}/#{translatedname}/#{r[:name].sub('.md', '')}" target="checksyncweb">#{r[:name]}</a></td><td>-</td><td><a href="#{gitbase}/#{translatedname}/#{r[:name]}" target="checksyncgit">#{r[:translated_at]}</a></td></tr>)
    end
  end
  ret.join("\n")
end

def days_range(origin_at, translated_at)
  oneday = 24 * 60 * 60
  if origin_at - (oneday * 365) > translated_at
    '365'
  elsif origin_at - (oneday * 180) > translated_at
    '180'
  elsif origin_at - (oneday * 90) > translated_at
    '90'
  elsif origin_at - (oneday * 30) > translated_at
    '30'
  elsif origin_at - (oneday * 14) > translated_at
    '14'
  else
    '1'
  end
end

begin
  g = Git.open(ARGV[0])
rescue ArgumentError
  log('Current folder seems not Git repository. Aborted.')
  exit 1
end

begin
  update_upstream(g, upstream_branch) unless ENV['SKIP_PULL']
  check_upstream(g, upstream_branch)
  check_workdir(ARGV[0], language)

  en = get_filelist(g, File.join(ARGV[0], 'content', 'en'), max_count: 10000)
  translated = get_filelist(g, File.join(ARGV[0], 'content', language), max_count: 10000)

  report =compare_files(origin: en, translated: translated)
  puts report_html(report,
                   webbase: 'https://kubernetes.io',
                   gitbase: 'https://github.com/kubernetes/website/tree/main/content',
                   originname: 'en', translatedname: language,
                   messages: %Q(<p>Translation may be in progress. Please check the <a href="https://github.com/kubernetes/website/issues" target="checksyncweb">GitHub issue</a> before working on it.</p>))
rescue MyGitError => e
  log("Error: #{e.message}")
  exit 1
end
