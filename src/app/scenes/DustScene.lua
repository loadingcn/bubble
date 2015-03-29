
require ("Group")
require ("World")

ProgressMgr = {}
ProgressMgr.items = {}
ProgressMgr.item2widget = {}
ProgressMgr.widgetGroup = nil

function ProgressMgr:CreateWidgetGroupWithLayer(layer)
	self.widgetGroup = StackUIGroup:new(layer, 0, 200)
	self.widgetGroup:setAnchor(0, 0)
end

function ProgressMgr:CreateDefaultStyleBar()
	local progressName = "progress.png"
	local widget = cc.Sprite:create(progressName)
	local function defaultUpdate(widget, widgetSize, percent)
		local w = widgetSize.width * percent
		widget:setTextureRect({
			["x"] = 0, 
			["y"] = 0, 
			["width"] = w, 
			["height"] = widgetSize.height,
		})
	end
	return widget, defaultUpdate
end

function ProgressMgr:CreateBarSpriteWithStyle(styleFunc)
	for _, func in pairs(self.Style) do
		if func==styleFunc then
			return func()
		end
	end
end

-- TODO: unfinied bar styles
ProgressMgr.Style = {
	["DefaultStyle"] = ProgressMgr.CreateDefaultStyleBar,
	["TextWithBarStyle"] = 2,
	["ImageWithBarStyle"] = 3,
	["TextAndImageWithBarStyle"] = 4,
	["CustomStyle"] = 5,
}


function ProgressMgr:AddItem(duration, barStyleInfo, notifyFunc, ...)
	local progressHandler = math.random()
	local progress = progressHandler
	self.items[progress] = {
		["notifyFunc"] = notifyFunc,
		["args"] = {...},
		["leftSeconds"] = duration,
		["totalSeconds"] = duration,
	}
	
	local progressWidget, updateFunc = self:CreateBarSpriteWithStyle(barStyleInfo)
	local size = progressWidget:getContentSize()
	self.item2widget[progress] = {
		["widget"] = progressWidget,
		["size"] = {
			["width"] = size.width,
			["height"] = size.height,
		},
		["update"] = updateFunc,
	}
	progressWidget:setTextureRect({
		["x"] = 0, 
		["y"] = 0, 
		["width"] = 0, 
		["height"] = size.height,
	})
	self.widgetGroup:pushUIObj(progressWidget)
	return progressHandler
end

function ProgressMgr:ForEachItem(func, ...)
	for item,_ in pairs(self.items) do
		func(item, ...)
	end
end

function ProgressMgr:OnTick(delta)
	for item, itemInfo in pairs(self.items) do
		itemInfo.leftSeconds = itemInfo.leftSeconds-delta
		if itemInfo.notifyFunc then
			itemInfo.notifyFunc(item, itemInfo.leftSeconds, 
				unpack(itemInfo.args))
		end
		self.item2widget[item].update(
			self.item2widget[item].widget,
			self.item2widget[item].size,
			(1-itemInfo.leftSeconds/itemInfo.totalSeconds))
		if itemInfo.leftSeconds <= 0 then
			self:RemoveItem(item)
		end
	end
end


function ProgressMgr:RemoveItem(progressItem)
	local widget = self.item2widget[progressItem].widget
	self.widgetGroup:RemoveUIObj(widget)
	self.items[progressItem] = nil
end


local DustScene = class("DustScene", function ()
	return display.newScene("DustScene")
end)

function DustScene.onTouchEvent(eventType, x, y)
	print("Touch Event:", eventType, x, " ", y)
	UIGroupMgr:foreachGroup(
		function (group) 
			if (group:isInRect(x,y)) then
				group:onTouchEvent(eventType, x, y)
				return
			end
		end
		)
end


