activate = ->
  console.log 'activate linter-harbour'

module.exports =
  config:
    executablePath:
      title: 'path to harbour executable'
      description: 'c:\harbour\bin or /opt/harbour/bin'
      default: ''
      type: 'string'
      order: 1
    harbourOptions:
      title: 'harbour compiler options'
      description: 'e.g. -n -s -w3 -es1 -q0'
      default: '-n -s -w3 -es1 -q0'
      type: 'string'
      order: 2
    harbourIncludes:
      title: 'harbour include options'
      description: 'e.g. /usr/local/include/harbour'
      default: ''
      type: 'string'
      order: 3
  activate: activate
