{CompositeDisposable} = require 'atom'
helpers = require('atom-linter')

module.exports =
  config:
    executablePath:
      type: 'string'
      title: 'harbour Executable'
      default: 'harbour' # Let OS's $PATH handle the rest

  _testBin: ->
    title = 'linter-harbour: Unable to determine PHP version'
    message = 'Unable to determine the version of "' + @executablePath +
      '", please verify that this is the right path to harbour.'
    try
      helpers.exec(@executablePath, ['--version']).then (output) =>
        regex = /Harbour (\d+)\.(\d+)\.(\d+)/g
        if not regex.exec(output)
          atom.notifications.addError(title, {detail: message})
          @executablePath = ''
      .catch (e) ->
        console.log e
        atom.notifications.addError(title, {detail: message})

  activate: ->
    require('atom-package-deps').install()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-harbour.executablePath',
      (executablePath) =>
        @executablePath = executablePath
        @_testBin()

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      name: 'harbour'
      grammarScopes: [ 'source.harbour', 'source.hb' ]
      scope: 'file'
      lintOnFly: false
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        command = @executablePath
        return Promise.resolve([]) unless command?
        parameters = []
        parameters.push('-n -s -w3 -es1 -q0')
        text = textEditor.getText()
        return helpers.exec(command, parameters, {stdin: text}).then (output) ->
          regex = /\\((?<line>\\d+)\\) ((?<error>Error)|(?<warning>Warning)) ((?<message>.+))[\\n\\r]/g
          messages = []
          while((match = regex.exec(output)) isnt null)
            messages.push
              type: "Error"
              filePath: filePath
              range: helpers.rangeFromLineNumber(textEditor, match[2] - 1)
              text: match[1]
          messages
