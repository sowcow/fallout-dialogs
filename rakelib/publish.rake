
task :publish do
  temp = Pathname '../very-temp-output'
  output = Pathname 'output'

  rm_rf temp
  mv output, temp
  system 'git checkout gh-pages'

  rm_rf Dir[?*]
  system 'git rm -rf .'
  cp_r Dir[output + '*'], '.'

  system 'git add -A'
  system 'git commit -m update'
  system 'git push origin gh-pages'

  system 'git checkout master'
  rm_rf temp
end
