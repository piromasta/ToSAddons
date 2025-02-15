--アドオン名（大文字）
local addonName = "testboard"
local addonNameLower = string.lower(addonName)
--作者名
local author = "ebisuke"

--アドオン内で使用する領域を作成。以下、ファイル内のスコープではグローバル変数gでアクセス可
_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {}
local g = _G["ADDONS"][author][addonName]
local acutil = require("acutil")
g.version = 0
g.settings = {x = 300, y = 300, volume = 100, mute = false}
g.settingsFileLoc = string.format("../addons/%s/settings.json", addonNameLower)
g.personalsettingsFileLoc = ""
g.framename = "testboard"
g.debug = true
g.handle = nil
g.interlocked = false
g.currentIndex = 1
g.x = nil
g.y = nil
g.buffs = {}
g.prevtime = nil
g.framelist = {}
--ライブラリ読み込み
CHAT_SYSTEM("[TESTBOARD]loaded")
local acutil = require("acutil")
function EBI_try_catch(what)
    local status, result = pcall(what.try)
    if not status then
        what.catch(result)
    end
    return result
end
function EBI_IsNoneOrNil(val)
    return val == nil or val == "None" or val == "nil"
end

local function DBGOUT(msg)
    EBI_try_catch {
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
    EBI_try_catch {
        try = function()
            CHAT_SYSTEM(msg)
            print(msg)
        end,
        catch = function(error)
        end
    }
end
function TESTBOARD_SAVE_SETTINGS()
    --CAMPCHEF_SAVETOSTRUCTURE()
    acutil.saveJSON(g.settingsFileLoc, g.settings)
end

function TESTBOARD_LOAD_SETTINGS()
    TESTBOARD_DBGOUT("LOAD_SETTING")
    g.settings = {foods = {}}
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings)
    if err then
        --設定ファイル読み込み失敗時処理
        TESTBOARD_DBGOUT(string.format("[%s] cannot load setting files", addonName))
        g.settings = {}
    else
        --設定ファイル読み込み成功時処理
        g.settings = t
        if (not g.settings.version) then
            g.settings.version = 0
        end
    end

    TESTBOARD_UPGRADE_SETTINGS()
    TESTBOARD_SAVE_SETTINGS()
end

function TESTBOARD_UPGRADE_SETTINGS()
    local upgraded = false
    return upgraded
end
-- if OLD_ON_AOS_OBJ_ENTER==nil then
--     OLD_ON_AOS_OBJ_ENTER=ON_AOS_OBJ_ENTER
--     ON_AOS_OBJ_ENTER=TESTBOARD_ON_AOS_OBJ_ENTER
-- end
--マップ読み込み時処理（1度だけ）
function TESTBOARD_ON_INIT(addon, frame)
    EBI_try_catch {
        try = function()
            frame = ui.GetFrame(g.framename)
            g.addon = addon
            g.frame = frame
            --g.personalsettingsFileLoc = string.format('../addons/%s/settings_%s.json', addonNameLower,tostring(CAMPCHEF_GETCID()))
            acutil.addSysIcon("testboard", "sysmenu_sys", "testboard", "TESTBOARD_TOGGLE_FRAME")
            addon:RegisterMsg("GAME_START_3SEC", "TESTBOARD_SHOW")
            --ccするたびに設定を読み込む
            if not g.loaded then
                g.loaded = true
            end
            --addon:RegisterMsg("ZONE_TRAFFICS", "TESTBOARD_ON_ZONE_TRAFFICS");

            addon:RegisterMsg("BUFF_ADD", "TESTBOARD_BUFF_ON_MSG")
            --addon:RegisterMsg('BUFF_REMOVE', 'TESTBOARD_BUFF_ON_MSG');
            --addon:RegisterMsg('BUFF_UPDATE', 'TESTBOARD_BUFF_ON_MSG');
            --  --コンテキストメニュー
            -- frame:SetEventScript(ui.RBUTTONDOWN, "AFKMUTE_TOGGLE")
            -- --ドラッグ
            -- frame:SetEventScript(ui.LBUTTONUP, "AFKMUTE_END_DRAG")
            --TESTBOARD_SHOW(g.frame)
            --TESTBOARD_GETFRAME_OLD=ui.GetFrame
            --ui.GetFrame=TESTBOARD_GETFRAME
            TESTBOARD_INIT()
            g.frame:ShowWindow(0)
        end,
        catch = function(error)
            ERROUT(error)
        end
    }
