-- Run from the repository root with Lua 5.1. No phone or network required.
package.path = './?.lua;' .. package.path
local type = type -- Mock callbacks still need Lua introspection.
local output = print
local count = 0
local function equal(actual, expected, message)
    assert(actual == expected, (message or 'Mismatch') .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end
local function test(name, fn)
    fn()
    count = count + 1
    output('ok ' .. count .. ' - ' .. name)
end
local function fails(fn, message)
    local ok, err = pcall(fn)
    assert(not ok and tostring(err):find(message, 1, true), tostring(err))
end

-- API contract mock: game-area pixels remain physical; scripted Regions and
-- Locations remain at 1280x720. Real AnkuLua performs the final scaling.
local log, clicks, drags, patterns, searches, saves
local appArea, viewport, frame, previous, visible, now, dialogValues
local regionMethods = {}
function regionMethods:getX() return self.x end
function regionMethods:getY() return self.y end
function regionMethods:getW() return self.w end
function regionMethods:getH() return self.h end
function regionMethods:getScore() return 0.95 end
function regionMethods:highlight() end
function regionMethods:highlightOff() end
function regionMethods:save(name) saves[#saves + 1] = name end
function regionMethods:exists(pattern, timeout)
    equal(timeout, 0, 'Detection must not block per template')
    assert(previous, 'Detection should reuse the scan snapshot')
    searches[#searches + 1] = {region = self, filename = pattern.filename}
    local target = visible[pattern.filename]
    if type(target) == 'table' then
        if target.x >= self.x and target.y >= self.y
            and target.x+target.w <= self.x+self.w and target.y+target.h <= self.y+self.h then
            return Region(target.x,target.y,target.w,target.h)
        end
    elseif target then return Region(self.x + 2, self.y + 3, 20, 10) end
end
function Region(x, y, w, h)
    return setmetatable({x=x, y=y, w=w, h=h}, {__index=regionMethods})
end
function Location(x,y) return Region(x,y,0,0) end
function Pattern(filename)
    equal(type(filename), 'string', 'Flat template filename')
    local f = assert(io.open('templates/' .. filename, 'rb'), 'Missing template: ' .. filename)
    f:close()
    patterns[#patterns+1] = filename
    return {filename=filename, similar=function(self, threshold) self.threshold=threshold; return self end}
end
Settings = {
    setScriptDimension=function(_, byWidth, width)
        assert(viewport, 'Game area must be set before dimensions')
        assert((byWidth and width==1280) or (not byWidth and width==720)); log[#log+1]='script'
    end,
    setCompareDimension=function(_, byWidth, width)
        assert((byWidth and width==1280) or (not byWidth and width==720)); log[#log+1]='compare'
    end,
}
function setImmersiveMode(value) log[#log+1]='immersive:' .. tostring(value) end
function autoGameArea(value) log[#log+1]=value and 'auto' or 'no-cutouts' end
function getGameArea() log[#log+1]='get'; return Region(appArea.x,appArea.y,appArea.w,appArea.h) end
function setGameArea(area) viewport=area; log[#log+1]='set' end
function snapshot() frame=frame+1 end
function usePreviousSnap(value) previous=value end
function click(target) clicks[#clicks+1]=target end
function dragDrop(a,b) drags[#drags+1]={a,b} end
function sleep(seconds) now=now+seconds end
function scriptExit(message) error('EXIT:' .. message) end
function dialogInit() end
function newRow() end
function addTextView() end
local function field(name, default)
    if dialogValues[name] ~= nil then _G[name] = dialogValues[name] else _G[name]=default end
end
function addCheckBox(name, _, default) field(name,default) end
function addEditNumber(name, default) field(name,default) end
function addSpinner(name, _, default) field(name,default) end
function dialogShow() end
function scriptPath() return './' end
function setImagePath(path) equal(path,'./templates/') end
print = function() end
local realTime = os.time
os.time = function() return math.floor(now) end
local function reset()
    log,clicks,drags,patterns,searches,saves={},{},{},{},{},{}
    appArea={x=0,y=0,w=2400,h=1080}; viewport=nil
    frame,previous,visible,now,dialogValues=0,false,{},1000,{}
    if package.loaded.screen then
        package.loaded.screen.setup({centered=true})
        log={}; viewport=nil
    end
end
reset()
-- Real AnkuLua reserves type() for text entry; typeOf supplies introspection.
typeOf = type
_G.type = function() error('AnkuLua text-entry type() was invoked for introspection') end
local screen = require('screen')
local config = require('config')
local detection = require('detection')
local actions = require('actions')
local cycle = require('cycle')

local cases = {
    {'720p',0,0,1280,720,0,0,1280,720},
    {'1080p',0,0,1920,1080,0,0,1920,1080},
    {'1440p',0,0,2560,1440,0,0,2560,1440},
    {'18:9',0,0,2160,1080,120,0,1920,1080},
    {'19.5:9',0,0,2340,1080,210,0,1920,1080},
    {'20:9',0,0,2400,1080,240,0,1920,1080},
    {'QHD wide',0,0,3200,1440,320,0,2560,1440},
    {'tablet',0,0,2048,1536,0,192,2048,1152},
    {'left cutout',86,0,2160,1080,206,0,1920,1080},
    {'right navigation',0,0,2280,1080,180,0,1920,1080},
    {'top inset',0,24,2400,1056,261,24,1877,1056},
    {'small display',0,0,960,540,0,0,960,540},
}
for _, c in ipairs(cases) do
    test('viewport ' .. c[1], function()
        reset()
        appArea={x=c[2],y=c[3],w=c[4],h=c[5]}
        local v=screen.setup({centered=true})
        equal(v.x,c[6]); equal(v.y,c[7]); equal(v.w,c[8]); equal(v.h,c[9])
        equal(table.concat(log,','),'immersive:true,auto,get,set,script,compare')
        actions.start_game()
        equal(clicks[1].x,955); equal(clicks[1].y,650)
        -- Expected physical Start location under the native uniform transform.
        local x=v.x+clicks[1].x*v.w/1280
        local y=v.y+clicks[1].y*v.w/1280
        assert(x>=v.x and x<v.x+v.w and y>=v.y and y<v.y+v.h)
    end)
end

for _, c in ipairs(cases) do
    test('expanded full game area ' .. c[1], function()
        reset(); appArea={x=c[2],y=c[3],w=c[4],h=c[5]}
        local v=screen.setup()
        equal(v.x,c[2]); equal(v.y,c[3]); equal(v.w,c[4]); equal(v.h,c[5])
        actions.start_game()
        local scale=math.min(v.w/1280,v.h/720)
        local physicalX=v.x+clicks[1].x*scale
        local physicalY=v.y+clicks[1].y*scale
        assert(math.abs(physicalX-(c[6]+955*c[8]/1280))<2,'Play X shifted from the working layout')
        assert(math.abs(physicalY-(c[7]+650*c[9]/720))<2,'Play Y shifted from the working layout')
    end)
end

test('manual asymmetric black bars and navigation mode', function()
    reset()
    local v=screen.setup({immersive=false,manual={x=100,y=0,w=1920,h=1080}})
    equal(v.x,100); equal(log[1],'immersive:false')
end)
test('reject portrait, invalid sizes and out-of-screen manual area', function()
    local good={x=0,y=0,w=2400,h=1080}
    fails(function() screen.viewport({x=0,y=0,w=1080,h=2400}) end,'landscape')
    fails(function() screen.viewport({x=0,y=0,w=0,h=0}) end,'Invalid')
    fails(function() screen.viewport(good,{x=-1,y=0,w=1920,h=1080}) end,'Invalid')
    fails(function() screen.viewport(good,{x=1000,y=0,w=1920,h=1080}) end,'outside')
    equal(screen.viewport(good,{x=0,y=0,w=2000,h=1080}).w,2000)
    fails(function() screen.viewport(good,{x=0.5,y=0,w=1920,h=1080}) end,'integer')
end)
test('default wide area preserves side pixels and the successful centered Play position', function()
    reset()
    local v=screen.setup()
    equal(v.x,0); equal(v.w,2400)
    equal(screen.fullRegion():getW(),1600); equal(screen.fullRegion():getH(),720)
    actions.start_game()
    equal(clicks[1].x,1115); equal(clicks[1].y,650)
    -- Same physical tap as mobile.1's x=240 crop, but neither side is discarded.
    equal(clicks[1].x*1.5,240+955*1.5)
    local r=screen.region(config.STAGE_PURCHASE_ITEM_REGION)
    equal(r:getX(),634); equal(r:getY(),84)
end)
test('manual Samsung window can have a wide aspect and physical offset', function()
    reset()
    local v=screen.setup({manual={x=120,y=80,w=1920,h=900},cutouts=false})
    equal(v.x,120); equal(v.y,80)
    equal(screen.fullRegion():getW(),1536)
    equal(log[2],'no-cutouts')
    actions.start_game(); equal(clicks[1].x,1083)
end)
test('tablet full area preserves top and bottom pixels', function()
    reset(); appArea={x=0,y=0,w=2048,h=1536}
    screen.setup()
    equal(screen.fullRegion():getW(),1280); equal(screen.fullRegion():getH(),960)
    actions.start_game(); equal(clicks[1].x,955); equal(clicks[1].y,770)
end)
test('all configured points, regions, and templates are valid', function()
    for key, value in pairs(config) do
        if key:match('_BUTTON$') or key:match('_ITEM$') or key:match('_POSITION$') or key:match('_POS_%d$') then
            assert(value[1]>=0 and value[1]<1280 and value[2]>=0 and value[2]<720,key)
        elseif key:match('_REGION$') then
            assert(value[1]>=0 and value[2]>=0 and value[3]<=1280 and value[4]<=720,key)
            assert(value[3]>value[1] and value[4]>value[2],key)
        elseif key:match('_TEMPLATE$') then
            for _, name in ipairs(value) do Pattern(name) end
        end
    end
    equal(_G.START_BUTTON,nil,'Config should not leak globals')
end)
test('stage templates fit their configured search regions', function()
    local function uint32(bytes, start)
        local a,b,c,d=bytes:byte(start,start+3)
        return ((a*256+b)*256+c)*256+d
    end
    for name, files in pairs(config.STAGE_TEMPLATES) do
        local bounds=assert(config.STAGE_REGIONS[name],name)
        for _, filename in ipairs(files) do
            local f=assert(io.open('templates/' .. filename,'rb'))
            local header=f:read(24); f:close()
            assert(uint32(header,17)<=bounds[3]-bounds[1],filename .. ' exceeds region width')
            assert(uint32(header,21)<=bounds[4]-bounds[2],filename .. ' exceeds region height')
        end
    end
end)
test('purchase actions use populated configuration', function()
    reset()
    actions.purchase_fast_start(); actions.purchase_cookie_relay(); actions.purchase_random_boost()
    equal(#clicks,6)
    equal(clicks[1].x,235); equal(clicks[3].x,385); equal(clicks[5].x,535)
    for i=2,6,2 do equal(clicks[i].x,925); equal(clicks[i].y,295) end
end)
test('desired boost uses flat filenames and the configured region', function()
    reset(); visible['BOOST_DOUBLE_COINS_1.png']=true
    actions.purchase_desired_random_boost(config.BOOST_DOUBLE_COINS_TEMPLATE,'Double Coins')
    equal(#clicks,3); equal(#searches,1)
    equal(searches[1].region.x,701); equal(searches[1].region.y,505)
    equal(previous,false)
end)
test('desired boost timeout stops instead of tapping Play blindly', function()
    reset()
    fails(function() actions.purchase_desired_random_boost(config.BOOST_DOUBLE_COINS_TEMPLATE,'Double Coins') end,'Desired boost not detected')
    equal(#clicks,3); assert(now>=1030)
end)
test('stage scan shares a frame and honors map/list exclusions', function()
    reset(); visible['MAINMENU_1.png']=true; visible['RELIC_CLAIM_1.png']=true
    equal(detection.detect_stage({'RELIC_CLAIM','MAINMENU'},{RELIC_CLAIM=true}),'MAINMENU')
    equal(frame,1); equal(#searches,1); equal(previous,false)
    equal(searches[1].region.w,190); equal(searches[1].region.h,75)
    equal(detection.detect_stage(nil,{RELIC_CLAIM=true}),'MAINMENU')
    equal(detection.detect_stage({'RELIC_CLAIM'},{'RELIC_CLAIM'}),nil)
end)
test('full search uses normalized game area and retains Match', function()
    reset(); visible['MAINMENU_1.png']=true
    local found=detection.detect_templates(config.STAGE_MAINMENU_TEMPLATE)
    equal(searches[1].region.w,1280); equal(searches[1].region.h,720)
    assert(found[1].match); equal(found[1].x,2)
end)
test('wide recovery finds the purchase label outside the old crop on the same frame', function()
    reset(); screen.setup()
    visible['PURCHASE_ITEM_1.png']={x=15,y=84,w=121,h=45}
    equal(detection.detect_stage({'PURCHASE_ITEM'}),nil)
    local before=frame
    equal(detection.detect_stage({'PURCHASE_ITEM'},nil,true),'PURCHASE_ITEM')
    equal(frame,before+1); equal(previous,false)
    equal(searches[#searches].region.w,1600)
    equal(searches[#searches].region.x,0)
end)
test('wide recovery still honors exclusions and never taps an unrecognized screen', function()
    reset(); screen.setup()
    visible['RELIC_CLAIM_1.png']={x=15,y=100,w=100,h=40}
    equal(detection.detect_stage({'RELIC_CLAIM'},{RELIC_CLAIM=true},true),nil)
    equal(detection.detect_stage({'PURCHASE_ITEM'},nil,true),nil)
    equal(#clicks,0)
end)
test('recovery widens at three seconds and all stages at ten, independently', function()
    local state=require('recovery').new(100)
    equal(state:poll(102,3,10,20).wide,false)
    local scan=state:poll(103,3,10,20)
    equal(scan.wide,true); equal(scan.all,false)
    scan=state:poll(110,3,10,20); equal(scan.all,true)
    scan=state:poll(120,3,10,20); equal(scan.diagnostic,true); equal(scan.elapsed,20)
    equal(state:poll(150,3,10,20).diagnostic,false)
    state:detected(150)
    equal(state:poll(170,3,10,20).diagnostic,true)
end)
test('stall diagnostic includes window and last action, uses bounded filenames', function()
    reset(); screen.setup(); actions.start_game()
    local originalOpen=io.open
    local contents,path
    io.open=function(name,mode)
        path=name
        return {write=function(_,text) contents=text end,close=function() end}
    end
    require('diagnostics').save_unrecognized('PRE_GAME','MAINMENU',20)
    io.open=originalOpen
    equal(saves[1],'debug_unrecognized.png')
    equal(path,'./templates/debug_unrecognized.txt')
    assert(contents:find('Last stage: MAINMENU',1,true))
    assert(contents:find('width=2400',1,true))
    assert(contents:find('logical=(1115,650)',1,true))
end)
test('friend scroll stays inside the reference screen', function()
    reset()
    local original=detection.detect_templates
    local n=0
    detection.detect_templates=function(files)
        equal(type(files[1]),'string')
        n=n+1
        if n==1 then return {} end
        return {{}}
    end
    actions.handle_send_friend_life()
    detection.detect_templates=original
    equal(#drags,1)
    equal(drags[1][1].y,260); equal(drags[1][2].y,620)
end)
test('round timer is five minutes between Play attempts across rounds', function()
    local state=cycle.new(300)
    equal(state:remaining(100),0); equal(state:can_purchase(),true)
    state:purchased(); state:started(100)
    equal(state:can_purchase(),false); equal(state:remaining(280),120)
    state:started(150); equal(state:remaining(280),120)
    equal(state:remaining(500),0)
    state:prepare(); equal(state:can_purchase(),true)
    state:purchased(); state:started(500); equal(state:remaining(600),200)
end)
test('bot module loads without starting or changing sleep/type', function()
    reset()
    local oldSleep, oldType=sleep,_G.type
    assert(type(require('bot').main)=='function')
    equal(#clicks,0); equal(sleep,oldSleep); equal(_G.type,oldType)
end)
test('calibration entry point never taps and saves a diagnostic', function()
    reset(); visible['MAINMENU_1.png']=true
    fails(function() dofile('main.lua') end,'EXIT:Calibration finished')
    equal(#clicks,0); equal(#saves,1)
    assert(saves[1]:match('^debug_screen_.*%.png$'))
end)
test('real bot recovery reaches run Play promptly when item label is outside old crop', function()
    reset(); screen.setup()
    visible['MAINMENU_1.png']=true
    local originalClick=click
    local firstTap,runTap
    click=function(point)
        originalClick(point)
        if point.x==1115 and point.y==650 then
            firstTap=now
            visible={['PURCHASE_ITEM_1.png']={x=15,y=84,w=121,h=45}}
        elseif point.x==1055 and point.y==620 then
            runTap=now
            error('REACHED_RUN_PLAY')
        else error('Unexpected tap during recovery') end
    end
    fails(function() require('bot').main() end,'REACHED_RUN_PLAY')
    click=originalClick
    assert(firstTap and runTap and runTap-firstTap<7,'Wide recovery was too slow')
    equal(#clicks,2); equal(#saves,0)
end)
test('simple bot completes two rounds, buys once, and waits until five minutes', function()
    reset(); dialogValues={use_random_boost=true}
    local originalDetect, originalClick=detection.detect_stage,click
    local stage, playCount, buyCount='MAINMENU',0,0
    local firstPlay, secondPlay
    detection.detect_stage=function(names)
        for _, name in ipairs(names or {}) do
            if name=='RELIC_CLAIM' then error('Simple mode should exclude relics') end
        end
        return stage
    end
    click=function(point)
        originalClick(point)
        if point.x==955 then stage='PURCHASE_ITEM'
        elseif point.x==535 then buyCount=buyCount+1
        elseif point.x==895 then
            playCount=playCount+1
            if playCount==1 then firstPlay=now -- Simulate the first Play not registering.
            elseif playCount==2 then stage='GAME_COMPLETE'; now=now+150
            else secondPlay=now; error('END_TWO_ROUNDS') end
        elseif point.x==460 then stage='MAINMENU' end
    end
    fails(function() require('bot').main() end,'END_TWO_ROUNDS')
    detection.detect_stage=originalDetect; click=originalClick
    equal(buyCount,2,'One purchase per round despite a failed Play')
    assert(secondPlay-firstPlay>=300,'Second round started too soon')
end)

os.time=realTime
_G.type=type
print=output
output('Passed ' .. count .. ' tests (mock AnkuLua API; physical phone testing still required).')
