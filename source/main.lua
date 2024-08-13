-- Importing things
import 'gridview'
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
local mask_arcade_true <const> = gfx.image.new('images/mask_arcade_true')
local mask_arcade_false <const> = gfx.image.new('images/mask_arcade_false')
local mask_zen <const> = gfx.image.new('images/mask_zen')
local pause <const> = gfx.image.new('images/pause')
local pause_luci <const> = gfx.image.new('images/pause_luci')
local tris_x <const> = {140, 170, 200, 230, 260, 110, 140, 170, 200, 230, 260, 290, 110, 140, 170, 200, 230, 260, 290}
local tris_y <const> = {70, 70, 70, 70, 70, 120, 120, 120, 120, 120, 120, 120, 170, 170, 170, 170, 170, 170, 170}
local tris_flip <const> = {true, false, true, false, true, true, false, true, false, true, false, true, false, true, false, true, false, true, false}

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
    save.sensitivity = save.sensitivity or 2
    if save.skipfanfare == nil then save.skipfanfare = false end
    if save.lastdaily == nil then save.lastdaily = {} end
    save.lastdaily.year = save.lastdaily.year or 0
    save.lastdaily.month = save.lastdaily.month or 0
    save.lastdaily.day = save.lastdaily.day or 0
    save.lastdaily.score = save.lastdaily.score or 0
    if save.lastdaily.sent == nil then save.lastdaily.sent = false end
    save.score = save.score or 0
    save.swaps = save.swaps or 0
    save.hexas = save.hexas or 0
    if save.mission_bests == nil then save.mission_bests = {} end
    save.highest_mission = save.highest_mission or 1
    for i = 1, 50 do
        save.mission_bests['mission' .. i] = save.mission_bests['mission' .. i] or 0
    end
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
        local pauseimg = pause:copy()
        gfx.pushContext(image)
            if mode == "picture" then
              assets.ui:draw(0, 0)
              for i = 1, 19 do
                game:tri(tris_x[i], tris_y[i], tris_flip[i], vars.goal[i].color, vars.goal[i].powerup)
              end
            end
            if mode == "arcade" or mode == "dailyrun" or mode == "time" or mode == "speedrun" then
              if save.crank then
                mask_arcade_true:draw(0, 0)
              else
                mask_arcade_false:draw(0, 0)
              end
            elseif mode == "zen" or mode == "picture" or mode == "logic" then
                mask_zen:draw(0, 0)
            end
        gfx.popContext()
        gfx.pushContext(pauseimg)
        if mode == "arcade" or mode == "dailyrun" or mode == "time" or mode == "speedrun" then
            image:drawScaled(-45, 65, 0.666)
        elseif mode == "zen" or mode == "picture" or mode == "logic" then
            image:drawScaled(-33, 65, 0.666)
        end
        if vars.mode == "time" or vars.mode == "speedrun" or vars.mode == "picture" or vars.mode == "logic" then
          local x = 0
          local y = 0
          local width = 200
          local height = 80
          local column = vars.mission
          gfx.setColor(gfx.kColorWhite)
          gfx.fillRect(x, y, width, height)
          gfx.setColor(gfx.kColorBlack)
          gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
          gfx.fillPolygon(x, y, x + width, y, x + width, y + height, x + width - (width * 0.2), y + height, x + width - (width * 0.05), y + (height / 2), x + width - (width * 0.2), y, x + width * 0.2, y, x + width * 0.05, y + (height / 2), x + width * 0.2, y + height, x, y + height, x, y)
          gfx.setColor(gfx.kColorBlack)
          if missions_list[column].type == "picture" then
            assets.full_circle:drawTextAligned(text('mission_picture1') .. missions_list[column].name .. text('mission_picture2'), x + (width / 2), y + (height / 8), kTextAlignment.center)
          elseif missions_list[column].type == "logic" or missions_list[column].type == "speedrun" then
            assets.full_circle:drawTextAligned(text('mission_' .. missions_list[column].type .. '_' .. missions_list[column].modifier), x + (width / 2), y + (height / 8), kTextAlignment.center)
          else
            assets.full_circle:drawTextAligned(text('mission_' .. missions_list[column].type), x + (width / 2), y + (height / 8), kTextAlignment.center)
          end
        end
        gfx.popContext()
        pd.setMenuImage(pauseimg)
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

-- http://lua-users.org/wiki/CopyTable
-- Save copied tables in `copies`, indexed by original table.
function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- This function takes a score number as input, and spits out the proper time in minutes, seconds, and milliseconds
function timecalc(num)
    local mins = math.floor((num/30) / 60)
    local secs = math.floor((num/30) - mins * 60)
    local mils = math.floor((num/30)*99 - mins * 5940 - secs * 99)
    if secs < 10 then secs = '0' .. secs end
    if mils < 10 then mils = '0' .. mils end
    return mins, secs, mils
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

scenemanager:switchscene(title, true, 'arcade')

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