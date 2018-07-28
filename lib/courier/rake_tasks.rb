task :proto do
  sh 'protoc --ruby_out=. --twirp_ruby_out=. --doc_out=doc/ --doc_opt=html,index.html app/service/service.proto'
end
