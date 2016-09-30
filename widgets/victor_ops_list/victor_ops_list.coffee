class Dashing.VictorOpsList extends Dashing.Widget
  ready: ->
    if @get('unordered')
      $(@node).find('ol').remove()
    else
      $(@node).find('ul').remove()

  color: ->
    data = @get('items')
    # Find out if there's unacked incidents
    worst = data.reduce @worstReduce, null
    switch worst
      when 'TRIGGERED' then '#ff0000'
      when 'ACKED' then '#ffff00'
      else '#33cc33'

  onData: (data) ->
    $(@get('node')).css 'background-color', @color()

  worstReduce: (memo, curr) ->
    console.dir(curr)
    if curr['phase'] == 'TRIGGERED'
      'TRIGGERED'
    else if curr['phase'] == 'ACKED' && memo != 'TRIGGERED'
      'ACKED'
    else
      null

