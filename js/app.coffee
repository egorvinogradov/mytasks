class Tasks

    months: [
        "январь",
        "февраль",
        "март",
        "апрель",
        "май",
        "июнь",
        "июль",
        "сентябрь",
        "октябрь",
        "ноябрь",
        "декабрь"
    ]
    monthsInflected: [
        "января",
        "февраля",
        "марта",
        "апреля",
        "мая",
        "июня",
        "июля",
        "сентября",
        "октября",
        "ноября",
        "декабря"
    ]
    weekdays: [
        "воскресенье",
        "понедельник",
        "вторник",
        "среда",
        "четверг",
        "пятница",
        "суббота"
    ]

    LOCAL_STORAGE_TASKS_KEY: "mytasks.tasks"
    LOCAL_STORAGE_FIRST_USAGE_KEY: "mytasks.firstUsage"
    DAY_TIMESTAMP: 24 * 60 * 60 * 1000

    KEYS:
        ENTER: 13

    tasks: {}

    selectors:
        taskItem: ".tasks__item"
        taskStatus: ".tasks__status"
        taskStatusItem: ".tasks__status-item"
        taskText: ".tasks__text"
        taskEdit: ".tasks__edit"
        taskRemove: ".tasks__remove"
        textarea: ".tasks__textarea"
        textareaSpeech: ".tasks__textarea-speech"
        dayList: ".tasks__list"
        dayAdd: ".tasks__add-day"
        calendar: ".tasks__calendar"
        calendarShow: ".tasks__calendar-show"
        historyButton: ".tasks__history"

    classes:
        hidden: "g-hidden"
        editing: "tasks__text_editing form-control input-sm"

    templates: {}

    constructor: (container, templates) ->
        @container = $(container)

        for templateName, template of templates
            @templates[templateName] = $(template).html()

    initialize: ->

        try
            @tasks = JSON.parse(localStorage.getItem(@LOCAL_STORAGE_TASKS_KEY)) or {}

        @currentDate = @getCurrentDate()

        currentTasks = @tasks[@currentDate.stringify()]
        unless currentTasks
            currentTasks = @tasks[@currentDate.stringify()] = tasks: []

        try
            firstUsage = localStorage.getItem(@LOCAL_STORAGE_FIRST_USAGE_KEY).parse().getDate()
        catch e
            localStorage.setItem @LOCAL_STORAGE_FIRST_USAGE_KEY, new Date().stringify()

        @render currentTasks
        @selectElement @selectors, @, @container
        @bindTaskItemEvents()
        @bindDayListEvents()

    selectElement: (selectors, obj, container) ->
        for key, selector of selectors
            obj[key] = $(selector, container)

    render: (dayTasks) ->
        dateString = @humanizeDate @currentDate, true
        @container.html _.templ(@templates.container)(_.extend(currentDate: dateString, dayTasks))

    appendTask: (task) ->
        @dayList.append _.templ(@templates.item)(task: task)
        
    bindTaskItemEvents: ->
        
        @container.on "mousedown", (e) =>
            target = $(e.target)
            unless target.is(@selectors.taskText) and target.hasClass(@classes.editing)
                @disableEditing @container.find @selectors.taskText

        @container.delegate @selectors.taskText, "keydown", (e) =>
            textElement = $(e.currentTarget)
            taskElement = textElement.parent()
            if e.which is @KEYS.ENTER
                value = textElement.text().trim()
                timestamp = +new Date()
                id = taskElement.data "id"
                if value
                    taskElement.data "finish", timestamp
                    @updateTask id,
                        finish: timestamp
                        text: value
                else
                    @removeTask id
                    taskElement.remove()
                @disableEditing textElement
                e.preventDefault()
                
        @container.delegate @selectors.taskRemove, "click", (e) =>
            taskElement = $(e.currentTarget).parents @selectors.taskItem
            if confirm "Удалить?"
                @removeTask taskElement.data "id"
                taskElement.remove()

        @container.delegate @selectors.taskEdit, "click", (e) =>
            taskElement = $(e.currentTarget).parents @selectors.taskItem
            textElement = taskElement.find @selectors.taskText
            @enableEditing textElement

        @container.delegate @selectors.taskStatusItem, "click", (e) =>

            currentItem = $(e.currentTarget)
            items = currentItem.parent().find @selectors.taskStatusItem
            nextItem = currentItem.next()
            task = currentItem.parents @selectors.taskItem

            unless nextItem.length
                nextItem = items.first()
            items.addClass @classes.hidden
            nextItem.removeClass @classes.hidden

            status = nextItem.data "status"
            timestamp = +new Date()
            id = task.data "id"

            if status is "new"
                task.data "finish", null
                @updateTask id,
                    status: status
                    finish: null
            else
                task.data "finish", timestamp
                @updateTask id,
                    status: status
                    finish: timestamp
        
    bindDayListEvents: ->

        @textarea.on "keydown", (e) =>
            if e.which is @KEYS.ENTER
                value = @textarea.val().trim()
                if value
                    @appendTask @createTask value
                    @textarea.val ""
                e.preventDefault()

        @textareaSpeech.on "webkitspeechchange", (e) =>
            value = @textareaSpeech.val().capitalize()
            length = value.length
            @textarea
                .val(value)
                .focus()
                .get(0)
                .setSelectionRange(length, length);
            @textareaSpeech.val("")

        @dayAdd.on "click", =>
            today = new Date()
            if @currentDate.stringify() is today.stringify()
                # tomorrow
            else if +@currentDate < +

    enableEditing: (textElement) ->
        textElement.toArray().forEach (element) ->
            element.contentEditable = true
            range = document.createRange()
            range.selectNodeContents element
            range.collapse false
            selection = getSelection()
            selection.removeAllRanges()
            selection.addRange range
        textElement.addClass(@classes.editing).focus()

    disableEditing: (textElement) ->
        textElement.removeClass(@classes.editing).blur()
        textElement.toArray().forEach (element) ->
            element.contentEditable = false

    getCurrentDate: ->
        today = new Date()
        dates = _.keys(@tasks).sort (a,b) ->
            if +a.parse() > +b.parse() then -1 else 1

        for date in dates
            parsedDate = date.parse()
            if +parsedDate < +today
                return parsedDate

        return today

    getTaskElements: ->
        $(@selectors.taskItem, @container)

    getTaskById: (id) ->
        for date, item of @tasks
            for task in item.tasks
                if task.id is +id
                    return task

    getTaskCreationDate: (task) ->
        for date, item of @tasks
            for currentTask in item.tasks
                if currentTask.id is task.id
                    return date

    saveTasks: ->
        localStorage.setItem @LOCAL_STORAGE_TASKS_KEY, JSON.stringify @tasks
        # todo: sync with server
    
    createTask: (text) ->
        task =
            text: text
            start: +new Date()
            id: +((+new Date()).toString().substr(8, 13) + Math.random().toFixed(5).substr(2,7))
            status: "new"
        @tasks[@currentDate.stringify()].tasks.push task
        @saveTasks()
        task

    updateTask: (id, data) ->
        task = @getTaskById id
        updatedTask = _.extend task, data
        @saveTasks()
        updatedTask

    removeTask: (id) ->
        task = @getTaskById id
        date = @getTaskCreationDate task
        index = _.pluck(@tasks[date].tasks, "id").indexOf task.id
        @tasks[date].tasks = @tasks[date].tasks
            .slice(0,index)
            .concat @tasks[date].tasks.slice(index + 1)
        @saveTasks()

    humanizeDate: (date, includeWeekday) ->
        humanizedDate = "#{date.getDate()} #{@monthsInflected[date.getMonth()]} #{date.getFullYear()}"
        if includeWeekday
            humanizedDate = @weekdays[date.getDay()].capitalize() + ", " + humanizedDate
        humanizedDate