end
function TESTBOARD_SHOW(frame)
    --frame = ui.GetFrame(g.framename)
    --frame:ShowWindow(1)
    --imcAddOn.BroadMsg("WEEKLY_BOSS_DPS_START");
end
function TESTBOARD_CLOSE(frame)
    frame = ui.GetFrame(g.framename)
    frame:ShowWindow(0)
end
function TESTBOARD_TOGGLE_FRAME(frame)
    ui.ToggleFrame(g.framename)
end
function TESTBOARD_INIT()
    EBI_try_catch {
        try = function()
            local frame = ui.GetFrame(g.framename)
            local button = frame:CreateOrGetControl("button", "btn", 0, 80, 200, 100)
            AUTO_CAST(button)
            button:SetEventScript(ui.LBUTTONUP, "TESTBOARD_TEST")
            button:SetText("INJECT LOVE!")

            local timer = GET_CHILD(frame, "addontimer", "ui::CAddOnTimer")
            timer:SetUpdateScript("TESTBOARD_ON_TIMER")
            timer:Start(0.01)
            timer:EnableHideUpdate(true)
            local cframe = ui.GetFrame("chat_option")
            local chks = cframe:CreateOrGetControl("checkbox", "damageCheck_my", 200, 200, 100, 30)
            AUTO_CAST(chks)
            local chkm = cframe:CreateOrGetControl("checkbox", "damageCheck_others", 200, 230, 100, 30)
            AUTO_CAST(chkm)
            chks:SetConfigName("BattleMsg_Damage_others")
            chkm:SetConfigName("BattleMsg_Damage_my")
            chks:SetEventScript(ui.LBUTTONUP, "CHAT_OPTION_UPDATE_CHECKBOX")
            chkm:SetEventScript(ui.LBUTTONUP, "CHAT_OPTION_UPDATE_CHECKBOX")
        end,
        catch = function(error)
            ERROUT(error)
        end
    }
end
function C_SR_EFT(self, target, sklLevel, hitInfo, hitIndex, eft, scl, x, y, z, lifeTime, delayTime)
    if delayTime == nil then
        delayTime = 0
    end
    CHAT_SYSTEM(tostring(hitInfo))
    local key = "None"
    local radAngle = 0
    effect.PlayGroundEffect(self, eft, scl, x, y, z, lifeTime, key, radAngle, delayTime)
end
function EFT_AND_HIT(self, target, sklLevel, hitInfo, hitIndex, eft, scl, x, y, z, lifeTime, delayTime)
    CHAT_SYSTEM(tostring(hitInfo))
end
function SKILL_USE_SCRIPT(self, target, sklLevel, hitInfo, hitIndex, eft, scl, x, y, z, lifeTime, delayTime)
    CHAT_SYSTEM("USESCP" .. tostring(hitInfo))
end

function SCR_COMMON_POST_HIT(self, target, sklLevel, hitInfo, hitIndex, eft, scl, x, y, z, lifeTime, delayTime)
    CHAT_SYSTEM(tostring(self))
end

function SCR_COMMON_POST_KILL(self, target, sklLevel, hitInfo, hitIndex, eft, scl, x, y, z, lifeTime, delayTime)
    CHAT_SYSTEM(tostring(self))
end

-- done , 해당 함수 내용은 cpp로 이전되었습니다. 변경 사항이 있다면 반드시 프로그램팀에 알려주시기 바랍니다.
function SCR_GET_TransmitPrana_BuffTime(skill)
    local value = 60

    CHAT_SYSTEM(tostring(skill))
    return value
