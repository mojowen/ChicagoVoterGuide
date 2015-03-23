require 'csv'
require 'fileutils'
require 'json'
require 'webrick'

load 'controller.rb'

task :serve do
    port = ARGV[1] || 8080
    server = WEBrick::HTTPServer.new(:Port => port, :DocumentRoot => Dir.pwd)
    trap('INT') { server.shutdown }
    server.start
end

task :mayors do
    mayors, _ = mayor_data

    markdown = [[]]

    mayors.first.keys.each do |key|
        markdown.first.push(key.to_s.capitalize)
    end

    markdown.push(Array.new(mayors.first.keys.length,'---'))
    mayors.each do |mayor|
        markdown.push([])
        mayor.each do |k,v|
            if k == "photo"
                markdown.last.push("![](#{v})")
            else
                markdown.last.push(v.respond_to?('join') ? v.join(',') : v)
            end
        end
    end

    File.open('mayors.md','w') do |fl|
        fl.write(markdown.map{ |r| "|#{r.join('|')}|" }.join("\n"))
    end
end

task :alderpeople do
    alderpeople = []
    CSV.foreach("data/alderpeople.csv",
                :headers => true) do |row|
         alderpeople.push Hash[row.headers.map(&:downcase).zip(row.fields.map)]
    end
    File.open('data/alderpeople.json','w') do |fl|
        fl.write(alderpeople.to_json)
    end
    Rake::Task["all"]
end

task :erb, :paths do |t,args|
    """
    Rebuild HTML pages.
    """

    controller = Controller.new()

    args.paths.each do |path|
        new_file = path.gsub('.erb','')
        function_name = path.split('.').first

        puts "Rewriting #{new_file}"

        File.open(new_file, 'w') do |fl|
            controller.send(function_name) if controller.respond_to?(function_name)
            fl.write(controller.render(path))
        end
    end
end

task :all do
    """
    Rebuild all the HTML pages.
    """
    Rake::Task["erb"].invoke(Dir.glob("*.html.erb"))
    Rake::Task["sharing"].invoke()
end

task :sharing do
    mayors, _ = mayor_data()

    build = {
        'mayor' => mayors,
        'alderman' => JSON::parse(File.read('data/alderpeople.json'))
    }


    FileUtils.rm_r 'sharing' if Dir.exists?("sharing")
    Dir.mkdir "sharing"

    build.each do |type, the_list|
        Dir.mkdir("sharing/#{type}") unless Dir.exists?("sharing/#{type}")

        the_list.each do |item|
            controller = Controller.new()
            controller.send(type, item)
            puts "Creating #{controller.filename}"
            File.open("sharing/#{controller.filename}.html", 'w') do |fl|
                fl.write(controller.render('sharing.erb'))
            end
        end
    end
end
