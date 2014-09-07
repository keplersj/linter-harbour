activate = ->
  console.log 'activate linter-harbour'

module.exports =
  configDefaults:
    harbourExecutablePath: null
    harbourOptions: '-n -s -w3 -es1 -q0'
    harbourIncludes: null
  activate: activate