end

function C_SR_EFT_DEFAULT(
    self,
    target,
    sklLevel,
    hitInfo,
    hitIndex,
    selfEeffectName,
    selfScale,
    selfOffset,
    targetEeffectName,
    targetScale,
    targetOffset)
    if selfEeffectName ~= nil and selfEeffectName ~= "None" and selfEeffectName ~= "" then
        self:GetEffect():PlayEffect(selfEeffectName, selfScale, GetOffsetEnum(selfOffset))
    end
    CHAT_SYSTEM(tostring(hitInfo))
    if targetEeffectName ~= nil and targetEeffectName ~= "None" and targetEeffectName ~= "" then
        local isMyEffect = self:GetHandleVal() == GetMyActor():GetHandleVal()
        local isBoss = false
        if self:GetObjType() == GT_MONSTER then
            if self.MonRank == "Boss" then
                isBoss = true
            end
        end

        target:GetEffect():PlayEffect(isMyEffect, isBoss, targetEeffectName, targetScale, GetOffsetEnum(targetOffset))
    end
end

function C_SR_EFT2(self, target, sklLevel, hitInfo, hitIndex, effectName, scale, nodeName, lifeTime)
    if lifeTime == nil then
        lifeTime = 0
    end
    CHAT_SYSTEM(tostring(hitInfo))
    effect.PlayActorEffect(self, effectName, nodeName, lifeTime, scale)
end

function C_EFFECT_USE_XYZ(actor, obj, effectName, scale, nodeName, x, y, z)
    CHAT_SYSTEM(tostring(nodeName))
    effect.PlayActorEffect(actor, effectName, nodeName, lifeTime, scale, x, y, z)
end
function C_EFFECT_POS(actor, obj, eftName, scl, x, y, z, lifeTime, key)
    if key == nil then
        key = "None"
    end
    CHAT_SYSTEM(tostring(eftName))
    effect.PlayGroundEffect(actor, eftName, scl, x, y, z, lifeTime, key)
end

function C_EFFECT_ATTACH(actor, obj, eftName, scl, scl2, x, y, z, autoDetach, angle)
    if angle == nil then
        angle = -1
    end

    if x == nil then
        effect.AddActorEffect(actor, eftName, scl * scl2, 0, 0, 0, angle)
    else
        effect.AddActorEffect(actor, eftName, scl * scl2, x, y, z, angle)
    end
    CHAT_SYSTEM(tostring(eftName))
    -- �� ���̾�ó�� ��ų�� ���� ScpArgMsg("Auto_iPegTeuTteKi")�� ������������ ����ϸ� ��
    if autoDetach == 1 then
        actor:GetEffect():AddAutoDetachEffect(eftName)
    end
end

function C_EFFECT(actor, obj, effectName, scale, nodeName, lifeTime)
    if lifeTime == nil then
        lifeTime = 0
    end

    -- 포포팝 피스톨 체크
    if IS_EXIST_BRIQUETTING_OR_BEAUTYSHOP_ITEM(actor, "LH", "Pistol", obj.type, 634214) == true then
        effectName = "None"
    end
    CHAT_SYSTEM(tostring(effectName))
    effect.PlayActorEffect(actor, effectName, nodeName, lifeTime, scale)
end
function I_SYS_damage_self(arg)
    CHAT_SYSTEM(tostring(arg))
end
function SYS_heal2(arg)
    CHAT_SYSTEM(tostring(arg))
end
function SKL_TGT_DMG(arg)
    CHAT_SYSTEM(tostring(arg))
