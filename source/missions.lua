import 'missions_list'
import 'title'
import 'game'

-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local text <const> = gfx.getLocalizedText

class('missions').extends(gfx.sprite) -- Create the scene's class
function missions:init(...)
	missions.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(true)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		pauseimage()
		menu:removeAllMenuItems()
		if not scenemanager.transitioning then
			menu:addMenuItem(text('goback'), function()
				scenemanager:transitionscene(title, false, 'missions')
			end)
		end
	end

	assets = {
		stars_small = gfx.image.new('images/stars_small'),
		stars_large = gfx.image.new('images/stars_large'),
		full_circle = gfx.font.new('fonts/full-circle'),
		half_circle = gfx.font.new('fonts/full-circle-halved'),
		grid = pd.ui.gridview.new(200, 125),
		sfx_move = smp.new('audio/sfx/swap'),
		sfx_select = smp.new('audio/sfx/select'),
		sfx_back = smp.new('audio/sfx/back'),
		sfx_bonk = smp.new('audio/sfx/bonk'),
		check = gfx.image.new('images/check'),
	}

	assets.grid:setNumberOfRows(1)
	assets.grid:setNumberOfColumns(50)
	assets.grid:setCellPadding(5, 5, 0, 0)
	assets.grid:setSelection(1, 1, math.min(save.highest_mission, 50))
	assets.grid:scrollCellToCenter(1, 1, math.min(save.highest_mission, 50), false)

	vars = {
		anim_stars_small_x = pd.timer.new(4000, 0, -399),
		anim_stars_small_y = pd.timer.new(2750, 0, -239),
		anim_stars_large_x = pd.timer.new(2500, 0, -399),
		anim_stars_large_y = pd.timer.new(1250, 0, -239),
	}
	missions_listHandlers = {
		leftButtonDown = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
			vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 75, function()
				local _, _, column = assets.grid:getSelection()
				if column == 1 then
					if save.sfx then assets.sfx_bonk:play() end
					shakies()
				else
					if save.sfx then assets.sfx_move:play() end
					assets.grid:selectPreviousColumn(false)
				end
			end)
		end,

		leftButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		rightButtonDown = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
			vars.keytimer = pd.timer.keyRepeatTimerWithDelay(150, 75, function()
				local _, _, column = assets.grid:getSelection()
				if column == 50 then
					if save.sfx then assets.sfx_bonk:play() end
					shakies()
				else
					if save.sfx then assets.sfx_move:play() end
					assets.grid:selectNextColumn(false)
				end
			end)
		end,

		rightButtonUp = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
		end,

		BButtonDown = function()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
			if save.sfx then assets.sfx_back:play() end
			scenemanager:transitionscene(title, false, 'missions')
		end,

		AButtonDown = function()
			local _, _, column = assets.grid:getSelection()
			if vars.keytimer ~= nil then vars.keytimer:remove() end
			local _, _, column = assets.grid:getSelection()
			if column > save.highest_mission then
				if save.sfx then assets.sfx_bonk:play() end
				shakies()
			else
				if save.sfx then assets.sfx_select:play() end
				scenemanager:transitionscene(game, missions_list[column].type, column, missions_list[column].modifier or nil, missions_list[column].start, missions_list[column].goal)
				fademusic()
			end
		end,
	}
	pd.timer.performAfterDelay(scenemanager.transitiontime, function()
		pd.inputHandlers.push(missions_listHandlers)
	end)

	vars.anim_stars_small_x.repeats = true
	vars.anim_stars_small_y.repeats = true
	vars.anim_stars_large_x.repeats = true
	vars.anim_stars_large_y.repeats = true

	function assets.grid:drawCell(section, row, column, selected, x, y, width, height)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(x, y, width, height)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawRect(x, y, width, height)
		if selected then
			gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
			gfx.fillPolygon(x, y, x + width, y, x + width, y + height, x + width - (width * 0.2), y + height, x + width - (width * 0.05), y + (height / 2), x + width - (width * 0.2), y, x + width * 0.2, y, x + width * 0.05, y + (height / 2), x + width * 0.2, y + height, x, y + height, x, y)
			gfx.setColor(gfx.kColorBlack)
		end
		if column > save.highest_mission then
			assets.half_circle:drawTextAligned('🔒 ' .. text('mission_label') .. column, x + (width / 2), y + 8, kTextAlignment.center)
			assets.half_circle:drawTextAligned(text('mission_locked'), x + (width / 2), y + (height / 3), kTextAlignment.center)
		else
			assets.full_circle:drawTextAligned(text('mission_label') .. column, x + (width / 2), y + 8, kTextAlignment.center)
			if missions_list[column].type == "picture" then
				assets.full_circle:drawTextAligned(text('mission_picture1') .. missions_list[column].name .. text('mission_picture2'), x + (width / 2), y + (height / 3.7), kTextAlignment.center)
			elseif missions_list[column].type == "logic" or missions_list[column].type == "speedrun" then
				assets.full_circle:drawTextAligned(text('mission_' .. missions_list[column].type .. '_' .. missions_list[column].modifier), x + (width / 2), y + (height / 3.7), kTextAlignment.center)
			else
				assets.full_circle:drawTextAligned(text('mission_' .. missions_list[column].type), x + (width / 2), y + (height / 3.7), kTextAlignment.center)
			end
			if missions_list[column].type == "picture" or missions_list[column].type == "logic" then
				assets.full_circle:drawTextAligned(text('swaps') .. text('divvy') .. commalize(save.mission_bests['mission' .. column]), x + (width / 2), y + (height - 22), kTextAlignment.center)
			elseif missions_list[column].type == "time" then
				assets.full_circle:drawTextAligned(text('score') .. text('divvy') .. commalize(save.mission_bests['mission' .. column]), x + (width / 2), y + (height - 22), kTextAlignment.center)
			elseif missions_list[column].type == "speedrun" then
				local mins, secs, mils = timecalc(save.mission_bests['mission' .. column])
				assets.full_circle:drawTextAligned(text('time') .. text('divvy') .. mins .. ':' .. secs .. '.' .. mils, x + (width / 2), y + (height - 22), kTextAlignment.center)
			end
		end
		if save.highest_mission > column then
			assets.check:draw(x + width - 45, y + height - 50)
		end
	end

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
		assets.stars_small:draw(vars.anim_stars_small_x.value, vars.anim_stars_small_y.value)
		assets.stars_large:draw(vars.anim_stars_large_x.value, vars.anim_stars_large_y.value)
		gfx.setColor(gfx.kColorWhite)
		gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer2x2)
		gfx.fillRect(0, 40, 400, 145)
		gfx.setColor(gfx.kColorBlack)
		assets.grid:drawInRect(0,50, 400, 125)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		assets.half_circle:drawText(text('move') .. ' ' .. text('select') .. ' ' .. text('back'), 10, 220)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end)

	self:add()
	newmusic('audio/music/title', true)
end