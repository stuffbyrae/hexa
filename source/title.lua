import 'game'
import 'highscores'
import 'howtoplay'
import 'options'
import 'credits'

-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('title').extends(gfx.sprite) -- Create the scene's class
function title:init(...)
	title.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning and vars.selection > 0 then
			menu:addMenuItem(text('howtoplay'), function()
				scenemanager:transitionscene(howtoplay)
				vars.selection = 0
			end)
			if catalog then
				menu:addMenuItem(text('highscores'), function()
					scenemanager:transitionscene(highscores)
					vars.selection = 0
				end)
			end
			menu:addMenuItem(text('options'), function()
				scenemanager:transitionscene(options)
				vars.selection = 0
			end)
		end
	end

	assets = {
		title = gfx.image.new('images/title'),
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		logo = gfx.image.new('images/logo'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		sfx_move = smp.new('audio/sfx/swap'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
		sfx_select = smp.new('audio/sfx/select'),
	}

	vars = {
		animate = args[1], -- bool. does the title animate on transition back?
		default = args[2],
		anim_stars_small_x = pd.timer.new(4000, 0, -399),
		anim_stars_small_y = pd.timer.new(2750, 0, -239),
		anim_stars_large_x = pd.timer.new(2500, 0, -399),
		anim_stars_large_y = pd.timer.new(1250, 0, -239),
		dailyrunnable = false,
		selection = 0,
	}
	vars.titleHandlers = {
		upButtonDown = function()
			if vars.selection ~= 0 then
				if vars.keytimer ~= nil then vars.keytimer:remove() end
				vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 75, function()
					if vars.selection > 1 then
						vars.selection -= 1
					else
						vars.selection = #vars.selections
					end
					if save.sfx then assets.sfx_move:play() end
				end)
			end
		end,

		upButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		downButtonDown = function()
			if vars.selection ~= 0 then
				if vars.keytimer ~= nil then vars.keytimer:remove() end
				vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 75, function()
					if vars.selection < #vars.selections then
						vars.selection += 1
					else
						vars.selection = 1
					end
					if save.sfx then assets.sfx_move:play() end
				end)
			end
		end,

		downButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		AButtonDown = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
			if vars.selections[vars.selection] == "arcade" then
				scenemanager:transitionscene(game, "arcade")
				fademusic()
			elseif vars.selections[vars.selection] == "zen" then
				scenemanager:transitionscene(game, "zen")
				fademusic()
			elseif vars.selections[vars.selection] == "dailyrun" then
				if vars.dailyrunnable then
					scenemanager:transitionscene(game, "dailyrun")
					save.lastdaily.score = 0
					fademusic()
				else
					shakies()
					if save.sfx then assets.sfx_bonk:play() end
				end
			elseif vars.selections[vars.selection] == "highscores" then
				scenemanager:transitionscene(highscores, "arcade")
			elseif vars.selections[vars.selection] == "howtoplay" then
				scenemanager:transitionscene(howtoplay)
			elseif vars.selections[vars.selection] == "options" then
				scenemanager:transitionscene(options)
			elseif vars.selections[vars.selection] == "credits" then
				scenemanager:transitionscene(credits)
			end
			if scenemanager.transitioning then
				if save.sfx then assets.sfx_select:play() end
				vars.selection = 0
			end
		end,
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.titleHandlers)
		if vars.default ~= nil then
			for i = 1, #vars.selections do
				if vars.selections[i] == vars.default then
					vars.selection = i
				end
			end
		end
		if vars.selection == 0 then
			vars.selection = 1
		end
	end)

	if catalog then
		vars.selections = {'arcade', 'zen', 'dailyrun', 'highscores', 'howtoplay', 'options', 'credits'}
	else
		vars.selections = {'arcade', 'zen', 'dailyrun', 'howtoplay', 'options', 'credits'}
	end

	if vars.animate then
		vars.anim_title = pd.timer.new(500, 200, 0, pd.easingFunctions.outBack)
	else
		vars.anim_title = pd.timer.new(0, 0, 0)
	end

	vars.anim_stars_small_x.repeats = true
	vars.anim_stars_small_y.repeats = true
	vars.anim_stars_large_x.repeats = true
	vars.anim_stars_large_y.repeats = true

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.title:draw(0, 0)
		assets.stars_small:draw(vars.anim_stars_small_x.value, vars.anim_stars_small_y.value)
		assets.stars_large:draw(vars.anim_stars_large_x.value, vars.anim_stars_large_y.value)
		assets.logo:draw(0, 0)
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		if catalog then
			gfx.fillRect(250 + vars.anim_title.value, 72, 200, 160)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			if pd.getGMTTime().hour < 23 then
				assets.half_circle:drawText(((vars.dailyrunnable and '⏰ ') or '🔒 ') .. (24 - pd.getGMTTime().hour) .. text('hrs'), 265 + vars.anim_title.value, 130)
			elseif pd.getGMTTime().minute < 59 then
				assets.half_circle:drawText(((vars.dailyrunnable and '⏰ ') or '🔒 ') .. (60 - pd.getGMTTime().minute) .. text('mins'), 265 + vars.anim_title.value, 130)
			else
				assets.half_circle:drawText(((vars.dailyrunnable and '⏰ ') or '🔒 ') .. (60 - pd.getGMTTime().second) .. text('secs'), 265 + vars.anim_title.value, 130)
			end
			assets.half_circle:drawTextAligned(text('arcade'), 385 + vars.anim_title.value, 90, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('zen'), 385 + vars.anim_title.value, 110, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('dailyrun'), 385 + vars.anim_title.value, 130, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('highscores'), 385 + vars.anim_title.value, 150, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('howtoplay'), 385 + vars.anim_title.value, 170, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('options'), 385 + vars.anim_title.value, 190, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('credits'), 385 + vars.anim_title.value, 210, kTextAlignment.right)
			assets.full_circle:drawTextAligned((vars.selection > 0 and text(vars.selections[vars.selection])) or (' '), 385 + vars.anim_title.value, 70 + (20 * vars.selection), kTextAlignment.right)
		else
			gfx.fillRect(250 + vars.anim_title.value, 92, 200, 160)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			if pd.getGMTTime().hour < 23 then
				assets.half_circle:drawText(((vars.dailyrunnable and '⏰ ') or '🔒 ') .. (24 - pd.getGMTTime().hour) .. text('hrs'), 265 + vars.anim_title.value, 150)
			else
				if pd.getGMTTime().minute < 59 then
					assets.half_circle:drawText(((vars.dailyrunnable and '⏰ ') or '🔒 ') .. (60 - pd.getGMTTime().minute) .. text('mins'), 265 + vars.anim_title.value, 150)
				else
					assets.half_circle:drawText(((vars.dailyrunnable and '⏰ ') or '🔒 ') .. (60 - pd.getGMTTime().second) .. text('secs'), 265 + vars.anim_title.value, 150)
				end
			end
			assets.half_circle:drawTextAligned(text('arcade'), 385 + vars.anim_title.value, 110, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('zen'), 385 + vars.anim_title.value, 130, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('dailyrun'), 385 + vars.anim_title.value, 150, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('howtoplay'), 385 + vars.anim_title.value, 170, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('options'), 385 + vars.anim_title.value, 190, kTextAlignment.right)
			assets.half_circle:drawTextAligned(text('credits'), 385 + vars.anim_title.value, 210, kTextAlignment.right)
			assets.full_circle:drawTextAligned((vars.selection > 0 and text(vars.selections[vars.selection])) or (' '), 385 + vars.anim_title.value, 90 + (20 * vars.selection), kTextAlignment.right)
		end
		assets.half_circle:drawText(text('move') .. ' ' .. text('select'), 10 - vars.anim_title.value, 220)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	newmusic('audio/music/title', true)

	self:add()
end

function title:update()
	if save.lastdaily.year == pd.getGMTTime().year and save.lastdaily.month == pd.getGMTTime().month and save.lastdaily.day == pd.getGMTTime().day then
		vars.dailyrunnable = false
	else
		vars.dailyrunnable = true
	end
	local ticks = pd.getCrankTicks(8)
	if ticks ~= 0 and vars.selection > 0 then
		if save.sfx then assets.sfx_move:play() end
		vars.selection += ticks
		if vars.selection < 1 then
			vars.selection = #vars.selections
		elseif vars.selection > #vars.selections then
			vars.selection = 1
		end
	end
end