end
function C_FORCE_EFT(
    actor,
    obj,
    eft,
    scale,
    snd,
    finEft,
    finEftScale,
    finSnd,
    destroy,
    fSpeed,
    easing,
    gravity,
    angle,
    hitIndex,
    collrange,
    createLength,
    radiusSpd,
    isLastForce,
    useHitEffect,
    linkTexName,
    dist,
    offSetAngle,
    height,
    delayStart,
    fixVerDir)
    CHAT_SYSTEM(tostring(eft))
    local item = session.GetEquipItemBySpot(item.GetEquipSpotNum("RH"))
    if item ~= nil then
        local equipItemObj = GetIES(item:GetObject())

        if obj.type == 30005 and equipItemObj.ClassType == "Musket" then
            eft = "I_archer_musket_atk#Dummy_Force_musket"
        end
    end

    if useHitEffect == nil then
        useHitEffect = 1
    end

    if radiusSpd == nil then
        radiusSpd = 0.0
    end

    if createLength == nil then
        createLength = 0.0
    end

    if linkTexName == nil then
        linkTexName = "None"
    end

    if customTarget == nil then
        customTarget = 0
    end

    if delayStart == nil then
        delayStart = 0
    end

    local addX = 0
    local addY = 0
    local addZ = 0
    if dist == nil or offSetAngle == nil or height == nil then
    else
        if dist > 0 then
            offSetAngle = DegToRad(offSetAngle)
            addX = math.cos(offSetAngle) * dist
            addY = height
            addZ = math.sin(offSetAngle) * dist
        end
    end

    if fixVerDir == nil then
        fixVerDir = 0
    end

    local ret =
        actor:GetForce():PlayForce_Tool(
        eft,
        scale,
        snd,
        finEft,
        finEftScale,
        finSnd,
        destroy,
        fSpeed,
        easing,
        gravity,
        angle,
        hitIndex,
        collrange,
        createLength,
        radiusSpd,
        useHitEffect,
        customTarget,
        linkTexName,
        delayStart,
        addX,
        addY,
        addZ,
        fixVerDir
    )

    -- ������������ ������ ��ųĵ�� �����ϰ� ���ش�.
    if isLastForce == 1 or isLastForce == nil then -- nil�� üũ�ϴ������� �����þȵȰ� �� ������ ������������� ������
        actor:EnableSkillCancel(1)
    end

    return ret
end
function C_EFFECT_ATTACH_OOBE(actor, obj, eftName, scl, scl2, x, y, z, autoDetach)
    local oobeActor = actor:GetOOBEActor()
    if oobeActor ~= nil then
        if x == nil then
            effect.AddActorEffect(oobeActor, eftName, scl * scl2, 0, 0, 0)
        else
            effect.AddActorEffect(oobeActor, eftName, scl * scl2, x, y, z)
        end

        -- �� ���̾�ó�� ��ų�� ���� ScpArgMsg("Auto_iPegTeuTteKi")�� ������������ ����ϸ� ��
        if autoDetach == 1 then
            oobeActor:GetEffect():AddAutoDetachEffect(eftName)
        end
    end
    CHAT_SYSTEM(tostring(eftName))
end
function TESTBOARD_GETFRAME(name)
    local frame = TESTBOARD_GETFRAME_OLD(name)
    if (frame) then
        g.framelist[name] = frame
    end
    return frame
