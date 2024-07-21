-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('howtoplay').extends(gfx.sprite) -- Create the scene's class
function howtoplay:init(...)
	howtoplay.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			menu:addMenuItem(text('goback'), function()
				scenemanager:transitionscene(title, false, 'howtoplay')
			end)
		end
	end

	assets = {
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		sfx_back = smp.new('audio/sfx/back'),
		manual = gfx.imagetable.new('images/manual'),
		sfx_move = smp.new('audio/sfx/swap'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
	}

	vars = {
		anim_stars_small_x = pd.timer.new(4000, 0, -399),
		anim_stars_small_y = pd.timer.new(2750, 0, -239),
		anim_stars_large_x = pd.timer.new(2500, 0, -399),
		anim_stars_large_y = pd.timer.new(1250, 0, -239),
		page = 1,
	}
	vars.howtoplayHandlers = {
		leftButtonDown = function()
			if vars.page > 1 then
				vars.page -= 1
				if save.sfx then assets.sfx_move:play() end
			else
				if save.sfx then assets.sfx_bonk:play() end
				shakies()
			end
		end,

		rightButtonDown = function()
			if vars.page < 7 then
				vars.page += 1
				if save.sfx then assets.sfx_move:play() end
			else
				if save.sfx then assets.sfx_bonk:play() end
				shakies()
			end
		end,

		BButtonDown = function()
			if save.sfx then assets.sfx_back:play() end
			scenemanager:transitionscene(title, false, 'howtoplay')
		end
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.howtoplayHandlers)
	end)

	vars.anim_stars_small_x.repeats = true
	vars.anim_stars_small_y.repeats = true
	vars.anim_stars_large_x.repeats = true
	vars.anim_stars_large_y.repeats = true

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.stars_small:draw(vars.anim_stars_small_x.value, vars.anim_stars_small_y.value)
		assets.stars_large:draw(vars.anim_stars_large_x.value, vars.anim_stars_large_y.value)
		gfx.setDitherPattern(0.25, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 0, 400, 240)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.full_circle:drawText(text('manual' .. vars.page), 10, 10)
		assets.manual[vars.page]:draw(220, 40)
		assets.half_circle:drawText(text('page') .. ' ' .. text('back'), 10, 220)
		assets.half_circle:drawTextAligned(vars.page .. '/7', 390, 220, kTextAlignment.right)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	self:add()
end