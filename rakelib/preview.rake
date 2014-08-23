
task :preview do
  system 'ruby -run -e httpd output -p 3000'
end