end
function TESTBOARD_ON_TIMER(frame)
    EBI_try_catch {
        try = function()
            local buff = info.GetBuff(session.GetMyHandle(), 4644)
            local skillInfo = session.GetSkill(100104, true)
            local skillInfo2 = session.GetSkill(100105, true)
            local skillInfo3 = session.GetSkill(100106, true)
            if skillInfo or skillInfo2 or skillInfo3 then
                if skillInfo then
                    local ies = GetIES(skillInfo:GetObject(), true)
                    local real = GetSkill(GetMyPCObject(), ies.ClassName)
                    local cd = --CHAT_SYSTEM("SHAKE_FOOT" .. buff.buffID .. "/" .. buff.time)
                    CHAT_SYSTEM(
                        "SHAKE_FOOT VIVORA" ..
                            skillInfo:GetCurrentCoolDownTime() .. "/" .. ies.CoolDown .. ies.ClassName
                    )
                end
                if skillInfo2 then
                    local ies = GetIES(skillInfo2:GetObject(), true)
                    local real = GetSkill(GetMyPCObject(), ies.ClassName)
                    --CHAT_SYSTEM("SHAKE_FOOT" .. buff.buffID .. "/" .. buff.time)
                    CHAT_SYSTEM(
                        "SHAKE_FOOT VIVORA" ..
                            skillInfo2:GetCurrentCoolDownTime() .. "/" .. ies.CoolDown .. "/" .. ies.ClassName
                    )
                end
                if skillInfo3 then
                    local ies = GetIES(skillInfo3:GetObject(), true)
                    local real = GetSkill(GetMyPCObject(), ies.ClassName)
                    --CHAT_SYSTEM("SHAKE_FOOT" .. buff.buffID .. "/" .. buff.time)
                    CHAT_SYSTEM(
                        "SHAKE_FOOT VIVORA" ..
                            skillInfo3:GetCurrentCoolDownTime() ..
                                "/" .. skillInfo3:GetRemainRefreshTimeMS() .. ies.ClassName
                    )
                end
            end

            -- local target = session.GetTargetHandle()

            -- if not target then
            --     return
            -- end

            -- local stat = info.GetStat(target);
            --CHAT_SYSTEM("HP:" .. stat.HP)
            --[[
        pc:DetachCopiedModel();
        pc:ChangeEquipNode(EmAttach.eHelmet, "Dummy_L_HAND");
        pc:ChangeEquipNode(EmAttach.eLHand, "Dummy_L_HAND");
        pc:ChangeEquipNode(EmAttach.eRHand, "Dummy_L_HAND");
        
        pc:CopyAttachedModel(EmAttach.eLHand, "Dummy_L_HAND");
        pc:CopyAttachedModel(EmAttach.eRHand, "Dummy_L_HAND");
        ]]
        end,
        catch = function(error)
            ERROUT(error)
        end
    }
end
-- done , 해당 함수 내용은 cpp로 이전되었습니다. 변경 사항이 있다면 반드시 프로그램팀에 알려주시기 바랍니다.
function SCR_GET_Heal_Ratio(skill)
    print(tostring(skill))
    print(tostring(skill.HitScript))
    skill.HitScript = "SKILL_USE_SCRIPT"
    local pc = GetSkillOwner(skill)
    local pcINT = TryGetProp(pc, "INT")
    if pcINT == nil then
        pcINT = 1
    end

    local pcMNA = TryGetProp(pc, "MNA")
    if pcMNA == nil then
        pcMNA = 1
    end

    local value = (pcINT + pcMNA) * 2

    return math.floor(value)
end
function TESTBOARD_BUFF_ON_MSG(frame, msg, argStr, argNum)
    local buff = info.GetBuff(session.GetMyHandle(), 4669) or info.GetBuff(session.GetMyHandle(), 4644)
    if buff == nil then
        return 0
    end
    CHAT_SYSTEM("SHAKE_FOOT" .. buff.buffID .. "/" .. buff.time)
