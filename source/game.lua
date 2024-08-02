import 'Tanuk_CodeSequence'

-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local random <const> = math.random
local floor <const> = math.floor
local ceil <const> = math.ceil
local tris_x <const> = {140, 170, 200, 230, 260, 110, 140, 170, 200, 230, 260, 290, 110, 140, 170, 200, 230, 260, 290}
local tris_y <const> = {70, 70, 70, 70, 70, 120, 120, 120, 120, 120, 120, 120, 170, 170, 170, 170, 170, 170, 170}
local tris_flip <const> = {true, false, true, false, true, true, false, true, false, true, false, true, false, true, false, true, false, true, false}
local text <const> = gfx.getLocalizedText
local min <const> = math.min
local exp <const> = math.exp
local flash <const> = pd.getReduceFlashing()

class('game').extends(gfx.sprite) -- Create the scene's class
function game:init(...)
	game.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage(vars.mode)
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			if vars.can_do_stuff then
				menu:addMenuItem(text((vars.mode == "zen" and 'imdone') or 'endgame'), function()
					self:endround()
				end)
				if vars.mode == "arcade" then
					menu:addMenuItem(text('restart'), function()
						self:restart()
					end)
				end
			end
			menu:addCheckmarkMenuItem(text('flip'), save.flip, function()
				save.flip = not save.flip
			end)
		end
	end

	assets = {
		cursor_false = gfx.image.new('images/cursor'),
		cursor_true = gfx.image.new('images/cursor_pulse'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		clock = gfx.font.new('fonts/clock'),
		hexa = gfx.imagetable.new('images/hexa_' .. tostring(flash)),
		sfx_move = smp.new('audio/sfx/move'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
		sfx_swap = smp.new('audio/sfx/swap'),
		sfx_hexa = smp.new('audio/sfx/hexa'),
		sfx_vine = smp.new('audio/sfx/vine'),
		sfx_boom = smp.new('audio/sfx/boom'),
		sfx_select = smp.new('audio/sfx/select'),
		sfx_count = smp.new('audio/sfx/count'),
		sfx_start = smp.new('audio/sfx/start'),
		sfx_end = smp.new('audio/sfx/end'),
		sfx_hexaprep = smp.new('audio/sfx/hexaprep'),
		powerup_double_up = gfx.imagetable.new('images/powerup_double_up'),
		powerup_double_down = gfx.imagetable.new('images/powerup_double_down'),
		powerup_bomb_up = gfx.imagetable.new('images/powerup_bomb_up'),
		powerup_bomb_down = gfx.imagetable.new('images/powerup_bomb_down'),
		powerup_wild_up = gfx.imagetable.new('images/powerup_wild_up'),
		powerup_wild_down = gfx.imagetable.new('images/powerup_wild_down'),
		label_3 = gfx.image.new('images/label_3'),
		label_2 = gfx.image.new('images/label_2'),
		label_1 = gfx.image.new('images/label_1'),
		label_go = gfx.image.new('images/label_go'),
		label_double = gfx.image.new('images/label_double'),
		label_bomb = gfx.image.new('images/label_bomb'),
		label_wild = gfx.image.new('images/label_wild'),
		modal = gfx.image.new('images/modal'),
		bg_tile = gfx.image.new('images/bg_tile'),
		stars = gfx.image.new('images/stars_large'),
		half = gfx.image.new('images/half'),
		outline = gfx.image.new('images/outline'),
	}

	vars = {
		mode = args[1], -- "arcade" or "zen" or "dailyrun"
		tris = {},
		slot = 1,
		score = 0,
		combo = 0,
		anim_hexa = pd.timer.new(1, 11, 11),
		anim_cursor_x = pd.timer.new(1, 106, 106),
		anim_cursor_y = pd.timer.new(1, 42, 42),
		anim_label = pd.timer.new(0, 400, 400),
		anim_modal = pd.timer.new(0, 400, 400),
		anim_bg_stars_x = pd.timer.new(10000, 0, -399),
		anim_bg_stars_y = pd.timer.new(15000, 0, -239),
		anim_powerup = pd.timer.new(700, 1, 4.99),
		can_do_stuff = false,
		ended = false,
		moves = 0,
		hexas = 0,
		movesbonus = 5,
		active_hexa = false,
		active_swap = false,
		boomed = false,
		lastdir = false,
		skippedfanfare = false,
	}
	vars.gameHandlers = {
		leftButtonDown = function()
			if vars.can_do_stuff then
				vars.lastdir = false
				if vars.slot == 2 then
					vars.slot = 1
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 106, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				elseif vars.slot == 5 then
					vars.slot = 4
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 137, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				elseif vars.slot == 4 then
					vars.slot = 3
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 78, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				else
					if save.sfx then assets.sfx_bonk:play() end
				end
			end
		end,

		rightButtonDown = function()
			if vars.can_do_stuff then
				vars.lastdir = true
				if vars.slot == 1 then
					vars.slot = 2
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 166, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				elseif vars.slot == 3 then
					vars.slot = 4
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 137, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				elseif vars.slot == 4 then
					vars.slot = 5
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 197, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				else
					if save.sfx then assets.sfx_bonk:play() end
				end
			end
		end,

		upButtonDown = function()
			if vars.can_do_stuff then
				if vars.slot == 3 or vars.slot == 4 or vars.slot == 5 then
					if vars.lastdir then
						vars.slot = 2
						vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 166, pd.easingFunctions.outBack)
						vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
						if save.sfx then assets.sfx_move:play() end
					else
						vars.slot = 1
						vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 106, pd.easingFunctions.outBack)
						vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
						if save.sfx then assets.sfx_move:play() end
					end
				else
					if save.sfx then assets.sfx_bonk:play() end
				end
			end
		end,

		downButtonDown = function()
			if vars.can_do_stuff then
				if vars.slot == 1 then
					vars.slot = 3
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 78, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				elseif vars.slot == 2 then
					vars.slot = 5
					vars.anim_cursor_x:resetnew(80, vars.anim_cursor_x.value, 197, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(80, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				else
					if save.sfx then assets.sfx_bonk:play() end
				end
			end
		end,

		AButtonDown = function()
			if vars.can_do_stuff then
				if save.flip then
					self:swap(vars.slot, false)
				else
					self:swap(vars.slot, true)
				end
			end
		end,

		BButtonDown = function()
			if vars.can_do_stuff then
				if save.flip then
					self:swap(vars.slot, true)
				else
					self:swap(vars.slot, false)
				end
			end
		end,
	}
	vars.losingHandlers = {
		AButtonDown = function()
			if vars.ended and not vars.skippedfanfare then
				self:ersi()
			end
		end
	}
	vars.loseHandlers = {
		AButtonDown = function()
			if vars.mode == "dailyrun" then
				fademusic()
				scenemanager:transitionscene(highscores, vars.mode)
			else
				fademusic()
				scenemanager:transitionscene(game, vars.mode)
			end
		end,

		BButtonDown = function()
			fademusic()
			scenemanager:transitionscene(title, false, vars.mode)
		end
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(vars.gameHandlers)
	end)

	assets.bg = gfx.image.new('images/bg_' .. vars.mode)

	if vars.mode == "dailyrun" then
		math.randomseed(pd.getGMTTime().year .. pd.getGMTTime().month .. pd.getGMTTime().day)
		save.lastdaily = pd.getGMTTime()
	else
		math.randomseed(playdate.getSecondsSinceEpoch())
		if flash then
			vars.anim_bg_tile_x = pd.timer.new(1, 0, 0)
			vars.anim_bg_tile_y = pd.timer.new(1, 0, 0)
		else
			vars.anim_bg_tile_x = pd.timer.new(30000, 0, -399)
			vars.anim_bg_tile_y = pd.timer.new(28000, 0, -239)
			vars.anim_bg_tile_x.repeats = true
			vars.anim_bg_tile_y.repeats = true
		end
	end

	vars.anim_cursor_x.discardOnCompletion = false
	vars.anim_cursor_y.discardOnCompletion = false
	vars.anim_label.discardOnCompletion = false
	vars.anim_modal.discardOnCompletion = false
	vars.anim_hexa.discardOnCompletion = false
	vars.anim_powerup.repeats = true
	vars.anim_bg_stars_x.repeats = true
	vars.anim_bg_stars_y.repeats = true

	local newcolor
	local newpowerup
	for i = 1, 19 do
		newcolor, newpowerup = self:randomizetri()
		vars.tris[i] = {index = i, color = newcolor, powerup = newpowerup}
	end

	if vars.mode ~= "zen" then
		assets.ui = gfx.image.new('images/ui_arcade')
		vars.timer = pd.timer.new(45000, 45000, 0)
		vars.timer.delay = 4000
		vars.old_timer_value = 45000
		vars.timer.timerEndedCallback = function()
			self:endround()
		end
		pd.timer.performAfterDelay(1000, function()
			if save.sfx then assets.sfx_count:play() end
			assets.draw_label = assets.label_3
			vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
		end)
		pd.timer.performAfterDelay(2000, function()
			if save.sfx then assets.sfx_count:play() end
			assets.draw_label = assets.label_2
			vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
		end)
		pd.timer.performAfterDelay(3000, function()
			if save.sfx then assets.sfx_count:play() end
			assets.draw_label = assets.label_1
			vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
		end)
		pd.timer.performAfterDelay(4000, function()
			vars.timer.delay = 0
			assets.draw_label = assets.label_go
			vars.anim_label:resetnew(1000, 400, -200, pd.easingFunctions.linear)
			vars.anim_label.timerEndedCallback = function()
				assets.draw_label = nil
			end
			if save.sfx then assets.sfx_start:play() end
			newmusic('audio/music/arcade' .. math.random(1, 3), true)
			vars.can_do_stuff = true
			self:check()
		end)
	elseif vars.mode == "zen" then
		assets.ui = gfx.image.new('images/ui_zen')
		pd.timer.performAfterDelay(1000, function()
			newmusic('audio/music/zen' .. math.random(1, 2), true)
			vars.can_do_stuff = true
			self:check()
		end)
	end

	class('game_canvas').extends(gfx.sprite)
	function game_canvas:init()
		game_canvas.super.init(self)
		self:setCenter(0, 0)
		self:setSize(400, 240)
		self:setOpaque(true)
		self:add()
	end
	function game_canvas:draw()
		assets.bg:draw(0, 0)
		if vars.mode ~= "dailyrun" then
			assets.bg_tile:draw((floor(vars.anim_bg_tile_x.value / 2) * 2) - 1, (floor(vars.anim_bg_tile_y.value / 2) * 2) - 1)
		end
		assets.stars:draw(vars.anim_bg_stars_x.value, vars.anim_bg_stars_y.value)
		if assets.draw_label ~= nil then assets.draw_label:draw(vars.anim_label.value, -13) end
		assets.ui:draw(0, 0)
		for i = 1, 19 do
			game:tri(tris_x[i], tris_y[i], tris_flip[i], vars.tris[i].color, vars.tris[i].powerup)
		end
		assets.outline:draw(79, 44)
		if vars.active_swap and not flash then
			assets.cursor_true:draw(vars.anim_cursor_x.value - 1.5, vars.anim_cursor_y.value - 2)
		else
			assets.cursor_false:draw(vars.anim_cursor_x.value, vars.anim_cursor_y.value)
		end
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		if vars.mode ~= "zen" then
			assets.half_circle:drawText(text('score'), 10, 10)
			assets.full_circle:drawText(commalize(vars.score), 10, 25)
			if vars.mode == "arcade" then
				assets.half_circle:drawText(text('high'), 10, 45)
				assets.full_circle:drawText(commalize((vars.score > save.score and vars.score) or (save.score)), 10, 60)
			else
				assets.half_circle:drawText(text('seed'), 10, 45)
				assets.full_circle:drawText(pd.getGMTTime().year .. pd.getGMTTime().month .. pd.getGMTTime().day, 10, 60)
			end
			assets.clock:drawText(ceil(vars.timer.value / 1000), 305, 55)
		elseif vars.mode == "zen" then
			assets.half_circle:drawText(text('swaps'), 10, 10)
			assets.full_circle:drawText(commalize(vars.moves), 10, 25)
			assets.half_circle:drawText(text('hexas'), 10, 45)
			assets.full_circle:drawText(commalize(vars.hexas), 10, 60)
		end
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		assets.hexa[math.floor(vars.anim_hexa.value)]:draw(0, 0)
		if not vars.can_do_stuff then
			assets.half:draw(0, 0)
		end
		assets.modal:draw(0, vars.anim_modal.value)
	end

	sprites.canvas = game_canvas()
	sprites.code = Tanuk_CodeSequence({pd.kButtonRight, pd.kButtonUp, pd.kButtonB, pd.kButtonDown, pd.kButtonUp, pd.kButtonB, pd.kButtonDown, pd.kButtonUp, pd.kButtonB}, function() self:boom(true) end)
	self:add()
end

function game:tri(x, y, up, color, powerup)
	if color == "gray" then
		gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
	end
	if color == "black" or color == "gray" then
		if up then
			gfx.fillTriangle(x, y - 25, x + 30, y + 25, x - 30, y + 25)
		else
			gfx.fillTriangle(x, y + 25, x + 30, y - 25, x - 30, y - 25)
		end
		gfx.setColor(gfx.kColorBlack)
	end
	if powerup ~= "" then
		if flash then
			if up then
				assets['powerup_' .. powerup .. '_up'][1]:draw(x - 28, y - 23)
			else
				assets['powerup_' .. powerup .. '_down'][1]:draw(x - 28, y - 23)
			end
		else
			if up then
				assets['powerup_' .. powerup .. '_up'][floor(vars.anim_powerup.value)]:draw(x - 28, y - 23)
			else
				assets['powerup_' .. powerup .. '_down'][floor(vars.anim_powerup.value)]:draw(x - 28, y - 23)
			end
		end
	end
end

function game:swap(slot, dir)
	if not vars.active_hexa and not vars.active_swap then
		vars.active_swap = true
		vars.movesbonus -= 1
		if vars.movesbonus < 0 then vars.movesbonus = 0 end
		pd.timer.performAfterDelay(50, function()
			vars.active_swap = false
		end)
		vars.moves += 1
		save.swaps += 1
		if save.sfx then assets.sfx_swap:play() end
		local tochange
		temp1, temp2, temp3, temp4, temp5, temp6 = self:findslot(slot)
		if slot == 1 then
			tochange = {1, 2, 3, 7, 8, 9}
		elseif slot == 2 then
			tochange = {3, 4, 5, 9, 10, 11}
		elseif slot == 3 then
			tochange = {6, 7, 8, 13, 14, 15}
		elseif slot == 4 then
			tochange = {8, 9, 10, 15, 16, 17}
		elseif slot == 5 then
			tochange = {10, 11, 12, 17, 18, 19}
		end
		if dir then
			vars.tris[tochange[2]] = temp1
			vars.tris[tochange[3]] = temp2
			vars.tris[tochange[6]] = temp3
			vars.tris[tochange[1]] = temp4
			vars.tris[tochange[4]] = temp5
			vars.tris[tochange[5]] = temp6
		else
			vars.tris[tochange[4]] = temp1
			vars.tris[tochange[1]] = temp2
			vars.tris[tochange[2]] = temp3
			vars.tris[tochange[5]] = temp4
			vars.tris[tochange[6]] = temp5
			vars.tris[tochange[3]] = temp6
		end
		self:check()
	end
end

function game:check()
	if vars.can_do_stuff then
		local temp1
		local temp2
		local temp3
		local temp4
		local temp5
		local temp6
		local color
		for i = 1, 5 do
			temp1, temp2, temp3, temp4, temp5, temp6 = self:findslot(i)
			for i = 1, 3 do
				if i == 1 then
					color = "white"
				elseif i == 2 then
					color = "black"
				elseif i == 3 then
					color = "gray"
				end
				if (temp1.color == color or temp1.powerup == "wild") and (temp2.color == color or temp2.powerup == "wild") and (temp3.color == color or temp3.powerup == "wild") and (temp4.color == color or temp4.powerup == "wild") and (temp5.color == color or temp5.powerup == "wild") and (temp6.color == color or temp6.powerup == "wild") then
					self:hexa(temp1, temp2, temp3, temp4, temp5, temp6)
					return
				end
			end
		end
		if vars.combo > 0 then
			vars.combo = 0
		end
	end
end

function game:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, yes)
	if yes then
		if (temp1.color == "white" and temp1.powerup ~= "wild") or (temp2.color == "white" and temp2.powerup ~= "wild") or (temp3.color == "white" and temp3.powerup ~= "wild") or (temp4.color == "white" and temp4.powerup ~= "wild") or (temp5.color == "white" and temp5.powerup ~= "wild") or (temp6.color == "white" and temp6.powerup ~= "wild") then
			temp1.color = "gray"
			temp2.color = "gray"
			temp3.color = "gray"
			temp4.color = "gray"
			temp5.color = "gray"
			temp6.color = "gray"
		else
			temp1.color = "white"
			temp2.color = "white"
			temp3.color = "white"
			temp4.color = "white"
			temp5.color = "white"
			temp6.color = "white"
		end
	else
		temp1.color = vars.tempcolor1
		temp2.color = vars.tempcolor2
		temp3.color = vars.tempcolor3
		temp4.color = vars.tempcolor4
		temp5.color = vars.tempcolor5
		temp6.color = vars.tempcolor6
	end
end

function game:hexa(temp1, temp2, temp3, temp4, temp5, temp6)
	pd.inputHandlers.pop()
	vars.active_hexa = true
	vars.tempcolor1 = temp1.color
	vars.tempcolor2 = temp2.color
	vars.tempcolor3 = temp3.color
	vars.tempcolor4 = temp4.color
	vars.tempcolor5 = temp5.color
	vars.tempcolor6 = temp6.color
	assets.sfx_hexaprep:setRate(1 + (0.1 * vars.combo))
	if save.sfx then assets.sfx_hexaprep:play() end
	self:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, true)
	pd.timer.performAfterDelay(100, function()
		if not flash then
			self:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, false)
		end
	end)
	pd.timer.performAfterDelay(200, function()
		if save.sfx then assets.sfx_hexaprep:play() end
		if flash then
			self:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, false)
		else
			self:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, true)
		end
	end)
	pd.timer.performAfterDelay(300, function()
		if not flash then
			self:colorflip(temp1, temp2, temp3, temp4, temp5, temp6, false)
		end
	end)
	pd.timer.performAfterDelay(400, function()
		if vars.can_do_stuff or (not vars.can_do_stuff and vars.ended) then
			vars.hexas += 1
			save.hexas += 1
			vars.combo += 1
			shakies()
			shakies_y()
			if temp1.powerup == "double" or temp2.powerup == "double" or temp3.powerup == "double" or temp4.powerup == "double" or temp5.powerup == "double" or temp6.powerup == "double" then
				if (temp1.color == "white" and temp1.powerup ~= "wild") or (temp2.color == "white" and temp2.powerup ~= "wild") or (temp3.color == "white" and temp3.powerup ~= "wild") or (temp4.color == "white" and temp4.powerup ~= "wild") or (temp5.color == "white" and temp5.powerup ~= "wild") or (temp6.color == "white" and temp6.powerup ~= "wild") then
					vars.score += 200 * vars.combo
				elseif (temp1.color == "gray" and temp1.powerup ~= "wild") or (temp2.color == "gray" and temp2.powerup ~= "wild") or (temp3.color == "gray" and temp3.powerup ~= "wild") or (temp4.color == "gray" and temp4.powerup ~= "wild") or (temp5.color == "gray" and temp5.powerup ~= "wild") or (temp6.color == "gray" and temp6.powerup ~= "wild") then
					vars.score += 300 * vars.combo
				elseif (temp1.color == "black" and temp1.powerup ~= "wild") or (temp2.color == "black" and temp2.powerup ~= "wild") or (temp3.color == "black" and temp3.powerup ~= "wild") or (temp4.color == "black" and temp4.powerup ~= "wild") or (temp5.color == "black" and temp5.powerup ~= "wild") or (temp6.color == "black" and temp6.powerup ~= "wild") then
					vars.score += 400 * vars.combo
				end
				if save.sfx then assets.sfx_select:play() end
				assets.draw_label = assets.label_double
				vars.anim_label:resetnew(1200, 400, -200, pd.easingFunctions.linear)
				vars.anim_label.timerEndedCallback = function()
					assets.draw_label = nil
				end
				if (vars.mode ~= "zen") and vars.can_do_stuff then
					vars.timer:resetnew(min(vars.timer.value + (11000 * math.exp(-0.105 * vars.hexas)) + 2750, 60000), min(vars.timer.value + (11000 * math.exp(-0.105 * vars.hexas)) + 2750, 60000), 0)
				end
			else
				if (temp1.color == "white" and temp1.powerup ~= "wild") or (temp2.color == "white" and temp2.powerup ~= "wild") or (temp3.color == "white" and temp3.powerup ~= "wild") or (temp4.color == "white" and temp4.powerup ~= "wild") or (temp5.color == "white" and temp5.powerup ~= "wild") or (temp6.color == "white" and temp6.powerup ~= "wild") then
					vars.score += 100 * vars.combo
				elseif (temp1.color == "gray" and temp1.powerup ~= "wild") or (temp2.color == "gray" and temp2.powerup ~= "wild") or (temp3.color == "gray" and temp3.powerup ~= "wild") or (temp4.color == "gray" and temp4.powerup ~= "wild") or (temp5.color == "gray" and temp5.powerup ~= "wild") or (temp6.color == "gray" and temp6.powerup ~= "wild") then
					vars.score += 150 * vars.combo
				elseif (temp1.color == "black" and temp1.powerup ~= "wild") or (temp2.color == "black" and temp2.powerup ~= "wild") or (temp3.color == "black" and temp3.powerup ~= "wild") or (temp4.color == "black" and temp4.powerup ~= "wild") or (temp5.color == "black" and temp5.powerup ~= "wild") or (temp6.color == "black" and temp6.powerup ~= "wild") then
					vars.score += 200 * vars.combo
				end
				if (vars.mode ~= "zen") and vars.can_do_stuff then
					vars.timer:resetnew(min(vars.timer.value + (7000 * math.exp(-0.105 * vars.hexas)) + 1750, 60000), min(vars.timer.value + (7000 * math.exp(-0.105 * vars.hexas)) + 1750, 60000), 0)
				end
			end
			vars.score += 10 * vars.movesbonus
			vars.movesbonus = 5
			if temp1.powerup == "bomb" or temp2.powerup == "bomb" or temp3.powerup == "bomb" or temp4.powerup == "bomb" or temp5.powerup == "bomb" or temp6.powerup == "bomb" then
				for i = 1, 19 do
					newcolor, newpowerup = self:randomizetri()
					vars.tris[i] = {index = i, color = newcolor, powerup = newpowerup}
				end
				if save.sfx then assets.sfx_boom:play() end
				assets.draw_label = assets.label_bomb
				vars.anim_label:resetnew(1200, 400, -200, pd.easingFunctions.linear)
				vars.anim_label.timerEndedCallback = function()
					assets.draw_label = nil
				end
			else
				temp1.color, temp1.powerup = self:randomizetri()
				temp2.color, temp2.powerup = self:randomizetri()
				temp3.color, temp3.powerup = self:randomizetri()
				temp4.color, temp4.powerup = self:randomizetri()
				temp5.color, temp5.powerup = self:randomizetri()
				temp6.color, temp6.powerup = self:randomizetri()
				if save.sfx then
					local random = random(1, 1000)
					if random == 1 then
						assets.sfx_vine:play()
					else
						assets.sfx_hexa:play()
					end
				end
			end
			vars.anim_hexa:resetnew(600, 1, 11)
			pd.timer.performAfterDelay(200, function()
				pd.inputHandlers.push(vars.gameHandlers)
				vars.active_hexa = false
				self:check()
			end)
		end
	end)
