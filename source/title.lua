import 'game'
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
		anim_stars_small_x = pd.timer.new(4000, 0, -399),
		anim_stars_small_y = pd.timer.new(2750, 0, -239),
		anim_stars_large_x = pd.timer.new(2500, 0, -399),
		anim_stars_large_y = pd.timer.new(1250, 0, -239),
		selections = {'arcademode', 'zenmode', 'howtoplay', 'options', 'credits'},
		selection = 0,
	}
	vars.titleHandlers = {
		upButtonDown = function()
			if vars.selection > 1 then
				vars.selection -= 1
				if save.sfx then assets.sfx_move:play() end
			else
				if save.sfx then assets.sfx_bonk:play() end
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

		AButtonDown = function()
			if save.sfx then assets.sfx_select:play() end
			if vars.selections[vars.selection] == "arcademode" then
				scenemanager:transitionscene(game, "arcade")
				fademusic()
			elseif vars.selections[vars.selection] == "zenmode" then
				scenemanager:transitionscene(game, "zen")
				fademusic()
			elseif vars.selections[vars.selection] == "howtoplay" then
				scenemanager:transitionscene(howtoplay)
			elseif vars.selections[vars.selection] == "options" then
				scenemanager:transitionscene(options)
			elseif vars.selections[vars.selection] == "credits" then
				scenemanager:transitionscene(credits)
			end
			vars.selection = 0
		end,
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.titleHandlers)
		vars.selection = 1
	end)

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
		gfx.fillRect(265 + vars.anim_title.value, 115, 200, 160)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.half_circle:drawTextAligned(text('arcademode'), 380 + vars.anim_title.value, 130, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('zenmode'), 380 + vars.anim_title.value, 150, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('howtoplay'), 380 + vars.anim_title.value, 170, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('options'), 380 + vars.anim_title.value, 190, kTextAlignment.right)
		assets.half_circle:drawTextAligned(text('credits'), 380 + vars.anim_title.value, 210, kTextAlignment.right)
		assets.full_circle:drawTextAligned((vars.selection > 0 and text(vars.selections[vars.selection])) or (' '), 380 + vars.anim_title.value, 110 + (20 * vars.selection), kTextAlignment.right)
		assets.half_circle:drawText(text('move') .. ' ' .. text('select'), 10 - vars.anim_title.value, 220)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	newmusic('audio/music/title', true)

	self:add()
end

function title:update()
	local ticks = pd.getCrankTicks(6)
	if ticks ~= 0 and vars.selection > 0 then
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