end
local function setskill(slot, skill)
    local skl = skill
    local icon = CreateIcon(slot)
    if skl == nil then
        if icon ~= nil then
            tolua.cast(icon, "ui::CIcon")
            icon:SetTooltipNumArg(0)
        end
        slot:ClearIcon()

        return
    end
    local sklObj = GetIES(skl:GetObject());
    local type=sklObj.ClassID

   
    if IS_NEED_CLEAR_SLOT(skl, type) == true then
        if icon ~= nil then
            tolua.cast(icon, "ui::CIcon")
            icon:SetTooltipNumArg(0)
        end
        slot:ClearIcon()

        return
    end
    local imageName = "icon_" .. GetClassString("Skill", type, "Icon")

    icon:SetOnCoolTimeUpdateScp("ICON_UPDATE_SKILL_COOLDOWN")
    icon:SetEnableUpdateScp("ICON_UPDATE_SKILL_ENABLE")
    icon:SetColorTone("FFFFFFFF")
    icon:ClearText()
    if imageName ~= "" then
        if iesID == nil then
            iesID = ""
        end

        local category = category
        local type = type

        slot:SetPosTooltip(0, 0)
      

        icon:SetTooltipType("skill")
        local skl = session.GetSkill(type)
        if skl ~= nil then
            iesID = skl:GetIESID()
        end

        -- expand tooltip
        local sklObj = GetClassByType("Skill", type)
        if sklObj ~= nil then
            if TryGetProp(sklObj, "ExpandSkillTooltip", "None") ~= "None" then
                icon:SetTooltipType("skill_expand")
            end
        end
    

        icon:Set(imageName, category, type, 0, iesID)
        icon:SetTooltipNumArg(type)
        icon:SetTooltipStrArg("quickslot")
        icon:SetTooltipIESID(iesID)
    

        INIT_QUICKSLOT_SLOT(slot, icon)
        local sendPacket = 1
        if false == sendSavePacket then
            sendPacket = 0
        end

        local icon = slot:GetIcon()
        if icon ~= nil then
            icon:SetDumpArgNum(slot:GetSlotIndex())
        end
    else
        slot:EnableDrag(0)
    end
