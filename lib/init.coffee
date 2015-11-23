activate = ->
  console.log 'activate linter-harbour'

module.exports =
  config:
    harbourExecutablePath: ''
    harbourOptions: '-n -s -w3 -es1 -q0'
    harbourIncludes: ''
  activate: activate
