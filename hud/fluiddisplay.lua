local computer = require("computer")
local colors = require("lib.graphics.colors")
local ar = require("lib.graphics.ar")
local parser = require("lib.utils.parser")
local time = require("lib.utils.time")
local screen = require("lib.utils.screen")
local states = require("server.entities.states")

local fluidDisplay = {}

local hudObjects = {}
local fluidData = {

}

function fluidDisplay.changeColor(glasses, backgroundColor, primaryColor, accentColor)
    local graphics = require("lib.graphics.graphics")
    for i = 1, #hudObjects do
        if hudObjects[i].glasses ~= nil then
            if hudObjects[i].glasses.address == glasses then
                if backgroundColor ~= nil then
                    for j = 1, #hudObjects[i].static do
                        hudObjects[i].static[j].setColor(screen.toRGB(backgroundColor))
                    end
                    --Add background coloredw widgets
                end
                if primaryColor ~= nil then
                    --Add Primary colored widgets
                end
                if accentColor ~= nil then
                    --Add accent colored widgets
                end
            end
        end
    end
end
--Scales: Small = 1, Normal = 2, Large = 3, Auto = 4x to 10x (Even)
--Glasses is a table of all glasses you want to dispaly the data on, with optional colour data.
--Glass table format {glassProxy, [{resolutionX, resolutionY}], [scale], [borderColor], [primaryColor], [accentColor], [width], [heigth]}
--Only the glass proxy is required, rest have default values.
function fluidDisplay.widget(glasses, fluids)

    if #hudObjects < #glasses then
        for i = 1, #glasses do
            if glasses[i][1] == nil then
                error("Must provide glass proxy for energy display.")
            end
            table.insert(hudObjects,  {
                static          = {},
                dynamic         = {},
                glasses         = glasses[i][1],
                resolution      = glasses[i][2] or {2560, 1440},
                scale           = glasses[i][3] or 3,
                borderColor     = glasses[i][4] or colors.darkGray,
                primaryColor    = glasses[i][5] or colors.electricBlue,
                accentColor     = glasses[i][6] or colors.magenta,
                width           = glasses[i][7] or 0,
                heigth          = glasses[i][8] or 29
            })
        end 
    end

    local selectedFluids = {}
    --Make proper implementation
    for k,v in pairs(fluids) do
        table.insert(selectedFluids, k)
    end



    for i = 1, #hudObjects do
        if hudObjects[i].width == 0 then hudObjects[i].width = screen.size(hudObjects[i].resolution, hudObjects[i].scale)[1] end
        local h = hudObjects[i].resolution[2]/hudObjects[i].scale
        local w = hudObjects[i].width
        local displayWidth = 60
        local hDivisor = 3
        local hBar = 8
        local hIO = h-hBar-2*hDivisor-1
        local startH = h - 15 - 3*hBar*#selectedFluids
        local fluidDisplays = 0
        --Initialization
        if #hudObjects[i].static == 0 and #hudObjects[i].glasses ~= nil then
            local borderColor = hudObjects[i].borderColor
            local primaryColor = hudObjects[i].primaryColor
            local accentColor = hudObjects[i].accentColor

            local function createFluidDisplay(x, y, fluid)
                    local amountString = parser.metricNumber(fluid.amount, "%.0f").."L/" .. parser.metricNumber(fluid.max, "%.0f").."L"
                    local percentage = math.min((1.0 - fluid.amount/fluid.max), 1.0)
                    local xTop = x + (w - x)*percentage
                    local xBot = x+hBar + (w - x)*percentage
                    table.insert(hudObjects[i].static, ar.quad(hudObjects[i].glasses, {x, y}, {x, y + hBar}, {w, y+hBar}, {w, y}, borderColor))
                    table.insert(hudObjects[i].static, ar.text(hudObjects[i].glasses, fluid.name, {x+1, y+1}, primaryColor, 0.7))
                    table.insert(hudObjects[i].static, ar.triangle(hudObjects[i].glasses, {x, y+hBar}, {x, y + hBar*2}, {x+hBar, y+hBar*2}, borderColor))
                    hudObjects[i].dynamic[fluid.id.."bar"] =  ar.quad(hudObjects[i].glasses, {xTop, y+hBar}, {xBot, y + hBar*2}, {w, y+hBar*2}, {w, y+hBar}, primaryColor, 0.5)
                    hudObjects[i].dynamic[fluid.id.."text"] =  ar.text(hudObjects[i].glasses, amountString, {(x+w)/2 - 4*(#amountString/2), y+1+hBar}, borderColor, 0.7, 0.25)
                    fluidData[fluid.id] = {amount=fluid.amount, max=fluid.max}
            end

            local nFluids = 0

            table.insert(hudObjects[i].static, ar.rectangle(hudObjects[i].glasses, {w-displayWidth, startH}, displayWidth, #selectedFluids * 2 * hBar, borderColor, 0.15)) --Background
            table.insert(hudObjects[i].static, ar.quad(hudObjects[i].glasses, {w-displayWidth-4, startH+4}, {w-displayWidth-4, startH + #selectedFluids * 2 * hBar - 4}, {w-displayWidth, startH + #selectedFluids * 2 * hBar}, {w-displayWidth, startH}, borderColor)) --Left Bar
            
            for _, f in pairs(fluids) do
                if type(f) == "table" then 
                    createFluidDisplay(w - displayWidth, startH + 2*hBar * nFluids, f)
                    nFluids = nFluids + 1
                end
            end
            table.insert(hudObjects[i].static, ar.quad(hudObjects[i].glasses, {w - 60, startH + 2*hBar * nFluids}, {w - 60 + hBar, startH + 2*hBar * nFluids + hBar}, {w, startH + 2*hBar * nFluids+hBar}, {w, startH + 2*hBar * nFluids}, borderColor))--Bottom Bar
            table.insert(hudObjects[i].static, ar.quad(hudObjects[i].glasses, {w-displayWidth-2, startH+4}, {w-displayWidth-2, startH + #selectedFluids * 2 * hBar - 5}, {w-displayWidth-1, startH + #selectedFluids * 2 * hBar-4}, {w-displayWidth-1, startH+3}, accentColor, 0.8)) --Left Accent
            table.insert(hudObjects[i].static, ar.quad(hudObjects[i].glasses, {w-displayWidth-1, startH + #selectedFluids * 2 * hBar-5}, {w-displayWidth-1, startH + #selectedFluids * 2 * hBar-4}, {w-displayWidth-1 + hBar, startH + #selectedFluids * 2 * hBar-4 + hBar}, {w-displayWidth-1 + hBar, startH + #selectedFluids * 2 * hBar-5 + hBar}, accentColor, 0.8)) --Diagonal Accent
            table.insert(hudObjects[i].static, ar.rectangle(hudObjects[i].glasses, {w-displayWidth-1 + hBar, startH + #selectedFluids * 2 * hBar-5 + hBar}, displayWidth - hBar + 2, 1, accentColor, 0.8)) --Background
        end
        --Update loop
    end
end

function fluidDisplay.remove(glassAddress)
    for i = 1, #hudObjects do
        local hudObject = hudObjects[i]
        local glasses = hudObject.glasses
        if glasses ~= nil then
            if glasses.address == glassAddress then
                for j = 1, #hudObjects[i].static do
                    hudObjects[i].glasses.removeObject(hudObjects[i].static[j].getID())
                end
                for name, value in pairs(hudObjects[i].dynamic) do
                    hudObjects[i].glasses.removeObject(hudObjects[i].dynamic[name].getID())
                end
            end
        end
    end
end

return fluidDisplay