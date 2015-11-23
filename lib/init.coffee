activate = ->
  console.log 'activate linter-harbour'

module.exports =
  config:
    harbourExe:
      title: 'EXE harbour'
      description: 'c:\harbour\bin\harbour.exe or /opt/harbour/bin/harbour'
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
      title: 'harbour compiler options'
      description: 'e.g. /usr/local/include/harbour'
      default: ''
      type: 'string'
      order: 3
  activate: activate
