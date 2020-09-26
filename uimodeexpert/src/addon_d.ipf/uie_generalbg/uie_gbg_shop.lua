--uie_gbg_shop
local acutil = require('acutil')


--ライブラリ読み込み
local debug = false
function EBI_try_catch(what)
    local status, result = pcall(what.try)
    if not status then
        what.catch(result)
    end
    return result
end
function EBI_IsNoneOrNil(val)
    return val == nil or val == 'None' or val == 'nil'
end
local function DBGOUT(msg)
    EBI_try_catch {
        try = function()
            if (debug == true) then
                CHAT_SYSTEM(msg)

                print(msg)
                local fd = io.open(g.logpath, 'a')
                fd:write(msg .. '\n')
                fd:flush()
                fd:close()
            end
        end,
        catch = function(error)
        end
    }
end
local function ERROUT(msg)
    EBI_try_catch {
        try = function()
            CHAT_SYSTEM(msg)
            print(msg)
        end,
        catch = function(error)
        end
    }
end

local function inherit(class, super, ...)
    local self = (super and super.new(...) or {})
    setmetatable(self, {__index = class})
    setmetatable(class, {__index = super})
    return self
end

UIMODEEXPERT = UIMODEEXPERT or {}

local g = UIMODEEXPERT

g.gbg=g.gbg or {}

g.gbg.uiegbgShop={
    new=function(frame,name,caption)
        local shopName = session.GetCurrentShopName()
        local self=inherit(g.gbg.uiegbgShop,g.gbg.uiegbgBase,frame,name,caption or  'ショップ')
        return self
    end,
    initializeImpl=function(self,gbox)

        local inv=g.gbg.uiegbgComponentShopInventory.new(self,gbox,'inventory',true,function()
            self:update()
        end)
        inv:initialize(gbox:GetWidth()/2+140,60,gbox:GetWidth()/2-160,gbox:GetHeight()-190)
        self:addComponent(inv)
        local shop=g.gbg.uiegbgComponentShop.new(self,gbox,'shop',function()
            self:update()
        end)
        shop:initialize(60,60,gbox:GetWidth()/2-120,gbox:GetHeight()-190)
        self:addComponent(shop)
        local zeny=g.gbg.uiegbgComponentFund.new(self,gbox,'fund')
        zeny:initialize(gbox:GetWidth()-260,10,200,50)
        self:addComponent(zeny)
        local trade=g.gbg.uiegbgComponentTradeResult.new(self,gbox,'trade',inv,shop)
        trade:initialize(gbox:GetWidth()/2-100,100,200,250)
        self:addComponent(trade)
        local under=g.gbg.uiegbgComponentUnderBtn.new(self,gbox,'under',{
            {
                name="clear",
                caption='空にする',
                callback=function() inv:reset();shop:reset(); end,

            },
            {
                name="determine",
                caption='精算',
                callback=function() self:adjustment();self:close(); end,

            },
            {
                name="cancel",
                caption='キャンセル',
                callback=function() self:close() end,
            }
        })
        under:initialize(100,gbox:GetHeight()-140,gbox:GetWidth()-200,100)
        
        self:addComponent(under)
    end,
    defaultHandlerImpl = function(self,key,frame)
        --override me
        return g.uieHandlergbgShop.new(key,frame,self)
    end,
    update=function(self)
        local shop=self:getComponent('shop')
        local buy=shop:calcTotalValue()
        local inventory=self:getComponent('inventory')
        local sell=inventory:calcTotalValue()
        local trade=self:getComponent('trade')
        local balance=SumForBigNumberInt64(buy,'-'..sell)
        trade:updateBalance(balance)
    end,
    adjustment=function(self)
        local shop=self:getComponent('shop')
        local buy=shop:calcTotalValue()
        local inventory=self:getComponent('inventory')
        local sell=inventory:calcTotalValue()
        local trade=self:getComponent('trade')
        local balance=SumForBigNumberInt64(buy,'-'..sell)
        if IsGreaterThanForBigNumber(balance, GET_TOTAL_MONEY_STR()) == 1 then
            ui.AddText("SystemMsgFrame", ClMsg('NotEnoughMoney'));
            return;
        end
        self:doSell()
        self:doBuy()
        imcSound.PlaySoundEvent("market_sell");

    end,
    doSell=function(self)
        local inventory=self:getComponent('inventory')
        for _,v in ipairs(inventory.invItemList) do
            if v.amount and v.amount >0 then
                item.AddToSellList(v.item:GetIESID(), v.amount);
            end
        end
        item.SellList();
    end,
    doBuy=function(self)
        local inventory=self:getComponent('shop')
        for _,v in ipairs(inventory.invItemList) do
            if v.amount and v.amount >0 then
                if GET_SHOP_ITEM_MAXSTACK(v.item)~=-1 then
                    item.AddToBuyList(v.item.classID, v.amount);
                else
                    for i=1,v.amount do
                        item.AddToBuyList(v.item.classID, 1);
                    end
                end
               
            end
        end
        item.BuyList();
    end,

}
g.uieHandlergbgShop = {
    new = function(key, frame,gbg)
        local self = inherit(g.uieHandlergbgShop, g.uieHandlergbgBase, key,frame,gbg)
       
        return self
    end,
    delayedenter = function(self)
        g.uieHandlergbgBase.delayedenter(self)
        local menu=g.menu.uiePopupMenu.new(nil,nil,200)
        menu:addMenu('{ol}かごを空にする',function()
            self.gbg:adjustment()
        end,false)
        menu:addMenu('{ol}買う',function()
            
        end)
        menu:addMenu('{ol}売る',function()

        end)
        
        menu:addMenu('{ol}精算',function()
            self.gbg:adjustment()
            self.gbg:close()
        end)
        menu:addMenu('{ol}キャンセル',function()
            self.gbg:close()
        end)
    end,
    tick = function(self)
        return g.uieHandlerBase.RefPass
    end
}
UIMODEEXPERT = g