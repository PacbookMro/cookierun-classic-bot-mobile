-- AnkuLua lays controls out horizontally until newRow(). Keep every widget
-- on its own row so labels cannot push inputs/spinners off a portrait screen.
local ui = {}

function ui.text(label)
    addTextView(label)
    newRow()
end

function ui.number(label, name, default)
    ui.text(label)
    addEditNumber(name, default)
    newRow()
end

function ui.choice(label, name, choices, default)
    ui.text(label)
    addSpinner(name, choices, default)
    newRow()
end

function ui.check(name, label, default)
    addCheckBox(name, label, default)
    newRow()
end

function ui.show(title)
    -- Native UI uses the display orientation, independently of game scaling.
    if dialogShowFullScreen then dialogShowFullScreen(title) else dialogShow(title) end
end

return ui