end

function game:boom(boomed)
	if ((boomed and not vars.boomed) or (not boomed)) and vars.can_do_stuff then
		shakies()
		shakies_y()
		if boomed then
			vars.boomed = true
		end
		for i = 1, 19 do
			newcolor, newpowerup = self:randomizetri()
			vars.tris[i] = {index = i, color = newcolor, powerup = newpowerup}
		end
		if save.sfx then assets.sfx_boom:play() end
		assets.draw_label = assets.label_bomb
		vars.anim_label:resetnew(1200, 400, -100, pd.easingFunctions.linear)
	end
end

function game:findslot(slot)
	local temp1
	local temp2
	local temp3
	local temp4
	local temp5
	local temp6
	if slot == 1 then
		-- 1, 2, 3, 7, 8, 9
		temp1 = vars.tris[1]
		temp2 = vars.tris[2]
		temp3 = vars.tris[3]
		temp4 = vars.tris[7]
		temp5 = vars.tris[8]
		temp6 = vars.tris[9]
	elseif slot == 2 then
		-- 3, 4, 5, 9, 10, 11
		temp1 = vars.tris[3]
		temp2 = vars.tris[4]
		temp3 = vars.tris[5]
		temp4 = vars.tris[9]
		temp5 = vars.tris[10]
		temp6 = vars.tris[11]
	elseif slot == 3 then
		-- 6, 7, 8, 13, 14, 15
		temp1 = vars.tris[6]
		temp2 = vars.tris[7]
		temp3 = vars.tris[8]
		temp4 = vars.tris[13]
		temp5 = vars.tris[14]
		temp6 = vars.tris[15]
	elseif slot == 4 then
		-- 8, 9, 10, 15, 16, 17
		temp1 = vars.tris[8]
		temp2 = vars.tris[9]
		temp3 = vars.tris[10]
		temp4 = vars.tris[15]
		temp5 = vars.tris[16]
		temp6 = vars.tris[17]
	elseif slot == 5 then
		-- 10, 11, 12, 17, 18, 19
		temp1 = vars.tris[10]
		temp2 = vars.tris[11]
		temp3 = vars.tris[12]
		temp4 = vars.tris[17]
		temp5 = vars.tris[18]
		temp6 = vars.tris[19]
	end
	return temp1, temp2, temp3, temp4, temp5, temp6
