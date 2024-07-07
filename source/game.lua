-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local random <const> = math.random
local floor <const> = math.floor
local tris_x <const> = {140, 170, 200, 230, 260, 110, 140, 170, 200, 230, 260, 290, 110, 140, 170, 200, 230, 260, 290}
local tris_y <const> = {70, 70, 70, 70, 70, 120, 120, 120, 120, 120, 120, 120, 170, 170, 170, 170, 170, 170, 170}
local tris_flip <const> = {true, false, true, false, true, true, false, true, false, true, false, true, false, true, false, true, false, true, false}
local text <const> = gfx.getLocalizedText
local lastdir

class('game').extends(gfx.sprite) -- Create the scene's class
function game:init(...)
	game.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
		if vars.mode == "zen" and vars.can_do_stuff then
			menu:addMenuItem(text('imdone'), function()
				self:endround()
			end)
		end
		if vars.mode == "arcade" and vars.can_do_stuff then
			menu:addMenuItem(text('callithere'), function()
				self:endround()
			end)
		end
	end

	assets = {
		cursor = gfx.image.new('images/cursor'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		hexa = gfx.imagetable.new('images/hexa'),
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
		sfx_lose = smp.new('audio/music/lose'),
		sfx_zen_end = smp.new('audio/music/zen_end'),
		powerup_double_up = gfx.image.new('images/powerup_double_up'),
		powerup_double_down = gfx.image.new('images/powerup_double_down'),
		powerup_bomb_up = gfx.image.new('images/powerup_bomb_up'),
		powerup_bomb_down = gfx.image.new('images/powerup_bomb_down'),
		powerup_wild_up = gfx.image.new('images/powerup_wild_up'),
		powerup_wild_down = gfx.image.new('images/powerup_wild_down'),
		label_3 = gfx.image.new('images/label_3'),
		label_2 = gfx.image.new('images/label_2'),
		label_1 = gfx.image.new('images/label_1'),
		label_go = gfx.image.new('images/label_go'),
		label_double = gfx.image.new('images/label_double'),
		label_bomb = gfx.image.new('images/label_bomb'),
		label_wild = gfx.image.new('images/label_wild'),
		modal = gfx.image.new('images/modal'),
	}

	assets.draw_label = assets.label_double

	vars = {
		mode = args[1], -- "arcade" or "zen"
		tris = {},
		slot = 1,
		score = 0,
		combo = 0,
		anim_hexa = pd.timer.new(1, 11, 11),
		anim_cursor_x = pd.timer.new(1, 105, 105),
		anim_cursor_y = pd.timer.new(1, 42, 42),
		anim_label = pd.timer.new(0, 400, 400),
		anim_modal = pd.timer.new(0, 400, 400),
		can_do_stuff = false,
		moves = 0,
		hexas = 0,
	}
	vars.gameHandlers = {
		leftButtonDown = function()
			if vars.can_do_stuff then
				lastdir = false
				if vars.slot == 2 then
					vars.slot = 1
					vars.anim_cursor_x:resetnew(150, vars.anim_cursor_x.value, 105, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(150, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				elseif vars.slot == 5 then
					vars.slot = 4
					vars.anim_cursor_x:resetnew(150, vars.anim_cursor_x.value, 137, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(137, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				elseif vars.slot == 4 then
					vars.slot = 3
					vars.anim_cursor_x:resetnew(150, vars.anim_cursor_x.value, 78, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(150, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				else
					if save.sfx then assets.sfx_bonk:play() end
				end
			end
		end,

		rightButtonDown = function()
			if vars.can_do_stuff then
				lastdir = true
				if vars.slot == 1 then
					vars.slot = 2
					vars.anim_cursor_x:resetnew(150, vars.anim_cursor_x.value, 165, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(150, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				elseif vars.slot == 3 then
					vars.slot = 4
					vars.anim_cursor_x:resetnew(150, vars.anim_cursor_x.value, 137, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(150, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				elseif vars.slot == 4 then
					vars.slot = 5
					vars.anim_cursor_x:resetnew(150, vars.anim_cursor_x.value, 197, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(150, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				else
					if save.sfx then assets.sfx_bonk:play() end
				end
			end
		end,

		upButtonDown = function()
			if vars.can_do_stuff then
				if vars.slot == 3 or vars.slot == 4 or vars.slot == 5 then
					if lastdir then
						vars.slot = 2
						vars.anim_cursor_x:resetnew(150, vars.anim_cursor_x.value, 165, pd.easingFunctions.outBack)
						vars.anim_cursor_y:resetnew(150, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
						if save.sfx then assets.sfx_move:play() end
					else
						vars.slot = 1
						vars.anim_cursor_x:resetnew(150, vars.anim_cursor_x.value, 105, pd.easingFunctions.outBack)
						vars.anim_cursor_y:resetnew(150, vars.anim_cursor_y.value, 42, pd.easingFunctions.outBack)
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
					vars.anim_cursor_x:resetnew(150, vars.anim_cursor_x.value, 78, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(150, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
					if save.sfx then assets.sfx_move:play() end
				elseif vars.slot == 2 then
					vars.slot = 5
					vars.anim_cursor_x:resetnew(150, vars.anim_cursor_x.value, 197, pd.easingFunctions.outBack)
					vars.anim_cursor_y:resetnew(150, vars.anim_cursor_y.value, 92, pd.easingFunctions.outBack)
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
	vars.loseHandlers = {
		AButtonDown = function()
			scenemanager:transitionscene(game, vars.mode)
		end,

		BButtonDown = function()
			scenemanager:transitionscene(title)
		end
	}
	pd.inputHandlers.push(vars.gameHandlers)

	assets.bg = gfx.image.new('images/bg_' .. vars.mode)

	vars.anim_cursor_x.discardOnCompletion = false
	vars.anim_cursor_y.discardOnCompletion = false
	vars.anim_label.discardOnCompletion = false
	vars.anim_modal.discardOnCompletion = false
	vars.anim_hexa.discardOnCompletion = false

	local newcolor
	local newpowerup
	for i = 1, 19 do
		newcolor, newpowerup = self:randomizetri()
		vars.tris[i] = {index = i, color = newcolor, powerup = newpowerup}
	end

	if vars.mode == "arcade" then
		vars.timer = pd.timer.new(45000, 45000, 0)
		vars.timer.delay = 5000
		vars.timer.timerEndedCallback = function()
			self:endround()
		end
		pd.timer.performAfterDelay(1000, function()
			if save.sfx then assets.sfx_count:play() end
			assets.draw_label = assets.label_3
			vars.anim_label:resetnew(1000, -50, 400, pd.easingFunctions.linear)
		end)
		pd.timer.performAfterDelay(2000, function()
			if save.sfx then assets.sfx_count:play() end
			assets.draw_label = assets.label_2
			vars.anim_label:resetnew(1000, -50, 400, pd.easingFunctions.linear)
		end)
		pd.timer.performAfterDelay(3000, function()
			if save.sfx then assets.sfx_count:play() end
			assets.draw_label = assets.label_1
			vars.anim_label:resetnew(1000, -50, 400, pd.easingFunctions.linear)
		end)
		pd.timer.performAfterDelay(4000, function()
			vars.timer.delay = 0
			assets.draw_label = assets.label_go
			vars.anim_label:resetnew(1000, -50, 400, pd.easingFunctions.linear)
			if save.sfx then assets.sfx_start:play() end
			newmusic('audio/music/arcade' .. math.random(1, 3), true)
			vars.can_do_stuff = true
			self:check()
		end)
	elseif vars.mode == "zen" then
		pd.timer.performAfterDelay(1000, function()
			newmusic('audio/music/zen' .. math.random(1, 2), true)
			vars.can_do_stuff = true
			self:check()
		end)
	end

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.bg:draw(0, 0)
		assets.draw_label:draw(vars.anim_label.value, -13)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillPolygon(135, 40, 265, 40, 325, 145, 325, 200, 75, 200, 75, 145, 135, 40)
	end)

	class('game_tris').extends(gfx.sprite)
	function game_tris:init()
		game_tris.super.init(self)
		self:setCenter(0, 0)
		self:setSize(400, 240)
		self:add()
	end
	function game_tris:draw()
		for i = 1, 19 do
			tri(tris_x[i], tris_y[i], tris_flip[i], vars.tris[i].color, vars.tris[i].powerup)
		end
		assets.cursor:draw(vars.anim_cursor_x.value, vars.anim_cursor_y.value)
	end

	class('game_ui').extends(gfx.sprite)
	function game_ui:init()
		game_ui.super.init(self)
		self:setCenter(0, 0)
		self:setSize(400, 240)
		self:add()
	end
	function game_ui:draw()
		gfx.fillTriangle(0, 0, 115, 0, 0, 200)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		if vars.mode == "arcade" then
			assets.half_circle:drawText(text('score'), 10, 10)
			assets.full_circle:drawText(vars.score, 10, 25)
			assets.half_circle:drawText(text('high'), 10, 45)
			assets.full_circle:drawText((vars.score > save.score and vars.score) or (save.score), 10, 60)
			assets.half_circle:drawText(text('time'), 10, 80)
			assets.full_circle:drawText(floor(vars.timer.value / 1000), 10, 95)
		elseif vars.mode == "zen" then
			assets.half_circle:drawText(text('swaps'), 10, 10)
			assets.full_circle:drawText(vars.moves, 10, 25)
			assets.half_circle:drawText(text('hexas'), 10, 45)
			assets.full_circle:drawText(vars.hexas, 10, 60)
		end
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		assets.hexa[math.floor(vars.anim_hexa.value)]:draw(0, 0)
		assets.modal:draw(0, vars.anim_modal.value)
	end

	sprites.tris = game_tris()
	sprites.ui = game_ui()
	self:add()
end

function tri(x, y, up, color, powerup)
	gfx.setColor(gfx.kColorBlack)
	if color == "gray" then
		gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
	end
	if color == "black" or color == "gray" then
		if up then
			gfx.fillTriangle(x, y - 25, x + 30, y + 25, x - 30, y + 25, x, y - 25)
		else
			gfx.fillTriangle(x, y + 25, x + 30, y - 25, x - 30, y - 25, x, y + 25)
		end
	end
	gfx.setColor(gfx.kColorBlack)
	if up then
		gfx.drawTriangle(x, y - 25, x + 30, y + 25, x - 30, y + 25, x, y - 25)
	else
		gfx.drawTriangle(x, y + 25, x + 30, y - 25, x - 30, y - 25, x, y + 25)
	end
	if powerup ~= "" then
		if up then
			assets['powerup_' .. powerup .. '_up']:draw(x - 28, y - 23)
		else
			assets['powerup_' .. powerup .. '_down']:draw(x - 28, y - 23)
		end
	end
end

function game:swap(slot, dir)
	vars.moves += 1
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

function game:hexa(temp1, temp2, temp3, temp4, temp5, temp6)
	pd.inputHandlers.pop()
	pd.timer.performAfterDelay(100, function()
		vars.hexas += 1
		vars.combo += 1
		shakies()
		shakies_y()
		if temp1.powerup == "double" or temp2.powerup == "double" or temp3.powerup == "double" or temp4.powerup == "double" or temp5.powerup == "double" or temp6.powerup == "double" then
			vars.score += 200 * vars.combo
			assets.sfx_select:play()
			assets.draw_label = assets.label_double
			vars.anim_label:resetnew(1200, -100, 400, pd.easingFunctions.linear)
			if vars.mode == "arcade" then
				vars.timer:resetnew(vars.timer.value + 7500, vars.timer.value + 7500, 0)
			end
		else
			vars.score += 100 * vars.combo
			if vars.mode == "arcade" then
				vars.timer:resetnew(vars.timer.value + 5000, vars.timer.value + 5000, 0)
			end
		end
		if temp1.powerup == "bomb" or temp2.powerup == "bomb" or temp3.powerup == "bomb" or temp4.powerup == "bomb" or temp5.powerup == "bomb" or temp6.powerup == "bomb" then
			for i = 1, 19 do
				newcolor, newpowerup = self:randomizetri()
				vars.tris[i] = {index = i, color = newcolor, powerup = newpowerup}
			end
			if save.sfx then assets.sfx_boom:play() end
			assets.draw_label = assets.label_bomb
			vars.anim_label:resetnew(1200, -100, 400, pd.easingFunctions.linear)
		else
			temp1.color, temp1.powerup = self:randomizetri()
			temp2.color, temp2.powerup = self:randomizetri()
			temp3.color, temp3.powerup = self:randomizetri()
			temp4.color, temp4.powerup = self:randomizetri()
			temp5.color, temp5.powerup = self:randomizetri()
			temp6.color, temp6.powerup = self:randomizetri()
			if save.sfx then
				local random = random(1, 10000)
				if random == 1 then
					assets.sfx_vine:play()
				else
					assets.sfx_hexa:play()
				end
			end
		end
		vars.anim_hexa:resetnew(600, 1, 11)
		pd.timer.performAfterDelay(200, function()
			self:check()
			pd.inputHandlers.push(vars.gameHandlers)
		end)
	end)
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

function game:endround()
	vars.can_do_stuff = false
	if vars.mode == "arcade" then
		vars.timer:pause()
	end
	if save.sfx then assets.sfx_end:play() end
	fademusic(1)
	gfx.pushContext(assets.modal)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		if vars.mode == "arcade" then
			assets.full_circle:drawTextAligned(text('score1') .. vars.score .. text('score2'), 240, 50, kTextAlignment.center)
		elseif vars.mode == "zen" then
			assets.full_circle:drawTextAligned(text('zen1'), 240, 50, kTextAlignment.center)
		end
		if vars.moves == 1 then
			assets.full_circle:drawTextAligned(text('stats1') .. vars.moves .. text('stats2b'), 240, 90, kTextAlignment.center)
		else
			assets.full_circle:drawTextAligned(text('stats1') .. vars.moves .. text('stats2a'), 240, 90, kTextAlignment.center)
		end
		if vars.hexas == 1 then
			assets.full_circle:drawTextAligned(text('stats3') .. vars.hexas .. text('stats4b'), 240, 105, kTextAlignment.center)
		else
			assets.full_circle:drawTextAligned(text('stats3') .. vars.hexas .. text('stats4a'), 240, 105, kTextAlignment.center)
		end
		assets.full_circle:drawTextAligned(text(vars.mode .. '_message' .. random(1, 10)), 190, 150, kTextAlignment.center)
		assets.half_circle:drawText(text('newgame') .. ' ' .. text('back'), 40, 205)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	gfx.popContext()
	pd.timer.performAfterDelay(2000, function()
		pd.inputHandlers.push(vars.loseHandlers, true)
		vars.anim_modal:resetnew(500, 240, 0, pd.easingFunctions.outBack)
		if vars.mode == "arcade" then
			if vars.score > save.score then save.score = vars.score end
			if save.sfx then assets.sfx_lose:play() end
		elseif vars.mode == "zen" then
			if save.sfx then assets.sfx_zen_end:play() end
		end
	end)
end

function game:update()
	if save.crank and vars.can_do_stuff then
		local ticks = pd.getCrankTicks(4)
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
end