end
function TESTBOARD_TEST(frame)
    EBI_try_catch {
        try = function()
            local frame = ui.GetFrame(g.framename)

            dofile(
                "\\\\theseventhbody.local\\E\\TosProject\\TosAddons\\testboard\\src\\addon_d.ipf\\testboard\\testboard.lua"
            )
            local slot = frame:CreateOrGetControl("slot", "saaa", 120, 200, 48, 48)
            local slot2 = frame:CreateOrGetControl("slot", "saaa2", 170, 200, 48, 48)
            local slot3 = frame:CreateOrGetControl("slot", "saaa3", 220, 200, 48, 48)
            AUTO_CAST(slot)
            AUTO_CAST(slot2)
            AUTO_CAST(slot3)

            slot:SetSkinName("invenslot2")
            slot2:SetSkinName("invenslot2")
            slot3:SetSkinName("invenslot2")

            setskill(slot, session.GetSkill(100104, true))
            setskill(slot2, session.GetSkill(100105, true))
            setskill(slot3, session.GetSkill(100106, true))

            slot:ShowWindow(1)
            slot2:ShowWindow(1)
            slot3:ShowWindow(1)
            --     DAMAGE_METER_UI_OPEN(ui.GetFrame("damage_meter"),nil,"0/1",100000);
            --     --local cls=GetClassByStrProp("Skill", "ClassName", "Cleric_Heal");
            --     --local ssss=geSkillTable.Get(cls.ClassName);
            --     local ssss=GetClass("Skill","Exorcist_Entity");
            --     --ssss= GetIES(ssss:GetObject())
            --     print(tostring(ssss.HitScript))
            --     ssss.HitScript="SKILL_USE_SCRIPT"
            --OPEN_PERSONAL_SHOP_REGISTER()
            --DAMAGE_METER_UI_OPEN(ui.GetFrame('damage_meter'),nil,'0/PRACTICE',1)
            --geMGame.ReqMGameCmd("WEEKLY_BOSS_RAID_01",2)
            --ui.PropertyCompare(session.GetTargetHandle(), 1, 0);
            --local pc = GetMyActor()
            -- local itemClsList, cnt = GetClassList('NormalTX');
            -- for i = 0, cnt - 1 do
            --     local itemCls = GetClassByIndexFromList(itemClsList, i);
            --     CHAT_SYSTEM(string.format('%d/%s', itemCls.ClassID, itemCls.ClassName))
            -- end

            -- local target = session.GetTargetHandle()

            -- if not target then

            --      return
            -- end
            -- local targetinfo = info.GetTargetInfo(target);
            -- local monactor = world.GetActor(target);
            -- local ies=GetIES(targetinfo:GetIESObject())
            -- local monactor = world.GetActor(target);
            -- local montype = monactor:GetType()

            -- local monclass = GetClassByType("Monster", montype);
            -- local tempObj = CreateGCIES('Monster', monclass.ClassName);
            -- SetExProp(tempObj, 'STARRANK', info.GetMonRankbyHandle(target))
            -- tempObj.Lv = targetinfo.level
            -- CHAT_SYSTEM("HP:" .. math.floor(SCR_Get_MON_MHP(tempObj)))
            -- CHAT_SYSTEM("PATK:" .. math.floor(SCR_Get_MON_MAXPATK(tempObj)))
            -- CHAT_SYSTEM("MATK:" .. math.floor(SCR_Get_MON_MAXMATK(tempObj)))
            -- CHAT_SYSTEM("PDEF:" .. math.floor(SCR_Get_MON_DEF(tempObj)))
            -- CHAT_SYSTEM("MDEF:" .. math.floor(SCR_Get_MON_MDEF(tempObj)))

            -- DestroyIES(tempObj);
            --pc.ReqExecuteTx_NumArgs('SCR_TX_TP_SHOP',{1})
            --RunScript('SCR_WEEKLY_BOSS_DPS_START()')
            --pc.ReqExecuteTx_Item("ABILITY_POINT_RESET", "SCR_WEEKLY_BOSS_DPS_START",'SCR_WEEKLY_BOSS_DPS_START');
            --pc.ReqExecuteTx_Item("ABILITY_POINT_RESET", "SCR_WEEKLY_BOSS_DPS_START",'SCR_WEEKLY_BOSS_DPS_START');
            -- local pos=pc:GetPos()
            -- local actor=pc
            -- local targetActor=world.GetActor(session.GetTargetHandle())
            -- --PlayEffect(actor, 'F_circle020_light', 1.5,1,'BOT')
            -- effect.PlayTextEffect(pc,"I_SYS_damage_4","100");
            -- effect.PlayTextEffect(pc,"I_SYS_damage_3","100")
            -- effect.PlayTextEffect(pc,"I_SYS_damage_2","100");
            -- effect.PlayTextEffect(pc,"I_SYS_damage_1","100");
            -- effect.PlayTextEffect(pc,"I_SYS_damage",'100');
            -- effect.PlayTextEffect(pc,"SHOW_DMG_SHIELD","100");
            -- effect.PlayTextEffect(pc,"I_SYS_heal2","100");

            -- iesman.ChangeIESProp("NormalTX",40, "SCR_TX_COLORSPRAY", "ClassName", "SCR_WEEKLY_BOSS_DPS_START", "Change By Tool", 1);
            -- pc.ReqExecuteTx("SCR_WEEKLY_BOSS_DPS_START",0);
            -- local cls = GetClass("NormalTX", "SCR_WEEKLY_BOSS_DPS_START");
            -- print(cls.Script)
            -- local objList, objCount = SelectObject(self, 300, 'ALL')
            -- CHAT_SYSTEM("Thaurge BEGIN")
            -- for i = 1, objCount do
            --     local enemyHandle = GetHandle(objList[i]);
            --     local enemy = world.GetActor(enemyHandle);
            --     local ies=GetIES(GetObject(enemyHandle))
            --     print(tostring(ies)..GetObject(enemyHandle))
            --     -- if objList[i].ClassName == 'pcskill_Warlock_DarkTheurge' then
            --     --     local enemyDestPos = enemy:GetArgPos(0);
            --     --     local enemyPos = enemy:GetPos();
            --     --     local distFromActor = imcMath.Vec3Dist(enemyPos, pos);
            --     --     CHAT_SYSTEM("Thaurge"..enemyHandle..":"..tostring(objList[i].Faction))
            --     -- end
            --     -- if objList[i].ClassID==150011 then
            --     --     ACCEPT_NEXT_LEVEL_CHALLENGE_MODE(enemyHandle)
            --     -- end
            --     -- if objList[i].ClassID==150010 then
            --     --     ACCEPT_CHALLENGE_MODE(enemyHandle)
            --     -- end
            --     break
            -- end
            -- -- for i = 1, objCount do
            --     local enemyHandle = GetHandle(objList[i]);
            --     local enemy = world.GetActor(enemyHandle);
            --     if objList[i].ClassName == 'pcskill_Warlock_DarkTheurge' then
            --         local enemyDestPos = enemy:GetArgPos(0);
            --         local enemyPos = enemy:GetPos();
            --         local distFromActor = imcMath.Vec3Dist(enemyPos, pos);
            --         CHAT_SYSTEM("Thaurge"..enemyHandle..":"..tostring(objList[i].Faction))
            --     end
            --     if objList[i].ClassID==150011 then
            --         ACCEPT_NEXT_LEVEL_CHALLENGE_MODE(enemyHandle)
            --     end
            --     if objList[i].ClassID==150010 then
            --         ACCEPT_CHALLENGE_MODE(enemyHandle)
            --     end
            -- end
            -- local actor = GetMyActor()
            -- local scenePos = world.GetActorPos(actor:GetHandleVal());
            -- scenePos.y = scenePos.x;
            -- local scenePos2 = world.GetActorPos(actor:GetHandleVal());
            -- scenePos2.x = scenePos2.x+50;
            -- --pc:SetDirMoveSpeed(33);
            -- --pc:SetDirMoveAccel(33);
            -- actor:SetMoveFromPos(scenePos);
            -- actor:SetMoveDestPos(scenePos2);
            -- actor:SetDirDestPos(scenePos2);
            -- actor:SetFSMTime( imcTime.GetAppTime() );
            -- --actor:ActorJump(10000, 100);
            -- --actor:ProcessDirMove(0.1);
            -- actor:MoveDirTo(scenePos2,1)
            --DAMAGE_METER_UI_OPEN(ui.GetFrame('damage_meter'),nil,'0/PRACTICE',1)
        end,
        catch = function(error)
            ERROUT("FAIL:" .. tostring(error))
        end
    }