end

function game:randomizetri()
	local randomcolor = random(1, 3)
	local randompowerup = random(1, 50)
	local color
	local powerup
	if randomcolor == 1 then
		color = "black"
	elseif randomcolor == 2 then
		color = "white"
	elseif randomcolor == 3 then
		color = "gray"
	end
	if vars.mode ~= "zen" then
		if randompowerup == 1 or randompowerup == 2 or randompowerup == 3 then
			powerup = "double"
		elseif randompowerup == 4 then
			powerup = "bomb"
		elseif randompowerup == 5 then
			powerup = "wild"
		else
			powerup = ""
		end
	else
		powerup = ""
	end
	return color, powerup
end

function game:restart()
	fademusic(1)
	self:boom(false)
	vars.can_do_stuff = false
	vars.score = 0
	vars.boomed = false
	vars.moves = 0
	vars.hexas = 0
	vars.anim_hexa:resetnew(1, 11, 11)
	vars.active_hexa = false
	vars.active_swap = false
	vars.slot = 1
	vars.anim_cursor_x:resetnew(1, 106, 106)
	vars.anim_cursor_y:resetnew(1, 42, 42)
	vars.anim_label:resetnew(0, 400, 400)
	vars.timer:resetnew(45000, 45000, 0)
	vars.timer:pause()
	vars.old_timer_value = 45000
	if #playdate.inputHandlers == 1 then
		pd.inputHandlers.push(vars.gameHandlers)
	end
	vars.old_timer_value = 45000
	vars.timer.timerEndedCallback = function()
		self:endround()
	end
	pd.timer.performAfterDelay(1000, function()
		if save.sfx then assets.sfx_count:play() end
		assets.draw_label = assets.label_3
		vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
	end)
	pd.timer.performAfterDelay(2000, function()
		if save.sfx then assets.sfx_count:play() end
		assets.draw_label = assets.label_2
		vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
	end)
	pd.timer.performAfterDelay(3000, function()
		if save.sfx then assets.sfx_count:play() end
		assets.draw_label = assets.label_1
		vars.anim_label:resetnew(1000, 350, -200, pd.easingFunctions.linear)
	end)
	pd.timer.performAfterDelay(4000, function()
		vars.timer:start()
		assets.draw_label = assets.label_go
		vars.anim_label:resetnew(1000, 400, -200, pd.easingFunctions.linear)
		vars.anim_label.timerEndedCallback = function()
			assets.draw_label = nil
		end
		if save.sfx then assets.sfx_start:play() end
		newmusic('audio/music/arcade' .. math.random(1, 3), true)
		vars.can_do_stuff = true
		self:check()
	end)
