-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('options').extends(gfx.sprite) -- Create the scene's class
function options:init(...)
	options.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning and vars.selection > 0 then
			menu:addMenuItem(text('goback'), function()
				scenemanager:transitionscene(title)
				vars.selection = 0
			end)
		end
	end

	assets = {
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		sfx_move = smp.new('audio/sfx/swap'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
		sfx_select = smp.new('audio/sfx/select'),
		sfx_back = smp.new('audio/sfx/back'),
		sfx_boom = smp.new('audio/sfx/boom'),
		fg = gfx.image.new('images/fg'),
		fg_hexa_1 = gfx.image.new('images/fg_hexa_1'),
		fg_hexa_2 = gfx.image.new('images/fg_hexa_2'),
	}

	vars = {
		anim_stars_small_x = pd.timer.new(4000, 0, -399),
		anim_stars_small_y = pd.timer.new(2750, 0, -239),
		anim_stars_large_x = pd.timer.new(2500, 0, -399),
		anim_stars_large_y = pd.timer.new(1250, 0, -239),
		anim_fg_hexa = pd.timer.new(3000, 0, 7, pd.easingFunctions.inOutSine),
		selections = {'music', 'sfx', 'flip', 'crank', 'reset'},
		selection = 0,
		resetprogress = 1,
	}
	vars.optionsHandlers = {
		upButtonDown = function()
			if vars.selection > 1 then
				vars.selection -= 1
				if save.sfx then assets.sfx_move:play() end
			else
				if save.sfx then assets.sfx_bonk:play() end
			end
			if vars.resetprogress < 4 then
				vars.resetprogress = 1
			end
		end,

		downButtonDown = function()
			if vars.selection < #vars.selections then
				vars.selection += 1
				if save.sfx then assets.sfx_move:play() end
			else
				if save.sfx then assets.sfx_bonk:play() end
			end
		end,

		BButtonDown = function()
			if save.sfx then assets.sfx_back:play() end
			scenemanager:transitionscene(title)
			vars.selection = 0
		end,

		AButtonDown = function()
			if vars.selections[vars.selection] == "music" then
				save.music = not save.music
				if not save.music then
					fademusic(1)
				else
					newmusic('audio/music/title', true)
				end
			elseif vars.selections[vars.selection] == "sfx" then
				save.sfx = not save.sfx
			elseif vars.selections[vars.selection] == "flip" then
				save.flip = not save.flip
			elseif vars.selections[vars.selection] == "crank" then
				save.crank = not save.crank
			elseif vars.selections[vars.selection] == "reset" then
				if vars.resetprogress < 3 then
					vars.resetprogress += 1
				elseif vars.resetprogress == 3 then
					if save.sfx then assets.sfx_boom:play() end
					vars.resetprogress += 1
					save.score = 0
				end
			end
			if save.sfx then assets.sfx_select:play() end
		end,
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.optionsHandlers)
		vars.selection = 1
	end)

	vars.anim_stars_small_x.repeats = true
	vars.anim_stars_small_y.repeats = true
	vars.anim_stars_large_x.repeats = true
	vars.anim_stars_large_y.repeats = true
	vars.anim_fg_hexa.reverses = true
	vars.anim_fg_hexa.repeats = true

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.stars_small:draw(vars.anim_stars_small_x.value, vars.anim_stars_small_y.value)
		assets.stars_large:draw(vars.anim_stars_large_x.value, vars.anim_stars_large_y.value)
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.half_circle:drawTextAligned(text('options_music') .. text(tostring(save.music)), 200, 70, kTextAlignment.center)
		assets.half_circle:drawTextAligned(text('options_sfx') .. text(tostring(save.sfx)), 200, 90, kTextAlignment.center)
		assets.half_circle:drawTextAligned(text('options_flip') .. text(tostring(save.flip)), 200, 110, kTextAlignment.center)
		assets.half_circle:drawTextAligned(text('options_crank') .. text(tostring(save.crank)), 200, 130, kTextAlignment.center)
		assets.half_circle:drawTextAligned(text('options_reset_' .. vars.resetprogress), 200, 150, kTextAlignment.center)
		if vars.selections[vars.selection] == 'reset' then
			assets.full_circle:drawTextAligned(text('options_reset_' .. vars.resetprogress), 200, 50 + (20 * vars.selection), kTextAlignment.center)
		else
			assets.full_circle:drawTextAligned((vars.selection > 0 and text('options_' .. vars.selections[vars.selection]) .. text(tostring(save[vars.selections[vars.selection]]))) or (' '), 200, 50 + (20 * vars.selection), kTextAlignment.center)
		end
		assets.half_circle:drawText('v' .. pd.metadata.version, 65, 205)
		assets.half_circle:drawText(text('move') .. ' ' .. text('toggle'), 70, 220)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		assets.fg:draw(0, 0)
		assets.fg_hexa_1:draw(0, vars.anim_fg_hexa.value)
		assets.fg_hexa_2:draw(0, vars.anim_fg_hexa.value * 1.2)
	end)

	self:add()
end

function options:update()
	local ticks = pd.getCrankTicks(6)
	if ticks ~= 0 and vars.selection > 0 then
		if ticks < 0 and vars.resetprogress > 1 then
			vars.resetprogress = 1
		end
		if save.sfx then
			if ticks < 0 and vars.selection == 1 then
				assets.sfx_bonk:play()
			elseif ticks > 0 and vars.selection == #vars.selections then
				assets.sfx_bonk:play()
			else
				assets.sfx_move:play()
			end
		end
		vars.selection += ticks
		vars.selection = math.max(1, math.min(#vars.selections, vars.selection))
	end
end