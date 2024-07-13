-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('highscores').extends(gfx.sprite) -- Create the scene's class
function highscores:init(...)
	highscores.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			menu:addMenuItem(text('goback'), function()
				scenemanager:transitionscene(title)
			end)
		end
	end

	assets = {
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		sfx_back = smp.new('audio/sfx/back'),
		fg = gfx.image.new('images/fg'),
	}

	vars = {
		mode = args[1] or "arcade",
		anim_stars_small_x = pd.timer.new(4000, 0, -399),
		anim_stars_small_y = pd.timer.new(2750, 0, -239),
		anim_stars_large_x = pd.timer.new(2500, 0, -399),
		anim_stars_large_y = pd.timer.new(1250, 0, -239),
		result = {},
		best = {},
		loading = false,
		test = {
			scores = {
				{ player = "rae", rank = 1, value = 1000000 },
				{ player = "hi", rank = 2, value = 900000 },
				{ player = "maxingoutthelimitYES", rank = 3, value = 800000 },
				{ player = "@.+-_symblchamp_-+.@", rank = 4, value = 293811 },
				{ player = "mr123456789", rank = 5, value = 200000 },
				{ player = "uvwxyz", rank = 6, value = 50000 },
				{ player = "abcdefghijklmnopqrst", rank = 7, value = 25000 },
				{ player = "ABCDEFGHIJKLMNOPQRST", rank = 8, value = 10000 },
				{ player = "UVWXYZ", rank = 9, value = 2 },
			}
		},
	}
	vars.highscoresHandlers = {
		AButtonDown = function()
			if vars.mode == "arcade" then
				self:refreshboards("dailyrun")
			elseif vars.mode == "dailyrun" then
				self:refreshboards("arcade")
			end
		end,

		BButtonDown = function()
			if save.sfx then assets.sfx_back:play() end
			scenemanager:transitionscene(title)
		end
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.highscoresHandlers)
	end)

	self:refreshboards(vars.mode)

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
		if vars.mode == "arcade" then
			assets.full_circle:drawTextAligned(text('arcademode'), 200, 10, kTextAlignment.center)
			assets.half_circle:drawTextAligned(text('highscores'), 200, 25, kTextAlignment.center)
		elseif vars.mode == "dailyrun" then
			assets.full_circle:drawTextAligned(text('dailyrun'), 200, 10, kTextAlignment.center)
			if pd.getGMTTime().hour < 23 then
				assets.half_circle:drawTextAligned(text('todaysscores') .. '   ⏰ ' .. (24 - pd.getGMTTime().hour) .. text('hrs'), 200, 25, kTextAlignment.center)
			else
				if pd.getGMTTime().minute < 59 then
					assets.half_circle:drawTextAligned(text('todaysscores') .. '   ⏰ ' .. (60 - pd.getGMTTime().minute) .. text('mins'), 200, 25, kTextAlignment.center)
				else
					assets.half_circle:drawTextAligned(text('todaysscores') .. '   ⏰ ' .. (60 - pd.getGMTTime().second) .. text('secs'), 200, 25, kTextAlignment.center)
				end
			end
		end
		if vars.result.scores ~= nil and next(vars.result.scores) ~= nil then
			for _, v in ipairs(vars.results.scores) do
				if v.rank <= 9 then
					assets.half_circle:drawTextAligned(ordinal(v.rank), 80, 30 + (15 * v.rank), kTextAlignment.right)
					assets.full_circle:drawText(v.player, 90, 30 + (15 * v.rank))
					assets.half_circle:drawTextAligned(commalize(v.value), 340, 30 + (15 * v.rank), kTextAlignment.right)
				end
			end
		elseif vars.result == "fail" then
			assets.half_circle:drawTextAligned(text('failedscores'), 200, 110, kTextAlignment.center)
		else
			if vars.loading then
				assets.half_circle:drawTextAligned(text('gettingscores'), 200, 110, kTextAlignment.center)
			else
				assets.half_circle:drawTextAligned(text('emptyscores_' .. vars.mode), 200, 110, kTextAlignment.center)
			end
		end
		if vars.best.rank ~= nil then
			assets.full_circle:drawTextAligned(text('lbscore1') .. commalize(vars.best.value) .. text('lbscore2') .. ordinal(1) .. text('lbscore3'), 200, 185, kTextAlignment.center)
		end
		if vars.loading then
			assets.half_circle:drawText(text('inasec'), 65, 205)
		else
			if vars.mode == "arcade" then
				assets.half_circle:drawText(text('dailyscores'), 65, 205)
			elseif vars.mode == "dailyrun" then
				assets.half_circle:drawText(text('arcadescores'), 65, 205)
			end
		end
		assets.half_circle:drawText(text('back'), 70, 220)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		assets.fg:draw(0, 0)
	end)

	self:add()
end

function highscores:refreshboards(mode)
	if not vars.loading then
		vars.result = {}
		vars.best = {}
		vars.loading = true
		vars.mode = mode
		if pd.isSimulator == 1 then
			pd.scoreboards.getScoreboards(function(status, result)
				printTable(status)
				printTable(result)
			end)
		end
		pd.scoreboards.getScores(vars.mode, function(status, result)
			if pd.isSimulator == 1 then
				printTable(status)
				printTable(result)
			end
			if status.code == "OK" then
				vars.result = result
			else
				vars.result = "fail"
			end
			vars.loading = false
		end)
		pd.scoreboards.getPersonalBest(vars.mode, function(status, result)
			if status.code == "OK" then
				vars.best = result
			end
		end)
	end
end

function highscores:update()
	local gmt = pd.getGMTTime()
	if gmt.hour == 0 and gmt.minute == 0 and gmt.second == 0 and not vars.loading and vars.mode == "dailyrun" then
		self:refreshboards(vars.mode)
	end
end