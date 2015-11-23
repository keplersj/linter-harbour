{CompositeDisposable} = require 'atom'
{exec, tempFile} = helpers = require('atom-linter')
path = require 'path'

module.exports =
  config:
    additionalArguments:
      title: 'Additional Arguments for harbour compiler'
      type: 'string'
      default: '-w3 -es1'
    executablePath:
      type: 'string'
      title: 'harbour compiler Executable'
      default: 'harbour'

  _testBin: ->
    title = 'linter-harbour: Unable to determine PHP version'
    message = 'Unable to determine the version of "' + @executablePath +
      '", please verify that this is the right path to harbour.'
    try
      helpers.exec(@executablePath, ['--version']).then (output) =>
        # Harbour 3.2.0dev (r1408271619)
        regex = /Harbour (\d+.*) /g
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
        cwd = path.dirname(filePath)
        command = @executablePath
        return Promise.resolve([]) unless command?
        parameters = []
        parameters.push('-n', '-s', )
        text = textEditor.getText()

        tempFile path.basename(filePath), text, (tmpFilePath) =>
          params = [
            tmpFilePath,
            '-n',
            '-s',
            '-q0',
            @additionalArguments.split(' ')...
          ].filter((e) -> e)
          return exec(command, params, {stream: 'stderr', cwd: cwd}).then (output) ->
            # test.prg(3) Error E0030  Syntax error "syntax error at '?'"
            # test.prg(8) Error E0020  Incomplete statement or unbalanced delimiters
            regex = /([\w\.]+)\((\d+)\) (Error|Warning) ([\w\d]+) (.+)/g
            messages = []
            console.log 'output:', output
            while((match = regex.exec(output)) isnt null)
              messages.push
                type: match[3]
                filePath: filePath
                range: helpers.rangeFromLineNumber(textEditor, match[1] - 1)
                text: match[4]
            messages