function DustScene:ctor()
	local bgFileName=""
    --local bg = cc.Sprite:create(bgFileName)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local originSize = cc.Director:getInstance():getVisibleOrigin()
	--bg:setPosition(originSize.x+visibleSize.width/2, originSize.y+visibleSize.height/2)
	print(originSize.x, originSize.y, visibleSize.width, visibleSize.height)

	local bg_layer = cc.Layer:create()
	--bg_layer:addChild(bg)

	local logic_layer = cc.Layer:create()
	
	local op_layer = cc.Layer:create()
	
	local statusGroup = UIGroup:new(op_layer)

	local posY = 40
	statusGroup:setPos(originSize.x, originSize.y+visibleSize.height-posY)

	local segmentNum = 5
	local lblWidth = visibleSize.width/segmentNum

	local statusFont = "Arial"

	local posX = 0
	local timeLbl = cc.LabelTTF:create("Time", statusFont, 24)
	timeLbl:setPosition(posX, 0)
	timeLbl:setAnchorPoint(0, 0)
	statusGroup:addUIObj(timeLbl)

	posX = posX + lblWidth
	local visiableLbl = cc.LabelTTF:create("Visiable", statusFont, 24)
	visiableLbl:setPosition(posX, 0)
	visiableLbl:setAnchorPoint(0, 0)
	statusGroup:addUIObj(visiableLbl)

	posX = posX + lblWidth
	local personNumLbl = cc.LabelTTF:create("Person", statusFont, 24)
	personNumLbl:setPosition(posX, 0)
	personNumLbl:setAnchorPoint(0, 0)
	statusGroup:addUIObj(personNumLbl)

	posX = posX + lblWidth
	local fogIncRateLbl = cc.LabelTTF:create("FogIncRate", statusFont, 24)
	fogIncRateLbl:setPosition(posX, 0)
	fogIncRateLbl:setAnchorPoint(0, 0)
	statusGroup:addUIObj(fogIncRateLbl)

	posX = posX + lblWidth
	local fogThickLbl = cc.LabelTTF:create("FogThick", statusFont, 24)
	fogThickLbl:setPosition(posX, 0)
	fogThickLbl:setAnchorPoint(0, 0)
	statusGroup:addUIObj(fogThickLbl)


	local opBarGroup = UIGroup:new(op_layer)
	opBarGroup:setPos(0, 0)
	local opBarBgFileName = "op_back.png"
	local opBarBg = cc.Sprite:create(opBarBgFileName)
	opBarBg:setPosition(0, 0)
	opBarBg:setAnchorPoint(0, 0)
	opBarGroup:addUIObj(opBarBg)

	local operations = {
		["KouZhao"] = {		-- 口罩技术
			["FileName"] = "kouzhao.png",
			["X"]=0, ["Y"]=0,
			["TouchHandler"] = DoKouZhao.onTouchEvent,
		},
		["XinCaiLiao"] = {	-- 研发新材料
			["FileName"] = "xincailiao.png",
			["X"]=100, ["Y"]=0,
			["TouchHandler"] = DoXinCaiLiao.onTouchEvent,
		},

	}
	for key, opInfo in pairs(operations) do
		local opSprite = cc.Sprite:create(opInfo.FileName)
		opSprite:setPosition(opInfo.X, opInfo.Y)
		opSprite:setAnchorPoint(0, 0)
		opBarGroup:addUIObj(opSprite)
		--opBarGroup:setTouchHandler(opSprite, opInfo.TouchHandler)
		opSprite:setTouchEnabled(true)
		opSprite:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
		opSprite:addNodeEventListener(cc.NODE_TOUCH_EVENT,
			function (event) 
				return opInfo.TouchHandler(opSprite, event)
			end)
	end
	

	local progress_layer = cc.Layer:create()
	ProgressMgr:CreateWidgetGroupWithLayer(progress_layer)


	self:addChild(bg_layer)
	self:addChild(logic_layer)
	self:addChild(progress_layer)
	self:addChild(op_layer)

	cc.Director:getInstance():getScheduler():scheduleScriptFunc(
		function (deltaT) 
			ProgressMgr:OnTick(deltaT) 
		end, 0, false)

end

-- Operations
DoKouZhao = {}

function DoKouZhao.onTouchEvent(widget, event)
	if (event.name == "began") then
		widget:setScale(0.95)
	elseif (event.name == "ended") then
		widget:setScale(1)
		local duration = math.random(1, 10)
		ProgressMgr:AddItem(duration, ProgressMgr.Style.DefaultStyle)
	end
	return true
end

DoXinCaiLiao = {}

function DoXinCaiLiao.onTouchEvent(widget, event)
	if (event.name == "began") then
		widget:setScale(0.95)
	elseif (event.name == "ended") then
		widget:setScale(1)
	end

	return true
end

return DustScene