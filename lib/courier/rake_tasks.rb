task :proto do
  sh 'protoc --ruby_out=. --twirp_ruby_out=. --doc_out=doc/ --doc_opt=html,index.html app/service/*.proto'

  project = File.basename(Dir.pwd)
  gem_dir = project.tr('-', '/')
  if Dir.exist? 'client'
    dest = "client/lib/#{gem_dir}"
    mkdir_p dest
    cp Dir['app/service/*.proto'], dest
    cp Dir['app/service/*.rb'], dest
  end
end
