Date::stringify = ->
    date = @getDate()
    month = @getMonth() + 1
    year = @getFullYear()
    "#{year}-#{month.addLeadingZero 2}-#{date.addLeadingZero 2}"

String::parse = ->
    dateArray = @split "-"
    date = new Date +dateArray[0], +dateArray[1] - 1, +dateArray[2]
    if +date then date else null

String::capitalize = ->
    @[0].toUpperCase() + @substr(1)

Number::addLeadingZero = (digitCount) ->
    numberString = @toString()
    zeroCount = if digitCount - numberString.length > 0 then digitCount - numberString.length else 0
    new Array(zeroCount + 1).join("0") + numberString

_.templ = (str, data) ->
    _.template str.replace /<%\s*include\s*(.*?)\s*%>/g, (match, templateSelector) ->
        template = $(templateSelector).first().html()
        template or ""
    , data