end

function game:ersi()
	vars.skippedfanfare = true
	pd.inputHandlers.push(vars.loseHandlers, true)
	if vars.mode == "zen" then
		gfx.pushContext(assets.modal)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				assets.full_circle:drawTextAligned(text('zen1'), 240, 50, kTextAlignment.center)
				if vars.moves == 1 then
					assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2b'), 240, 90, kTextAlignment.center)
				else
					assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2a'), 240, 90, kTextAlignment.center)
				end
				if vars.hexas == 1 then
					assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4b'), 240, 105, kTextAlignment.center)
				else
					assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4a'), 240, 105, kTextAlignment.center)
				end
				assets.full_circle:drawTextAligned(text(vars.mode .. '_message' .. random(1, 10)), 190, 150, kTextAlignment.center)
				assets.half_circle:drawText(text('newgame') .. ' ' .. text('back'), 40, 205)
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		gfx.popContext()
	else
		gfx.pushContext(assets.modal)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				assets.full_circle:drawTextAligned(text('score1') .. commalize(vars.score) .. text('score2'), 240, 50, kTextAlignment.center)
				if vars.moves == 1 then
					assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2b'), 240, 90, kTextAlignment.center)
				else
					assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2a'), 240, 90, kTextAlignment.center)
				end
				if vars.hexas == 1 then
					assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4b'), 240, 105, kTextAlignment.center)
				else
					assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4a'), 240, 105, kTextAlignment.center)
				end
				assets.full_circle:drawTextAligned(text(vars.mode .. '_message' .. random(1, 10)), 190, 150, kTextAlignment.center)
				if vars.mode == "dailyrun" then
					assets.half_circle:drawText(text('showsdailyscores') .. ' ' .. text('back'), 40, 205)
				else
					assets.half_circle:drawText(text('newgame') .. ' ' .. text('back'), 40, 205)
				end
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		gfx.popContext()
	end
