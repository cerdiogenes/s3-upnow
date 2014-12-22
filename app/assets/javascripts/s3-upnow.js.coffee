$(document).on 'change', (e) ->
  input = $(e.target)
  if (input.prop('tagName') == "INPUT" && input.prop('type') == "file" && input.data('upnow'))
    return if (!input.prop('files'))
    file = input.prop('files')[0]
    file.unique_id = Math.random().toString(36).substr(2,16)

    dispatchEvent = (name, detail) ->
      ev = document.createEvent('CustomEvent')
      ev.initCustomEvent(name, true, false, detail)
      input[0].dispatchEvent(ev)

    if (file)
      url = input.data('url')
      fields = input.data('fields')

      data = new FormData()

      if (fields)
        Object.keys(fields).forEach (key) ->
          if key == 'key'
            fields[key] = fields[key]
              .replace('{timestamp}', new Date().getTime())
              .replace('{unique_id}', file.unique_id)
          data.append(key, fields[key])
      data.append('file', file)

      xhr = new XMLHttpRequest()
      xhr.addEventListener('load', (e) ->
        input.removeClass('uploading')
        dispatchEvent('upload:complete', xhr.response)
        if ((xhr.status >= 200 && xhr.status < 300) || xhr.status == 304)
          key = input.data('key') || $(xhr.response).find('Key').text()
          input.prev().val(key)
          input.removeAttr('name')
          dispatchEvent('upload:success', xhr.response)
        else
          dispatchEvent('upload:failure', xhr.response)
      )

      xhr.upload.addEventListener('progress', (e) ->
        dispatchEvent('upload:progress', e) if (e.lengthComputable)
      )

      xhr.open('POST', url, true)
      xhr.send(data)

      input.addClass('uploading')
      dispatchEvent('upload:start')