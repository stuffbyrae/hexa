local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local floor <const> = math.floor

class('scenemanager').extends()

local podbaydoor <const> = gfx.image.new('images/podbaydoor')
local sfx_transition <const> = smp.new('audio/sfx/transition')

function scenemanager:init()
    self.transitiontime = 700
    self.transitioning = false
end

function scenemanager:switchscene(scene, ...)
    self.newscene = scene
    self.sceneargs = {...}
    -- Pop any rogue input handlers, leaving the default one.
    local inputsize = #playdate.inputHandlers - 1
    for i = 1, inputsize do
        pd.inputHandlers.pop()
    end
    self:loadnewscene()
    self.transitioning = false
end

function scenemanager:transitionscene(scene, ...)
    if self.transitioning then return end
    show_crank = false
    -- Pop any rogue input handlers, leaving the default one.
    local inputsize = #playdate.inputHandlers - 1
    for i = 1, inputsize do
        pd.inputHandlers.pop()
    end
    self.transitioning = true
    self.newscene = scene
    self.sceneargs = {...}
    local transitiontimer = self:transition(-230, -10, 410, 202)
    if save.sfx then sfx_transition:play() end
    transitiontimer.timerEndedCallback = function()
        self:loadnewscene()
        transitiontimer = self:transition(-10, -230, 202, 410)
        transitiontimer.timerEndedCallback = function()
            self.transitioning = false
        end
    end
end

function scenemanager:transition(podbaydoor1start, podbaydoor1end, podbaydoor2start, podbaydoor2end)
    local podbaydoor1 = self:loadingsprite(false)
    local podbaydoor2 = self:loadingsprite(true)
    podbaydoor1:moveTo(podbaydoor1start, 0)
    podbaydoor2:moveTo(podbaydoor2start, 0)
    local podbaydoor1timer = pd.timer.new(self.transitiontime, podbaydoor1start, podbaydoor1end, pd.easingFunctions.inOutCubic)
    local podbaydoor2timer = pd.timer.new(self.transitiontime, podbaydoor2start, podbaydoor2end, pd.easingFunctions.inOutCubic)
    podbaydoor1timer.updateCallback = function(timer) podbaydoor1:moveTo(floor(podbaydoor1timer.value / 2) * 2, 0) end
    podbaydoor2timer.updateCallback = function(timer) podbaydoor2:moveTo(floor(podbaydoor2timer.value / 2) * 2, 0) end
    return podbaydoor1timer
end

function scenemanager:loadingsprite(flip)
    local loading = gfx.sprite.new(podbaydoor)
    loading:setZIndex(26000)
    loading:setCenter(0, 0)
    if flip then
        loading:moveTo(400, 0)
        loading:setImageFlip("flipX")
    else
        loading:moveTo(-200, 0)
    end
    loading:setIgnoresDrawOffset(true)
    loading:add()
    return loading
end

function scenemanager:loadnewscene()
    self:cleanupscene()
    self.newscene(table.unpack(self.sceneargs))
end

function scenemanager:cleanupscene()
    gfx.sprite:removeAll()
    if sprites ~= nil then
        for i = 1, #sprites do
            sprites[i] = nil
        end
    end
    sprites = {}
    if assets ~= nil then
        for i = 1, #assets do
            assets[i] = nil
        end
        assets = nil -- Nil all the assets,
    end
    if vars ~= nil then
        for i = 1, #vars do
            vars[i] = nil
        end
    end
    vars = nil -- and nil all the variables.
    self:removealltimers() -- Remove every timer,
    collectgarbage('collect') -- and collect the garbage.
    gfx.setDrawOffset(0, 0) -- Lastly, reset the drawing offset. just in case.
end

function scenemanager:removealltimers()
    local alltimers = pd.timer.allTimers()
    for _, timer in ipairs(alltimers) do
        timer:remove()
        timer = nil
    end
end