end

function game:endround()
	vars.can_do_stuff = false
	vars.ended = true
	fademusic(1)
	if not save.skipfanfare then
		pd.inputHandlers.push(vars.losingHandlers, true)
	end
	if vars.mode ~= "zen" then
		vars.timer:pause()
		if save.sfx then assets.sfx_end:play() end
		pd.timer.performAfterDelay(2000, function()
			if catalog then
				if vars.mode == "dailyrun" then
					if save.lastdaily.year == pd.getGMTTime().year and save.lastdaily.month == pd.getGMTTime().month and save.lastdaily.day == pd.getGMTTime().day then
						save.lastdaily.score = vars.score
						pd.scoreboards.addScore(vars.mode, vars.score, function(status, result)
							if status.code == "OK" then
								save.lastdaily.sent = true
							else
								save.lastdaily.sent = false
							end
							if pd.isSimulator == 1 then
								printTable(status)
								printTable(result)
							end
						end)
					end
				else
					pd.scoreboards.addScore('arcade', vars.score, function(status, result)
						if pd.isSimulator == 1 then
							printTable(status)
							printTable(result)
						end
					end)
				end
			end
			if vars.score > save.score and vars.mode == "arcade" then save.score = vars.score end
			newmusic('audio/music/lose')
			vars.anim_modal:resetnew(500, 240, 0, pd.easingFunctions.outBack)
			if save.skipfanfare then
				self:ersi()
			else
				pd.timer.performAfterDelay(548, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
								assets.full_circle:drawTextAligned(text('score1') .. commalize(vars.score) .. text('score2'), 240, 50, kTextAlignment.center)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(2146, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							if vars.moves == 1 then
								assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2b'), 240, 90, kTextAlignment.center)
							else
								assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2a'), 240, 90, kTextAlignment.center)
							end
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(3957, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							if vars.hexas == 1 then
								assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4b'), 240, 105, kTextAlignment.center)
							else
								assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4a'), 240, 105, kTextAlignment.center)
							end
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(6138, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							assets.full_circle:drawTextAligned(text(vars.mode .. '_message' .. random(1, 10)), 190, 150, kTextAlignment.center)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(8976, function()
					if not vars.skippedfanfare then
						pd.inputHandlers.push(vars.loseHandlers, true)
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							if vars.mode == "dailyrun" then
								assets.half_circle:drawText(text('showsdailyscores') .. ' ' .. text('back'), 40, 205)
							else
								assets.half_circle:drawText(text('newgame') .. ' ' .. text('back'), 40, 205)
							end
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
			end
		end)
	elseif vars.mode == "zen" then
		if save.sfx then assets.sfx_start:play() end
		pd.timer.performAfterDelay(1000, function()
			newmusic('audio/music/zen_end')
			vars.anim_modal:resetnew(500, 240, 0, pd.easingFunctions.outBack)
			if save.skipfanfare then
				self:ersi()
			else
				pd.timer.performAfterDelay(2140, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
								assets.full_circle:drawTextAligned(text('zen1'), 240, 50, kTextAlignment.center)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(3296, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							if vars.moves == 1 then
								assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2b'), 240, 90, kTextAlignment.center)
							else
								assets.full_circle:drawTextAligned(text('stats1') .. commalize(vars.moves) .. text('stats2a'), 240, 90, kTextAlignment.center)
							end
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(4152, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							if vars.hexas == 1 then
								assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4b'), 240, 105, kTextAlignment.center)
							else
								assets.full_circle:drawTextAligned(text('stats3') .. commalize(vars.hexas) .. text('stats4a'), 240, 105, kTextAlignment.center)
							end
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(5297, function()
					if not vars.skippedfanfare then
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							assets.full_circle:drawTextAligned(text(vars.mode .. '_message' .. random(1, 10)), 190, 150, kTextAlignment.center)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
				pd.timer.performAfterDelay(8000, function()
					if not vars.skippedfanfare then
						pd.inputHandlers.push(vars.loseHandlers, true)
						gfx.pushContext(assets.modal)
							gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
							assets.half_circle:drawText(text('newgame') .. ' ' .. text('back'), 40, 205)
							gfx.setImageDrawMode(gfx.kDrawModeCopy)
						gfx.popContext()
					end
				end)
			end
		end)
	end
end

function game:update()
	if save.crank and vars.can_do_stuff and not vars.active_hexa then
		local ticks = pd.getCrankTicks(6)
		if ticks >= 1 then
			for i = 1, ticks do
				if save.flip then
					self:swap(vars.slot, false)
				else
					self:swap(vars.slot, true)
				end
			end
		elseif ticks <= -1 then
			for i = 1, -ticks do
				if save.flip then
					self:swap(vars.slot, true)
				else
					self:swap(vars.slot, false)
				end
			end
		end
	end
	if vars.mode ~= "zen" then
		if vars.old_timer_value > 10000 and vars.timer.value <= 10000 then
			shakies(500, 1)
			shakies_y(750, 1)
			if save.sfx then assets.sfx_count:play() end
		end
		if vars.old_timer_value > 9000 and vars.timer.value <= 9000 then
			shakies(500, 2)
			shakies_y(750, 2)
			if save.sfx then assets.sfx_count:play() end
		end
		if vars.old_timer_value > 8000 and vars.timer.value <= 8000 then
			shakies(500, 3)
			shakies_y(750, 3)
			if save.sfx then assets.sfx_count:play() end
		end
		if vars.old_timer_value > 7000 and vars.timer.value <= 7000 then
			shakies(500, 4)
			shakies_y(750, 4)
			if save.sfx then assets.sfx_count:play() end
		end
		if vars.old_timer_value > 6000 and vars.timer.value <= 6000 then
			shakies(500, 5)
			shakies_y(750, 5)
			if save.sfx then assets.sfx_count:play() end
		end
		if vars.old_timer_value > 5000 and vars.timer.value <= 5000 then
			shakies(500, 6)
			shakies_y(750, 6)
			if save.sfx then assets.sfx_count:play() end
		end
		if vars.old_timer_value > 4000 and vars.timer.value <= 4000 then
			shakies(500, 7)
			shakies_y(750, 7)
			if save.sfx then assets.sfx_count:play() end
		end
		if vars.old_timer_value > 3000 and vars.timer.value <= 3000 then
			shakies(500, 8)
			shakies_y(750, 8)
			if save.sfx then assets.sfx_count:play() end
		end
		if vars.old_timer_value > 2000 and vars.timer.value <= 2000 then
			shakies(500, 9)
			shakies_y(750, 9)
			if save.sfx then assets.sfx_count:play() end
		end
		if vars.old_timer_value > 1000 and vars.timer.value <= 1000 then
			shakies(500, 10)
			shakies_y(750, 10)
			if save.sfx then assets.sfx_count:play() end
		end
		vars.old_timer_value = vars.timer.value
	end
end