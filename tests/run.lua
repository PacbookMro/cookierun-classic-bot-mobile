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
local realWidth, realHeight, scriptAxis, scriptDimension
local dialogs, dialogRows
local regionMethods = {}
function regionMethods:getX() return self.x end
function regionMethods:getY() return self.y end
function regionMethods:getW() return self.w end
function regionMethods:getH() return self.h end
function regionMethods:getScore() return 0.95 end
function regionMethods:highlight() end
function regionMethods:highlightOff() end
function regionMethods:save(name) saves[#saves + 1] = name end
function regionMethods:saveColor(name) saves[#saves + 1] = name end
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
        assert((byWidth and (width==1280 or width==realWidth)) or (not byWidth and width==720)); scriptAxis,scriptDimension=byWidth,width; log[#log+1]='script'
    end,
    setCompareDimension=function(_, byWidth, width)
        equal(byWidth,scriptAxis); equal(width,scriptDimension); log[#log+1]='compare'
    end,
}
function setImmersiveMode(value) log[#log+1]='immersive:' .. tostring(value) end
function autoGameArea(value) log[#log+1]=value and 'auto' or 'no-cutouts' end
function getRealScreenSize() return Location(realWidth,realHeight) end
function getGameArea() log[#log+1]='get'; return Region(appArea.x,appArea.y,appArea.w,appArea.h) end
function setGameArea(area) viewport=area; log[#log+1]='set' end
function snapshot() frame=frame+1 end
function usePreviousSnap(value) previous=value end
function click(target) clicks[#clicks+1]=target end
function dragDrop(a,b) drags[#drags+1]={a,b} end
function sleep(seconds) now=now+seconds end
function scriptExit(message) error('EXIT:' .. message) end
function dialogInit() dialogRows={{}} end
function newRow() dialogRows[#dialogRows+1]={} end
local function widget(kind,name)
    local row=dialogRows[#dialogRows]
    row[#row+1]={kind=kind,name=name}
end
function addTextView(label) widget('label',label) end
local function field(name, default)
    if dialogValues[name] ~= nil then _G[name] = dialogValues[name] else _G[name]=default end
end
function addCheckBox(name, _, default) widget('check',name); field(name,default) end
function addEditNumber(name, default) widget('number',name); field(name,default) end
function addSpinner(name, _, default) widget('spinner',name); field(name,default) end
local function showDialog(title,full)
    local nonempty=0
    for _,row in ipairs(dialogRows) do
        assert(#row<=1, 'Portrait controls must each have their own row: '..title)
        if #row>0 then nonempty=nonempty+1 end
    end
    assert(nonempty<=6, 'Settings page is too dense: '..title)
    dialogs[#dialogs+1]={title=title,full=full,rows=dialogRows}
end
function dialogShow(title) showDialog(title,false) end
function dialogShowFullScreen(title) showDialog(title,true) end
function scriptPath() return './' end
function setImagePath(path) equal(path,'./templates/') end
print = function() end
local realTime = os.time
os.time = function() return math.floor(now) end
local function reset()
    log,clicks,drags,patterns,searches,saves={},{},{},{},{},{}
    appArea={x=0,y=0,w=2400,h=1080}; viewport=nil
    realWidth,realHeight=2400,1080
    frame,previous,visible,now,dialogValues=0,false,{},1000,{}
    dialogs,dialogRows={},{{}}
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
test('portrait split screen scales the selected top pane by height and contains taps', function()
    reset(); realWidth,realHeight=1080,2400
    local rect={x=0,y=24,w=1080,h=700}
    screen.setup({window=true,manual=rect})
    equal(viewport.w,1080); equal(viewport.h,700); equal(viewport.y,24)
    equal(scriptAxis,false); equal(scriptDimension,720)
    local reg=screen.fullRegion()
    equal(reg:getH(),720); equal(reg:getW(),1110)
    actions.start_game(); actions.play_game(); actions.purchase_random_boost()
    for _,point in ipairs(clicks) do
        local x=rect.x+point:getX()*rect.h/720
        local y=rect.y+point:getY()*rect.h/720
        assert(x>=rect.x and x<rect.x+rect.w)
        assert(y>=rect.y and y<rect.y+rect.h,'Tap escaped into bottom app')
    end
    -- main Play and lobby Play remain separate inside the game pane.
    equal(clicks[1].y,650); equal(clicks[2].y,620)
end)
test('top-pane scale matches the narrow example instead of fitting a whole 16:9 canvas', function()
    reset(); realWidth,realHeight=692,1536
    screen.setup({window=true,manual={x=0,y=0,w=692,h=449}})
    actions.start_game()
    local physicalX=clicks[1].x*449/720
    local physicalY=clicks[1].y*449/720
    assert(math.abs(physicalX-542)<2)
    assert(math.abs(physicalY-405)<2)
    fails(function() screen.location(1279,650) end,'outside game area')
    equal(screen.region({1200,0,1280,100}),nil)
end)
test('cropped reference regions skip local searches instead of searching chat', function()
    reset(); realWidth,realHeight=1080,2400
    screen.setup({window=true,manual={x=0,y=0,w=1080,h=800}})
    equal(#detection.detect_templates(config.STAGE_MAINMENU_TEMPLATE,{1200,0,1280,100}),0)
    equal(#searches,0)
    local found=detection.detect_templates(config.STAGE_MAINMENU_TEMPLATE)
    equal(#found,0)
    for _,entry in ipairs(searches) do
        assert(entry.region:getY()+entry.region:getH()<=720)
    end
end)
test('wide recovery is restricted to the game pane even when another app has matching text', function()
    reset(); realWidth,realHeight=1080,2400
    screen.setup({window=true,manual={x=0,y=0,w=1080,h=700}})
    -- Chat text would be below the selected pane after height normalization.
    visible['MAINMENU_1.png']={x=100,y=900,w=174,h=59}
    equal(detection.detect_stage({'MAINMENU'},nil,true),nil)
    for _,entry in ipairs(searches) do
        assert(entry.region:getY()+entry.region:getH()<=720)
    end
end)

local function fakeProfileIO(initial)
    local original=io.open
    local data=initial
    io.open=function(path,mode)
        if path~='./window-profile.txt' then return original(path,mode) end
        if mode=='r' then
            if not data then return nil end
            return {read=function() return data end,close=function() end}
        end
        return {write=function(_,text) data=text end,close=function() end}
    end
    return function() io.open=original; return data end
end

test('two-corner picker saves physical pixels and does not send game/chat taps', function()
    reset(); realWidth,realHeight=1080,2400
    local queue={Location(2,25),Location(1078,723)}
    local restore=fakeProfileIO()
    getTouchEvent=function()
        equal(scriptAxis,true); equal(scriptDimension,1080,'Picker must use physical pixels')
        return 'click',table.remove(queue,1)
    end
    local rect=require('window_profile').select()
    equal(rect.x,2); equal(rect.y,25); equal(rect.w,1076); equal(rect.h,698)
    local saved=restore(); getTouchEvent=nil
    equal(saved,'1 1080 2400 2 25 1076 698\n')
    equal(#clicks,0)
end)
test('saved window profile rejects changed display, missing/corrupt data, and out-of-bounds rectangles', function()
    reset(); realWidth,realHeight=1080,2400
    local restore=fakeProfileIO('1 1080 2400 0 24 1080 700\n')
    local rect=require('window_profile').load(); equal(rect.h,700)
    realWidth,realHeight=2400,1080
    fails(function() require('window_profile').load() end,'orientation changed')
    restore(); realWidth,realHeight=1080,2400
    for _,fixture in ipairs({'', 'return os.execute("bad")', '1 1080 2400 500 0 1080 700'}) do
        restore=fakeProfileIO(fixture)
        local ok=pcall(require('window_profile').load)
        equal(ok,false)
        restore()
    end
    restore=fakeProfileIO()
    fails(function() require('window_profile').load() end,'No saved window')
    restore()
end)
test('picker rejects drag gestures without saving or tapping', function()
    reset(); realWidth,realHeight=1080,2400
    getTouchEvent=function() return 'swipe',{} end
    fails(function() require('window_profile').select() end,'do not drag')
    getTouchEvent=nil; equal(#clicks,0)
end)
test('portrait main entry loads saved game pane and calibration never taps', function()
    reset(); realWidth,realHeight=1080,2400
    dialogValues.screen_mode='Reuse saved game window'
    local restore=fakeProfileIO('1 1080 2400 0 24 1080 700\n')
    fails(function() dofile('main.lua') end,'EXIT:Calibration finished')
    restore()
    equal(viewport.y,24); equal(viewport.w,1080); equal(viewport.h,700)
    equal(#clicks,0); equal(#saves,1)
end)

test('window mode rejects taps and searches after physical display rotation', function()
    reset(); realWidth,realHeight=1080,2400
    screen.setup({window=true,manual={x=0,y=24,w=1080,h=700}})
    local verified=screen.location(955,650)
    realWidth,realHeight=2400,1080
    fails(function() actions.start_game(verified) end,'Display changed')
    fails(function() actions.play_game() end,'Display changed')
    fails(function() detection.detect_stage({'MAINMENU'}) end,'Display changed')
    equal(#clicks,0)
end)
test('picker rejects rotation between the two corner touches', function()
    reset(); realWidth,realHeight=1080,2400
    local index=0
    getTouchEvent=function()
        index=index+1
        if index==2 then realWidth,realHeight=2400,1080; return 'click',Location(1000,700) end
        return 'click',Location(0,24)
    end
    fails(function() require('window_profile').select() end,'Display changed during selection')
    getTouchEvent=nil; equal(#clicks,0)
end)
test('offset pop-up game pane excludes the rest of the portrait display', function()
    reset(); realWidth,realHeight=1080,2400
    local rect={x=100,y=160,w=880,h=500}
    screen.setup({window=true,manual=rect})
    actions.start_game(); actions.play_game(); actions.purchase_fast_start(); actions.purchase_cookie_relay()
    for _,point in ipairs(clicks) do
        local x=rect.x+point:getX()*rect.h/720
        local y=rect.y+point:getY()*rect.h/720
        assert(x>=rect.x and x<rect.x+rect.w and y>=rect.y and y<rect.y+rect.h)
    end
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
local function mockBoostScreen(rolling)
    snapshotColor=function() frame=frame+1 end
    getColor=function(point)
        assert(previous, 'Boost colors must reuse a color snapshot')
        if point:getY()>=590 then return 140,190,20 end
        if rolling then return 240,240,240 end
        return 60,50,100
    end
end
local function clearBoostScreen() getColor=nil; snapshotColor=nil end
local function withoutBoostDiagnostics(fn)
    local diagnostics=require('diagnostics')
    local original=diagnostics.save_unrecognized
    local reports={}
    diagnostics.save_unrecognized=function(...) reports[#reports+1]={...} end
    local ok,err=pcall(fn,reports)
    diagnostics.save_unrecognized=original
    assert(ok,err)
end

test('desired boost searches a wider banner area and waits for stable completion', function()
    reset(); visible['BOOST_DOUBLE_COINS_1.png']=true; mockBoostScreen(false)
    actions.purchase_desired_random_boost(config.BOOST_DOUBLE_COINS_TEMPLATE,'Double Coins')
    equal(#clicks,3); assert(#searches>=7)
    equal(searches[1].region.x,650); equal(searches[1].region.y,480)
    equal(previous,false); assert(now>=1008)
    clearBoostScreen()
end)
test('desired boost timeout stops instead of tapping Play blindly', function()
    reset(); mockBoostScreen(false)
    withoutBoostDiagnostics(function(reports)
        fails(function() actions.purchase_desired_random_boost(config.BOOST_DOUBLE_COINS_TEMPLATE,'Double Coins') end,'Desired boost not detected')
        equal(#reports,1); assert(reports[1][1]:find('Double Coins',1,true))
    end)
    equal(#clicks,3); assert(now>=1180)
    clearBoostScreen()
end)
test('stage scan shares a frame and honors map/list exclusions', function()
    reset(); visible['MAINMENU_1.png']=true; visible['RELIC_CLAIM_1.png']=true
    equal(detection.detect_stage({'RELIC_CLAIM','MAINMENU'},{RELIC_CLAIM=true}),'MAINMENU')
    equal(frame,1); equal(#searches,1); equal(previous,false)
    equal(searches[1].region.w,280); equal(searches[1].region.h,135)
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
test('repeat countdown starts at results, not Play, and is not reset by result retries', function()
    local state=cycle.new(300)
    equal(state:remaining(100),0); equal(state:can_purchase(),true)
    state:purchased(); state:started(100)
    equal(state:can_purchase(),false); equal(state:remaining(280),0)
    state:started(150); equal(state.last_start,100)
    state:finished(500); equal(state:remaining(600),200)
    state:finished(550); equal(state:remaining(600),200)
    equal(state:remaining(900),0)
    state:prepare(); equal(state:can_purchase(),true)
    state:purchased(); state:started(900); equal(state:remaining(950),0)
    state:finished(1200); equal(state:remaining(1250),250)
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
-- Synthetic controls based on the six supplied screens' geometry. These
-- exercise live color sampling; they are not pixel replays of the screenshots.
local function mockControls(scene)
    snapshotColor=function() frame=frame+1 end
    getColor=function(point)
        assert(previous, 'Color samples must share the color frame')
        local origin=screen.location(0,0)
        local x,y=point:getX()-origin:getX(),point:getY()-origin:getY()
        local r,g,b=20,35,80 -- dark blue background
        if scene=='main' or scene=='dimmed' then
            if x>=750 and x<=1160 and y>=600 and y<=696 then r,g,b=155,195,12 end
            if x>=752 and x<=1160 and y>=508 and y<=586 then r,g,b=25,155,170 end
        elseif scene=='items' or scene=='random' or scene=='rolling' or scene=='ready' then
            if x>=700 and x<=1100 and y>=565 and y<=661 then r,g,b=155,195,12 end
            if scene~='items' and x>=850 and x<=1040 and y>=249 and y<=325 then r,g,b=20,170,190 end
        elseif scene=='multi' then
            if x>=530 and x<=760 and y>=550 and y<=625 then r,g,b=155,195,12 end
        end
        if scene=='dimmed' then return r*0.45,g*0.45,b*0.45 end
        return r,g,b
    end
end
local function clearControls() getColor=nil; snapshotColor=nil end

test('main-menu fallback recognizes Play plus tabs without a Friends template match', function()
    reset(); screen.setup(); mockControls('main')
    local stage,evidence=detection.detect_stage({'MAINMENU'})
    equal(stage,'MAINMENU'); equal(evidence.source,'main-menu Play + cyan tabs')
    equal(evidence.target:getX(),1115); equal(evidence.target:getY(),650)
    equal(previous,false)
    actions.start_game(evidence.target)
    equal(clicks[1],evidence.target,'Use the verified logical target without another offset')
    clearControls()
end)
test('purchase, random boost, multi-buy, rolling, and ready screens cannot trigger the main-menu fallback', function()
    reset()
    for _,scene in ipairs({'items','random','multi','rolling','ready','dimmed'}) do
        mockControls(scene)
        equal(detection.detect_stage({'MAINMENU'},nil,true),nil,scene)
        equal(#clicks,0)
    end
    clearControls()
end)
test('main-menu fallback respects group scope and exclusions', function()
    reset(); mockControls('main')
    equal(detection.detect_stage({'PURCHASE_ITEM'},nil,true),nil)
    equal(detection.detect_stage({'MAINMENU'},{MAINMENU=true},true),nil)
    clearControls()
end)
test('color sampling tolerates two text/highlight samples per control, rejects weak evidence', function()
    reset(); mockControls('main')
    local original=getColor
    local n=0
    getColor=function(point)
        n=n+1
        if n==1 or n==2 or n==9 or n==10 then return 250,250,250 end
        return original(point)
    end
    assert(require('main_menu').findPlay())
    n=0
    getColor=function(point)
        n=n+1
        if n<=3 then return 250,250,250 end
        return original(point)
    end
    equal(require('main_menu').findPlay(),nil)
    clearControls()
end)
test('color bridge errors release the snapshot and leave actionable diagnostics', function()
    reset(); mockControls('main')
    getColor=function() error('color bridge unavailable') end
    equal(require('main_menu').findPlay(),nil)
    equal(previous,false)
    assert(require('main_menu').last_probe:find('color bridge unavailable',1,true))
    clearControls()
end)
test('real bot clicks initial Play when Friends never matches, then reaches item Play', function()
    reset(); screen.setup(); mockControls('main')
    local originalClick=click
    click=function(point)
        originalClick(point)
        if #clicks==1 then
            equal(point:getX(),1115); equal(point:getY(),650)
            mockControls('items')
            visible['PURCHASE_ITEM_1.png']=true
        else
            equal(point:getX(),1055); equal(point:getY(),620)
            error('MAINMENU_FALLBACK_COMPLETED')
        end
    end
    fails(function() require('bot').main() end,'MAINMENU_FALLBACK_COMPLETED')
    click=originalClick; clearControls()
    equal(#clicks,2)
end)
test('main-menu fallback is rechecked after waiting before a tap', function()
    reset(); mockControls('main')
    local originalSleep=sleep
    sleep=function(seconds)
        originalSleep(seconds)
        if seconds==5 then mockControls('multi') end
        if now>1007 then error('CHANGED_SCREEN_CHECKED') end
    end
    fails(function() require('bot').main() end,'CHANGED_SCREEN_CHECKED')
    sleep=originalSleep; clearControls()
    equal(#clicks,0,'Do not use stale color evidence after a popup opens')
end)

test('simple bot waits five minutes after results and buys once per round', function()
    reset(); dialogValues={use_random_boost=true}
    local originalDetect, originalClick=detection.detect_stage,click
    local stage, playCount, buyCount='MAINMENU',0,0
    local firstPlay, secondPlay, resultAt
    detection.detect_stage=function(names)
        for _, name in ipairs(names or {}) do
            if name=='RELIC_CLAIM' then error('Simple mode should exclude relics') end
        end
        if stage=='GAME_COMPLETE' and not resultAt then resultAt=math.floor(now) end
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
    assert(secondPlay-resultAt>=300,'Second round must wait five minutes after results')
    assert(resultAt-firstPlay>=150)
end)


-- QoL tests exercise native API contracts and the real bot loop.
local options = require('options')
local interaction = require('interaction')
test('options default to fixed five minutes, no purchases, no dimming or tap variation', function()
    reset()
    local settings=options.read()
    equal(settings.round_interval,300); equal(settings.round_max_interval,300)
    equal(settings.use_fast_start,false); equal(settings.buy_fast_start,false)
    equal(settings.use_cookie_relay,false); equal(settings.buy_cookie_relay,false)
    equal(settings.dim_percent,nil); equal(settings.interaction.enabled,false)
end)
test('options accept short and long intervals and convert press milliseconds', function()
    reset(); dialogValues={repeat_min_minutes=1,repeat_max_minutes=7.5,vary_taps=true}
    local settings=options.read()
    equal(settings.round_interval,60); equal(settings.round_max_interval,450)
    equal(settings.interaction.press_min,0.04); equal(settings.interaction.press_max,0.1)
end)
test('invalid timers, tap ranges, brightness and conflicting boost modes are rejected', function()
    local invalid={
        {{repeat_min_minutes=-1},'Repeat delay'}, {{repeat_max_minutes=4},'Repeat delay'},
        {{repeat_max_minutes=math.huge},'Repeat delay'}, {{repeat_min_minutes=0/0},'Repeat delay'},
        {{vary_taps=true,tap_radius=7},'Tap radius'}, {{vary_taps=true,tap_radius=1.5},'integer'},
        {{vary_taps=true,press_min_ms=110,press_max_ms=40},'Press duration'},
        {{vary_taps=true,press_max_ms=201},'Press duration'},
        {{vary_taps=true,tap_pause=-1},'Extra tap pause'},
        {{dim_screen=true,dim_percent=0},'Brightness percent'},
        {{dim_screen=true,dim_percent=101},'Brightness percent'},
        {{use_random_boost=true,use_desired_random_boost=true},'not both'},
    }
    for _, entry in ipairs(invalid) do
        reset(); dialogValues=entry[1]; fails(options.read,entry[2])
        equal(#clicks,0)
    end
end)
for _, mode in ipairs({'Off','Use owned only (never buy)','Buy one each round + use'}) do
    test('real bot item policy: '..mode..', including a failed Play retry', function()
        reset(); dialogValues={fast_start_mode=mode,relay_mode=mode}
        local original=detection.detect_stage
        local stages={'PURCHASE_ITEM','PURCHASE_ITEM','GAME_START','GAME_RELAY','GAME_COMPLETE'}
        local n=0
        detection.detect_stage=function()
            n=n+1
            if not stages[n] then error('ITEM_POLICY_COMPLETE') end
            return stages[n]
        end
        fails(function() require('bot').main() end,'ITEM_POLICY_COMPLETE')
        detection.detect_stage=original
        local purchaseCount,useCount,playCount=0,0,0
        for _, target in ipairs(clicks) do
            if target.x==925 then purchaseCount=purchaseCount+1 end
            if target.x==655 then useCount=useCount+1 end
            if target.x==895 then playCount=playCount+1 end
        end
        equal(purchaseCount,mode=='Buy one each round + use' and 2 or 0)
        equal(useCount,mode=='Off' and 0 or 2)
        equal(playCount,2)
    end)
end
test('owned-only mode progresses without stock icons and makes no replacement purchase', function()
    reset(); dialogValues={fast_start_mode='Use owned only (never buy)',relay_mode='Use owned only (never buy)'}
    local original=detection.detect_stage
    local n=0
    detection.detect_stage=function()
        n=n+1
        if n==1 then return 'PURCHASE_ITEM' end
        if n<5 then return nil end
        if n==5 then return 'GAME_COMPLETE' end
        error('NO_STOCK_COMPLETE')
    end
    fails(function() require('bot').main() end,'NO_STOCK_COMPLETE')
    detection.detect_stage=original
    equal(#clicks,2); equal(clicks[1].x,895); equal(clicks[2].x,460)
end)
test('random repeat delay is sampled once per result and is independent of stage duration', function()
    local original=math.random
    local n=0
    math.random=function() n=n+1; return n==1 and 0 or 1 end
    local state=cycle.new(60,420)
    state:started(100); equal(n,0)
    equal(state:remaining(800),0)
    state:finished(900); equal(state:remaining(910),50); equal(n,1)
    state:finished(930); equal(state:remaining(930),30); equal(n,1)
    state:prepare(); state:started(1000); equal(n,1)
    state:finished(1700); equal(state:remaining(1700),420); equal(n,2)
    equal(state:remaining(2200),0)
    math.random=original
end)
test('optional taps use bounded down/wait/up and remain inside a portrait game pane', function()
    reset(); realWidth,realHeight=1080,2400
    screen.setup({window=true,manual={x=0,y=24,w=1080,h=700}})
    local sequences={}
    manualTouch=function(sequence) sequences[#sequences+1]=sequence end
    interaction.configure({enabled=true,radius=6,press_min=0.04,press_max=0.1,pause=0.25})
    local area=screen.fullRegion()
    for i=1,100 do
        screen.tapLogical(Location(0,0))
        screen.tapLogical(Location(area:getW()-1,area:getH()-1))
        actions.start_game(screen.location(955,650))
        actions.play_game()
    end
    equal(#clicks,0,'Randomized presses must not send an extra native click')
    for _, sequence in ipairs(sequences) do
        equal(sequence[1].action,'touchDown'); equal(sequence[2].action,'wait'); equal(sequence[3].action,'touchUp')
        equal(sequence[1].target,sequence[3].target)
        assert(sequence[2].target>=0.04 and sequence[2].target<=0.1)
        local p=sequence[1].target
        assert(p.x>=0 and p.y>=0 and p.x<area:getW() and p.y<area:getH())
    end
    local main=screen.location(955,650); local lobby=screen.location(895,620)
    for i=1,#sequences,4 do
        assert(sequences[i][1].target.x<=6 and sequences[i][1].target.y<=6)
        assert(math.abs(sequences[i+2][1].target.x-main.x)<=6)
        assert(math.abs(sequences[i+2][1].target.y-main.y)<=6)
        assert(math.abs(sequences[i+3][1].target.x-lobby.x)<=6)
        assert(math.abs(sequences[i+3][1].target.y-lobby.y)<=6)
    end
    interaction.configure(); manualTouch=nil
end)
test('small matched buttons restrict variation and keep native match coordinates', function()
    reset(); screen.setup()
    local match=Region(500,300,8,8)
    function match:getTarget() return Location(504,304) end
    manualTouch=function(sequence)
        local p=sequence[1].target
        assert(math.abs(p.x-504)<=2 and math.abs(p.y-304)<=2)
    end
    interaction.configure({enabled=true,radius=6,press_min=0.04,press_max=0.1,pause=0})
    for i=1,30 do screen.tapMatch(match) end
    interaction.configure(); manualTouch=nil
end)
test('display rotation during randomized pause aborts before touch down', function()
    reset(); realWidth,realHeight=1080,2400
    screen.setup({window=true,manual={x=0,y=0,w=1080,h=650}})
    local original=sleep
    sleep=function(seconds) original(seconds); realWidth,realHeight=2400,1080 end
    manualTouch=function() error('UNSAFE_TOUCH') end
    interaction.configure({enabled=true,radius=3,press_min=0.04,press_max=0.1,pause=0.25})
    fails(function() actions.play_game() end,'Display changed')
    sleep=original; interaction.configure(); manualTouch=nil
end)
test('tap variation fails clearly when native manualTouch is unavailable', function()
    fails(function() interaction.configure({enabled=true}) end,'manualTouch support')
    interaction.configure()
end)

-- In-memory journal: no real brightness or user files are changed by tests.
local brightness=require('brightness')
local function withBrightness(fn)
    local oldOpen,oldRemove=io.open,os.remove
    local state={level=180,stored=nil,sets={}}
    getBrightness=function() return state.level end
    setBrightness=function(value)
        if state.failSet then error('BRIGHTNESS_DENIED') end
        state.level=value; state.sets[#state.sets+1]=value
    end
    io.open=function(path,mode)
        if path~='./brightness-restore.txt' then return oldOpen(path,mode) end
        if mode=='r' and not state.stored then return nil end
        if mode=='w' and state.failWrite then return nil end
        return {
            read=function() return state.stored end,
            write=function(_,value) state.stored=value; return true end,
            close=function() return true end,
        }
    end
    os.remove=function(path) equal(path,'./brightness-restore.txt'); state.stored=nil; return true end
    local ok,err=pcall(fn,state)
    io.open,os.remove=oldOpen,oldRemove
    getBrightness,setBrightness=nil,nil
    assert(ok,err)
end
test('brightness restores after normal completion and caught bot failure', function()
    withBrightness(function(state)
        brightness.run(function() brightness.dim(5); equal(state.level,13); assert(state.stored) end)
        equal(state.level,180); equal(state.stored,nil)
        fails(function() brightness.run(function() brightness.dim(5); error('BOT_FAILED') end) end,'BOT_FAILED')
        equal(state.level,180); equal(state.stored,nil)
    end)
end)
test('brightness journal survives forced stop and can be recovered on next startup', function()
    withBrightness(function(state)
        brightness.dim(5); equal(state.level,13)
        package.loaded.brightness=nil
        assert(require('brightness').restore())
        equal(state.level,180); equal(state.stored,nil)
    end)
end)
test('brightness never increases an already dim screen and supports original zero', function()
    withBrightness(function(state)
        state.level=0
        brightness.dim(5); equal(state.level,0); equal(state.stored,'0\n')
        assert(brightness.restore()); equal(state.level,0)
    end)
end)
test('brightness journal failure prevents dimming, restoration failure retains original value', function()
    withBrightness(function(state)
        state.failWrite=true
        fails(function() brightness.dim(5) end,'dimming cancelled'); equal(state.level,180)
        state.failWrite=false
        brightness.dim(5); state.failSet=true
        fails(brightness.restore,'BRIGHTNESS_DENIED'); equal(state.stored,'180\n')
        state.failSet=false; brightness.restore(); equal(state.level,180)
    end)
end)
test('brightness restore rejects corrupt journal without setting the display', function()
    withBrightness(function(state)
        state.stored='not a number'
        fails(brightness.restore,'Invalid brightness-restore'); equal(#state.sets,0)
    end)
end)

test('boost completion options accept any game-selected target or a specific name', function()
    reset(); dialogValues={use_desired_random_boost=true,boost_wait_seconds=300,boost_settle_seconds=10}
    local settings=options.read()
    equal(#settings.desired_boost_template,11)
    equal(settings.desired_boost_name,'Any completed boost (game target)')
    equal(settings.boost_timeout,300); equal(settings.boost_settle,10)
    dialogValues.selected_boost_name='Magnetic Aura'
    settings=options.read()
    equal(#settings.desired_boost_template,1)
    equal(settings.desired_boost_template[1],'BOOST_MAGNETIC_AURA_1.png')
end)
test('boost completion options reject impossible wait ranges', function()
    for _, values in ipairs({
        {use_desired_random_boost=true,boost_wait_seconds=9},
        {use_desired_random_boost=true,boost_wait_seconds=1801},
        {use_desired_random_boost=true,boost_wait_seconds=10,boost_settle_seconds=9},
        {use_desired_random_boost=true,boost_settle_seconds=-1},
    }) do
        reset(); dialogValues=values
        assert(not pcall(options.read)); equal(#clicks,0)
    end
end)
test('boost banner that extends beyond the old crop matches on the wide phone canvas', function()
    reset(); screen.setup(); mockBoostScreen(false)
    -- 372-pixel original banner, displaced past the old reference x=1091 edge.
    visible['BOOST_DOUBLE_COINS_1.png']={x=906,y=515,w=372,h=54}
    equal(#detection.detect_templates(config.BOOST_DOUBLE_COINS_TEMPLATE,{701,505,1091,578}),0)
    require('boost_wait').wait(config.BOOST_DOUBLE_COINS_TEMPLATE,'Double Coins',15,0)
    equal(#clicks,0); clearBoostScreen()
end)
test('multi-buy may take over thirty seconds and is not sent again while waiting', function()
    reset(); mockBoostScreen(false)
    local original=sleep
    sleep=function(seconds)
        original(seconds)
        if now>=1045 then visible['BOOST_DOUBLE_COINS_1.png']=true end
    end
    actions.purchase_desired_random_boost(config.BOOST_DOUBLE_COINS_TEMPLATE,'Double Coins',90,5)
    sleep=original
    assert(now>=1048); equal(#clicks,3)
    clearBoostScreen()
end)
test('target banner during rolling cannot start Play until the panel closes and settles', function()
    reset(); mockBoostScreen(true); visible['BOOST_DOUBLE_COINS_1.png']=true
    local original=sleep
    sleep=function(seconds)
        original(seconds)
        if now>=1040 then mockBoostScreen(false) end
    end
    require('boost_wait').wait(config.BOOST_DOUBLE_COINS_TEMPLATE,'Double Coins',60,5)
    sleep=original
    assert(now>=1043); equal(#clicks,0); clearBoostScreen()
end)
test('any boost accepts another target; specific verification never silently accepts it', function()
    reset(); mockBoostScreen(false); visible['BOOST_MAGNETIC_AURA_1.png']=true
    dialogValues={use_desired_random_boost=true}
    local settings=options.read()
    require('boost_wait').wait(settings.desired_boost_template,settings.desired_boost_name,10,0)
    withoutBoostDiagnostics(function()
        fails(function() require('boost_wait').wait(config.BOOST_DOUBLE_COINS_TEMPLATE,'Double Coins',10,0) end,'Desired boost not detected')
    end)
    equal(#clicks,0); clearBoostScreen()
end)
test('transient and changing banners reset the completion stability timer', function()
    reset(); mockBoostScreen(false)
    local original=sleep
    local first='BOOST_DOUBLE_COINS_1.png'; local second='BOOST_MAGNETIC_AURA_1.png'
    visible[first]=true
    sleep=function(seconds)
        original(seconds)
        if now>=1001 then visible[first]=nil end
        if now>=1002 then visible[second]=true end
        if now>=1003 and now<1004 then visible[second]=nil end
    end
    require('boost_wait').wait({first,second},'Any',15,0)
    sleep=original
    assert(now>=1007); equal(#clicks,0); clearBoostScreen()
end)
test('missing Play or color API failure prevents boost completion and releases frame reuse', function()
    reset(); mockBoostScreen(false)
    getColor=function() return 20,20,20 end
    equal(require('boost_wait').ready(),false); equal(previous,false)
    getColor=function() error('COLOR_FAILED') end
    local ready,detail=require('boost_wait').ready()
    equal(ready,false); assert(detail:find('COLOR_FAILED',1,true)); equal(previous,false)
    clearBoostScreen()
    fails(function() actions.purchase_desired_random_boost(config.BOOST_DOUBLE_COINS_TEMPLATE,'Double Coins') end,'color capture support')
    equal(#clicks,0)
end)

test('startup menu has no repeat wait; missed results fall back to observed run returning', function()
    local state=cycle.new(60,60)
    state:returned(100); equal(state:remaining(100),0)
    state:observed_run(); state:returned(500); equal(state:remaining(510),50)
    state:returned(520); equal(state:remaining(530),30)
    state:started(600); state:finished(900); equal(state:remaining(910),50)
end)
test('starting on results counts once and zero delay remains immediate', function()
    local state=cycle.new(60)
    state:finished(100); state:finished(130); equal(state:remaining(140),20)
    local immediate=cycle.new(0)
    immediate:finished(100); equal(immediate:remaining(100),0)
end)
test('repeat and tap settings use labeled full-width rows in both display orientations', function()
    for _,size in ipairs({{1080,2400},{2400,1080}}) do
        reset(); realWidth,realHeight=size[1],size[2]
        dialogValues={simple_mode=false,use_desired_random_boost=true,vary_taps=true}
        options.read()
        equal(dialogs[1].title,'Repeat delay after stage ends')
        local found={}
        for _,page in ipairs(dialogs) do
            equal(page.full,true)
            for i,row in ipairs(page.rows) do
                if row[1] and (row[1].kind=='number' or row[1].kind=='spinner') then
                    assert(i>1 and page.rows[i-1][1].kind=='label','Input needs a separate label row')
                    equal(#row,1); found[row[1].name]=page.title
                end
            end
        end
        equal(found.repeat_min_minutes,'Repeat delay after stage ends')
        equal(found.repeat_max_minutes,'Repeat delay after stage ends')
        equal(found.selected_boost_name,'Random boost')
        equal(found.press_min_ms,'Tap timing'); equal(found.press_max_ms,'Tap timing')
        equal(found.tap_pause,'Tap timing'); equal(found.dim_percent,'Screen brightness')
    end
end)
test('portrait saved-window startup skips irrelevant fullscreen/manual settings', function()
    reset(); realWidth,realHeight=1080,2400
    dialogValues.screen_mode='Reuse saved game window'
    local restore=fakeProfileIO('1 1080 2400 0 24 1080 700\n')
    fails(function() dofile('main.lua') end,'EXIT:Calibration finished')
    restore()
    equal(#dialogs,1); equal(dialogs[1].full,true)
    for _,row in ipairs(dialogs[1].rows) do
        if row[1] then assert(row[1].name~='screen_width' and row[1].name~='screen_manual') end
    end
end)
test('manual rectangle fields remain individually editable on a portrait display', function()
    reset(); realWidth,realHeight=1080,2400; appArea={x=0,y=0,w=1080,h=2400}
    dialogValues={screen_manual=true,screen_x=0,screen_y=24,screen_width=1080,screen_height=700}
    fails(function() dofile('main.lua') end,'EXIT:Calibration finished')
    equal(#dialogs,4); equal(dialogs[3].title,'Game rectangle: position')
    equal(dialogs[4].title,'Game rectangle: size')
    equal(viewport.y,24); equal(viewport.w,1080); equal(viewport.h,700); equal(#clicks,0)
end)
test('game-window review separates position and size fields without changing picked coordinates', function()
    reset(); realWidth,realHeight=1080,2400
    local points={Location(0,24),Location(1080,724)}
    getTouchEvent=function() return 'click',table.remove(points,1) end
    local restore=fakeProfileIO()
    local rect=require('window_profile').select()
    restore(); getTouchEvent=nil
    equal(rect.y,24); equal(rect.h,700)
    equal(dialogs[3].title,'Review game window: position')
    equal(dialogs[4].title,'Review game window: size')
    for _,page in ipairs(dialogs) do equal(page.full,true) end
end)
test('dialog helper falls back to ordinary dialog API when fullscreen dialogs are unavailable', function()
    reset(); local original=dialogShowFullScreen; dialogShowFullScreen=nil
    dialogInit(); require('ui').number('Minimum wait','ui_test_value',1); require('ui').show('Fallback')
    dialogShowFullScreen=original
    equal(dialogs[1].full,false); equal(ui_test_value,1)
end)
test('real bot clears result and both reward screens while repeat delay counts down', function()
    reset(); dialogValues={repeat_min_minutes=1,repeat_max_minutes=1}
    local originalDetect,originalClick=detection.detect_stage,click
    local stage='GAME_COMPLETE'
    local resultAt=math.floor(now)
    local menuTap, rewardTaps, resultTaps=nil,0,0
    detection.detect_stage=function() return stage end
    click=function(point)
        originalClick(point)
        if stage=='GAME_COMPLETE' then
            resultTaps=resultTaps+1
            if resultTaps==2 then stage='MYSTERY_BOX' end
        elseif stage=='MYSTERY_BOX' then
            rewardTaps=rewardTaps+1
            assert(now-resultAt<60,'Reward clearing should not block on the repeat delay')
            if rewardTaps==2 then stage='MAINMENU' end
        elseif stage=='MAINMENU' then menuTap=now; stage='PURCHASE_ITEM'
        elseif stage=='PURCHASE_ITEM' then error('RESULT_REPEAT_COMPLETE') end
    end
    fails(function() require('bot').main() end,'RESULT_REPEAT_COMPLETE')
    detection.detect_stage,click=originalDetect,originalClick
    equal(resultTaps,2); equal(rewardTaps,2)
    assert(menuTap-resultAt>=60 and menuTap-resultAt<62,'Result retries/reward screens must not reset the deadline')
end)
test('direct lobby after results also waits and rechecks before buying or playing', function()
    reset(); dialogValues={repeat_min_minutes=1,repeat_max_minutes=1,use_random_boost=true}
    local originalDetect,originalClick=detection.detect_stage,click
    local stage='GAME_COMPLETE'; local resultAt=math.floor(now); local checked=false
    detection.detect_stage=function(names)
        if checked then error('LOBBY_RECHECKED') end
        if stage=='PURCHASE_ITEM' and now-resultAt>=60 then
            checked=true
            return 'MAINMENU' -- A different screen appeared during the wait.
        end
        return stage
    end
    click=function(point)
        originalClick(point)
        if stage=='GAME_COMPLETE' then stage='PURCHASE_ITEM'
        else error('STALE_LOBBY_TAP') end
    end
    fails(function() require('bot').main() end,'LOBBY_RECHECKED')
    detection.detect_stage,click=originalDetect,originalClick
    assert(checked); equal(#clicks,1)
end)

os.time=realTime
_G.type=type
print=output
output('Passed ' .. count .. ' tests (mock AnkuLua API; physical phone testing still required).')
