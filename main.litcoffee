# ![logo](https://solsort.com/_logo.png) "Vores fart" (danish for "our speed")

Visualisation of speeding measurements.

## Todo

- find ud af de præcise detaljer hvilket gennemsnit etc. der skal bruges, ie. er der outliers der skal prunes, eller lignende?
- tooltip over bars
- tekst for måned i dato
- hover-effect
- konkurrencepladser i bunden, ved hvilket vejarbejde overholdes hastighedsbegrænsningen bedst?
- styling
- flytte backenden over i php, - send mail med spec til arni
- typen der sendes med til webserviceUrl'en skal sikres at være den rigtige. Forøjeblikket sendes typen 0.
- ie. support
- extract such that it is easy to integrate


## Configuration

Speed limit

    speedLimit = 50

Data url for the web service we use:

    webserviceUrl = (unitId, start, end, type) ->
        "http://fartviser.dk/fartviser/fvdownload.php?unit_id=#{unitId}&" +
        "datestart=#{danishDate(start)}&hourstart=#{start.getHours()}&" +
        "dateend=#{danishDate(end)}&hourend=#{end.getHours()}&type=#{type}"

Unit ids

    unitIds =
        37: "Motorring 4"
        101: "Kolding V"
        111: "Vilsundbroen"

Visualisation parameters, telling where on the screen the dynamic elements are placed

    barWidth = 100
    barX = 100
    barY = 7 
    barSpacing = 220
    lineHeight = 16

## Server

    if Meteor.isServer 

Serverside method that returns statistics for the last 24 hours. Result is just a json object of objects of objects, accessible like `obj[unitId][datehour].property`, wher unitId is an key as defined above (ie. 37 for "Moterring 4"), datehour is a string containing the date and hour, and property may be `avgSpeed`, `offenders` etc.

Currently implemented as a Meteor RPC-call, but could just be http server returning the result based on current time.

Current speeding statistics cached for performance, - this is recalculated every hour.

        speedingStat = undefined


Function for recalculating the speeding statistics

        updateStat = ->

calculating statistics for 24 hour.

            endTime = Date.now()
            startTime = endTime - millisecondsPerDay


The stat is split up according to different unit ids

            result = {}
            for id, name of unitIds

where we just get data from the web service and process the result.

                data = Meteor.http.get webserviceUrl(id, new Date(startTime), new Date(endTime), 0) # see TODO above
                result[id] = processData(id, line.split "\t" for line in (data.content.split "\r\n").slice(1) if data.content)

            speedingStat = result
            console.log result
            console.log "updated speeding stat"

Processing the data 

        processData = (id, data) ->
            stat = {}
            for line in data
                [datetime, lane, speed, length, type, gap, wrong_dir, display, flash] = line
                datehour = datetime.slice(0, -6)

If we want to ignore certain entries, ie. outliers or similar, we can add the condition here. Also ignore entries with date missing.

                if not datehour then continue

For doing the statistics, we just extract the speeds

                stat[datehour] = [] if not stat[datehour]
                stat[datehour].push +speed

and then calculate average, and other key numbers

            for datehour, speeds of stat
                stat[datehour] = 
                    id: id
                    datehour: datehour
                    avgSpeed: avg(speeds)
                    offenders: speeds.filter((a)-> a>speedLimit).length / speeds.length
            stat

        Meteor.startup updateStat
        Meteor.startup ->
            setTimeout updateStat, millisecondsPerHour

Result is supplied to client via a meteor remote function, - just sending the speeding stat. Could be replaced with a simple http-call on server and client.

        Meteor.methods
            getData: (callback) -> speedingStat

## Visualisation

### Meteor code

This is the only Meteor dependend client code:

    if Meteor.isClient 

`getData` could be replaced with a function that get the data from a webservice, instead of doing an RPC. Ie. via `$.ajax(..)` or similar.

        getData = (callback) -> Meteor.call "getData", callback 

This could just be replaced with `$(...)`.

        Meteor.startup ->

### Startup

Get the data, and visualise it :)

            getData (err, data) -> 
                if err then throw err
                visualise data

### Actual visualisation code

        visualise = (data) ->
            $visualisation = $ "#visualisation"
 
Find the label/indexed of the data, sorted descending.

            datahours = {}
            for id, hours of data
                for datahour of hours
                    datahours[datahour] = true
            datahours = (key for key of datahours).sort().reverse()

Run through the data and unitIds, and draw bars. Keep track of coordinates, and place absolutely.

            y = 0
            for datehour in datahours
                addTitle $visualisation, datehour, 0, y
                x = barX
                for id of unitIds
                    addBar $visualisation, data[id][datehour], x, y
                    x += barSpacing
                y += lineHeight

Create an place label for each set of bars

        addTitle = ($root, title, x, y) ->
            text = title.slice(-2) + ":00"
            date = " " + title.slice(5, -3)
            text = text + date if y is 0
            text = text + date if text is "23:00"
            $label = ($ '<div class="label">').text(text)
            $label.css
                left: x
                top: y
            $root.append $label

The bar contains of three parts, a blue box, an orange box, and a line annotating the average.
Create those elements for the and add them to the root element

        addBar = ($root, item, x, y) ->

            $blueBox = $ '<div class="bar ok">'
            $blueBox.css
                left: x + item.offenders * barWidth
                top: y + barY
                width: barWidth * (1-item.offenders)
            $root.append $blueBox

            $orangeBox= $ '<div class="bar offenders">'
            $orangeBox.css
                left: x + barWidth
                top: y + barY
                width: barWidth * item.offenders
            $root.append $orangeBox

            $avgLine = $ '<div class="speedLine">'
            $avgLine.css
                left: x + item.avgSpeed / speedLimit * barWidth
                top: y + barY
            $root.append $avgLine

            addHover $root, item, [$blueBox, $orangeBox, $avgLine]

        hoverDepth = 0;
        showHover = (item) ->
            console.log "showhover"
        hideHover = (item) ->
            console.log "hidehover"

        addHover = ($root, item, elems) ->
            for $elem in elems
                $elem.on "mouseover", -> showHover(item)
                $elem.on "mouseout", -> hideHover(item)



## Utility

Utility function formatting a date in danish, this is used for making the data url

    danishDate = (date) ->
        "#{date.getDate()}/#{date.getMonth()+1}-#{date.getFullYear()}"

Constant for readability of code

    millisecondsPerHour = 60*60*1000
    millisecondsPerDay = 24*millisecondsPerHour

Utility for finding the average

    avg = (list) -> list.reduce(((a,b)->a+b), 0) / list.length

