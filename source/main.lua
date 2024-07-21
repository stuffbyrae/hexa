-- Importing things
import 'CoreLibs/math'
import 'CoreLibs/timer'
import 'CoreLibs/crank'
import 'CoreLibs/object'
import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'CoreLibs/animation'
import 'scenemanager'
import 'title'
scenemanager = scenemanager()

-- Setting up basic SDK params
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local fle <const> = pd.sound.fileplayer
local text <const> = gfx.getLocalizedText
local mask_arcade <const> = gfx.image.new('images/mask_arcade')
local mask_zen <const> = gfx.image.new('images/mask_zen')
local pause <const> = gfx.image.new('images/pause')
local pause_luci <const> = gfx.image.new('images/pause_luci')

catalog = false
if pd.metadata.bundleID == "wtf.rae.hexa" then
    catalog = true
end

pd.display.setRefreshRate(30)
gfx.setBackgroundColor(gfx.kColorBlack)
gfx.setLineWidth(3)

-- Save check
function savecheck()
    save = pd.datastore.read()
    if save == nil then save = {} end
    if save.music == nil then save.music = true end
    if save.sfx == nil then save.sfx = true end
    if save.flip == nil then save.flip = false end
    if save.crank == nil then save.crank = true end
    if save.skipfanfare == nil then save.skipfanfare = false end
    if save.lastdaily == nil then save.lastdaily = {} end
    save.lastdaily.year = save.lastdaily.year or 0
    save.lastdaily.month = save.lastdaily.month or 0
    save.lastdaily.day = save.lastdaily.day or 0
    save.lastdaily.score = save.lastdaily.score or 0
    if save.lastdaily.sent == nil then save.lastdaily.sent = false end
    save.score = save.score or 0
end

-- ... now we run that!
savecheck()

-- When the game closes...
function pd.gameWillTerminate()
    pd.datastore.write(save)
end

function pauseimage(mode)
    if mode == nil or not vars.can_do_stuff then
        pd.setMenuImage(pause_luci)
    else
        local image = gfx.getDisplayImage()
        gfx.pushContext(image)
            if mode == "arcade" or mode == "dailyrun" then
                mask_arcade:draw(0, 0)
            elseif mode == "zen" then
                mask_zen:draw(0, 0)
            end
        gfx.popContext()
        gfx.pushContext(pause)
        if mode == "arcade" or mode == "dailyrun" then
            image:drawScaled(-45, 65, 0.666)
        elseif mode == "zen" then
            image:drawScaled(-33, 65, 0.666)
        end
        gfx.popContext()
        pd.setMenuImage(pause)
    end
end

function pd.deviceWillSleep()
    pd.datastore.write(save)
end

-- Setting up music
music = nil

-- Fades the music out, and trashes it when finished. Should be called alongside a scene change, only if the music is expected to change. Delay can set the delay (in seconds) of the fade
function fademusic(delay)
    delay = delay or 300
    if music ~= nil then
        music:setVolume(0, 0, delay/700, function()
            music:stop()
            music = nil
        end)
    end
end

-- New music track. This should be called in a scene's init, only if there's no track leading into it. File is a path to an audio file in the PDX. Loop, if true, will loop the audio file. Range will set the loop's starting range.
function newmusic(file, loop, range)
    if save.music and music == nil then -- If a music file isn't actively playing...then go ahead and set a new one.
        music = fle.new(file)
        if loop then -- If set to loop, then ... loop it!
            music:setLoopRange(range or 0)
            music:play(0)
        else
            music:play()
            music:setFinishCallback(function()
                music = nil
            end)
        end
    end
end

function pd.timer:resetnew(duration, startValue, endValue, easingFunction)
    self.duration = duration
    if startValue ~= nil then
        self._startValue = startValue
        self.originalValues.startValue = startValue
        self._endValue = endValue or 0
        self.originalValues.endValue = endValue or 0
        self._easingFunction = easingFunction or pd.easingFunctions.linear
        self.originalValues.easingFunction = easingFunction or pd.easingFunctions.linear
        self._currentTime = 0
        self.value = self._startValue
    end
    self._lastTime = nil
    self.active = true
    self.hasReversed = false
    self.reverses = false
    self.repeats = false
    self.remainingDelay = self.delay
    self._calledOnRepeat = nil
    self.discardOnCompletion = false
    self.paused = false
    self.timerEndedCallback = self.timerEndedCallback
end

-- This function returns the inputted number, with the ordinal suffix tacked on at the end (as a string)
function ordinal(num)
    local m10 = num % 10 -- This is the number, modulo'd by 10.
    local m100 = num % 100 -- This is the number, modulo'd by 100.
    if m10 == 1 and m100 ~= 11 then -- If the number ends in 1 but NOT 11...
        return tostring(num) .. gfx.getLocalizedText("st") -- add "st" on.
    elseif m10 == 2 and m100 ~= 12 then -- If the number ends in 2 but NOT 12...
        return tostring(num) .. gfx.getLocalizedText("nd") -- add "nd" on,
    elseif m10 == 3 and m100 ~= 13 then -- and if the number ends in 3 but NOT 13...
        return tostring(num) .. gfx.getLocalizedText("rd") -- add "rd" on.
    else -- If all those checks passed us by,
        return tostring(num) .. gfx.getLocalizedText("th") -- then it ends in "th".
    end
end

-- http://lua-users.org/wiki/FormattingNumbers
function commalize(amount)
  local formatted = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

-- This function shakes the screen. int is a number representing intensity. time is a number representing duration
function shakies(time, int)
    if pd.getReduceFlashing() or perf then -- If reduce flashing is enabled, then don't shake.
        return
    end
    anim_shakies = pd.timer.new(time or 500, int or 10, 0, pd.easingFunctions.outElastic)
end

function shakies_y(time, int)
    if pd.getReduceFlashing() or perf then
        return
    end
    anim_shakies_y = pd.timer.new(time or 750, int or 10, 0, pd.easingFunctions.outElastic)
end

import 'game'
scenemanager:switchscene(title, true)

function pd.update()
    if (save.lastdaily.score ~= 0) and not (save.lastdaily.year == pd.getGMTTime().year and save.lastdaily.month == pd.getGMTTime().month and save.lastdaily.day == pd.getGMTTime().day) then
      save.lastdaily.score = 0
      save.lastdaily.sent = false
    end
    -- Screen shake update logic
    if anim_shakies ~= nil then
        pd.display.setOffset(anim_shakies.value, offsety)
    end
    offsetx, offsety = pd.display.getOffset()
    if anim_shakies_y ~= nil then
        pd.display.setOffset(offsetx, anim_shakies_y.value)
    end
    -- Catch-all stuff ...
    gfx.sprite.update()
    pd.timer.updateTimers()
    -- pd.drawFPS(10, 10)
end