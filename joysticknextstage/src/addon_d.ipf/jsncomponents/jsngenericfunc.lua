--jsnobject.lua
--アドオン名（大文字）
local addonName = "jsn_commonlib"
local addonNameLower = string.lower(addonName)
--作者名
local author = 'ebisuke'
--アドオン内で使用する領域を作成。以下、ファイル内のスコープではグローバル変数gでアクセス可
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}
local g = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local function EBI_try_catch(what)
    local status, result = pcall(what.try)
    if not status then
        what.catch(result)
    end
    return result
end
local function EBI_IsNoneOrNil(val)
    return val == nil or val == "None" or val == "nil"
end


local function DBGOUT(msg)
    
    EBI_try_catch{
        try = function()
            if (g.debug == true) then
                CHAT_SYSTEM(msg)
                
                print(msg)
                local fd = io.open(g.logpath, "a")
                fd:write(msg .. "\n")
                fd:flush()
                fd:close()
            
            end
        end,
        catch = function(error)
        end
    }

end
local function ERROUT(msg)
    EBI_try_catch{
        try = function()
            CHAT_SYSTEM(msg)
            print(msg)
        end,
        catch = function(error)
        end
    }

end
g.callbackFunctionTable={}
g.sounds={
    CURSOR_MOVE="button_over",
    DETERMINE="button_click_3",
    CANCEL="button_v_click",
    POPUP="UI_card_move",
    ERROR='skill_cooltime'
}
g.fn={
    CleanupSingletons=function()
        for _,v in pairs(g.singleton) do
            v:release()
        end
        g.singleton={}
    end,
    CalcPosVirtualToReal=function (x, y)
        local sw = option.GetClientWidth()
        local sh = option.GetClientHeight()
        --representative fullscreen frame
        local frame = ui.GetFrame("worldmap2_mainmap")
        local ow = frame:GetWidth()
        local oh = frame:GetHeight()
        return x * (ow/sw), y * ( oh/sh)
    end,
    CalcPosRealToVirtual=function (x, y)
        local sw = option.GetClientWidth()
        local sh = option.GetClientHeight()
        --representative fullscreen frame
        local frame = ui.GetFrame("worldmap2_mainmap")
        local ow = frame:GetWidth()
        local oh = frame:GetHeight()
        return x * (sw/ow), y * ( sh/oh)
    end,
    ReserveFunction=function (delay,fn)
        callbackFunctionTable[tostring(fn)]=fn
        ReserveScript(string.format("JSN_COMMONLIB_CALLBACK_FUNCTION('%s')",tostring(fn)),delay)
    end,
    InputNumberBox=function (owner,title,default,min,max,callback)
        return g.classes.JSNInputbox(g.jsnmanager,owner,title,default,min,max,callback):init()
        --callbackFunctionTable[tostring(callback)]=callback
        --INPUT_NUMBER_BOX(nil, title, "JSN_COMMONLIB_CALLBACK_FUNCTION", default, min, max, nil, tostring(callback), 1);
    end,
    temporallyEnableControlRestriction=function (fn)
        local delay=0.00
        local token=g.classes.JSNManager():getInstance():temporallyEnableControlRestriction()
        g.fn.ReserveFunction(delay,function ()
            fn()
            token:release()
        end)
    end,
    ShowToolTip=function(typename,tipname,x,y)
        local frame=ui.GetFrame("inventory")
    end,
    MarkAsDontOverride=function (frame,remove)
        if(remove)then
            frame:SetUserValue("JSN_DONT_OVERRIDE",nil)
        else
            frame:SetUserValue("JSN_DONT_OVERRIDE",1)
        end
       
    end,
    HideToolTip=function ()
        local tooltipFrame = ui.GetFrame("item_tooltip");
        ui.CloseFrame("item_tooltip");
    end,
    GenerateMenuByItem=function(invItem,sender,slot)
        local menus={}
        local cls=GetClassByType("Item",invItem.type)
        local iesid=invItem:GetIESID()
        local clsid=invItem.type
        local invObject=GetIES(invItem:GetObject())
        if(cls.ItemType=="Equip") then
            menus[#menus+1] = {
                text="Equip Item",
                onClick=function()
                   
                        ITEM_EQUIP_BY_ID(iesid);
                    
                    
    
                end
            }
        elseif(not invItem.isLockState) then
            menus[#menus+1] = {
                text="Use Item",
                onClick=function()
                   
                        INV_ICON_USE(invItem)
                    
                    
                end
            }
        end
    
        if(cls.ItemType=="Equip" and REINFORCE_ABLE_131014(invObject)~=0) then
            menus[#menus+1] = {
                text="Reinforce",
                onClick=function()
                    local filter=function(invItem)
                        local cls=GetClassByType("Item",invItem.type)
    
                        return cls.ClientScp=='CLIENT_MORU'
                      
                    end
                    DBGOUT("Reinforce"..sender._className)
                    g.classes.JSNInventoryFrame(
                        g.classes.JSNManager():getInstance(),
                        sender,
                        filter,
                        sender and slot:getGlobalX(),
                        sender and slot:getGlobalY(),
                        "Choose a anvil"
                    ):init():setEventHandler({
                        eventUserRequestedDetermine=
                            function(moru,_sender,_slot)
                                CLIENT_MORU(moru)
                                MORU_LBTN_CLICK(nil,invItem)
                                REINFORCE_131014_EXEC()
                                if(g.classes.JSNOmniScreen():getInstance())then
                                    g.classes.JSNOmniScreen():getInstance():release()
                                end
                             
                                return true
                            end,
                        e
                    })
                end
            }
        end    
        return menus
    end
}

function JSN_COMMONLIB_CALLBACK_FUNCTION(id,...)
    if(g.callbackFunctionTable[id])then
        g.callbackFunctionTable[id](...)
        g.callbackFunctionTable[id]=nil
    end
end

function JSN_COMMONLIB_CTRL_CALLBACK_FUNCTION(frame,ctrl,argstr,argnum)
    if(g.callbackFunctionTable[argstr])then
        g.callbackFunctionTable[argstr](frame,ctrl,nil,argnum)
        g.callbackFunctionTable[argstr]=nil
    end
end