end
-- function BEFORE_APPLIED_NON_EQUIP_ITEM_OPEN(invItem)
--     if invItem == nil then
--         return;
--     end
--     local invFrame = ui.GetFrame("inventory");
--     local itemobj = GetIES(invItem:GetObject());
--     if itemobj == nil then
--         return;
--     end
--     if SYSMENU_INVENTORY_WEIGHT_NOTICE == nil then
--         --older one
--         invFrame:SetUserValue("INVITEM_GUID", invItem:GetIESID());
--     else
--         --newer
--         invFrame:SetUserValue("REQ_USE_ITEM_GUID", invItem:GetIESID());
--     end
--     if itemobj.Script == 'SCR_SUMMON_MONSTER_FROM_CARDBOOK' then
--         --REQUEST_SUMMON_BOSS_TX()
--         local pos=GetMyActor():GetPos()
--         item.UseItemToHandlePos(invItem,session.GetMyHandle());
--         return;
--     elseif itemobj.Script == 'SCR_QUEST_CLEAR_LEGEND_CARD_LIFT' then
--         local textmsg = string.format("[ %s ]{nl}%s", itemobj.Name, ScpArgMsg("Use_Item_LegendCard_Slot_Open2"));
--         ui.MsgBox_NonNested(textmsg, itemobj.Name, "REQUEST_SUMMON_BOSS_TX", "None");
--         return;
--     end
-- end
function TESTBOARD_TAKEDAMAGE()
    DBGOUT("take")
end
function TESTBOARD_SCP()
    DBGOUT("scp")
end
function TESTBOARD_RELOAD()
    dofile("\\\\theseventhbody.local\\E\\TosProject\\TosAddons\\testboard\\src\\addon_d.ipf\\testboard\\testboard.lua")
end
