local Progress = {}

local function isSkillBook(item)
    if not item or not SkillBook then
        return false
    end

    local skill = item:getSkillTrained()
    return skill and skill ~= "" and SkillBook[skill] ~= nil
end

function Progress.isManaged(item)
    if not item or isSkillBook(item) or item:getNumberOfPages() <= 0 then
        return false
    end
    if not item:hasModData() then
        return false
    end

    return item:getModData().RBP_GradualMoodEffects == true
end

function Progress.clearShared(character, item)
    if character and Progress.isManaged(item) then
        character:setAlreadyReadPages(item:getFullType(), 0)
    end
end

function Progress.resetAfterCooldown(character, item)
    if not Progress.isManaged(item) then
        return false
    end

    local data = item:getModData()
    local title = data.literatureTitle
    if not title or title == "" then
        return false
    end

    local readLiterature = character:getReadLiterature()
    if not readLiterature or not readLiterature:containsKey(title) then
        return false
    end
    if character:isLiteratureRead(title) then
        return false
    end

    local completedDay = tostring(readLiterature:get(title))
    if data.RBP_ProgressResetDay == completedDay then
        return false
    end

    item:setAlreadyReadPages(0)
    data.RBP_ProgressResetDay = completedDay
    return true
end


-- Vanilla reading and tooltip code expects character progress by fullType.
-- Expose one item's value only for the duration of that vanilla call.
function Progress.withItemProgress(character, item, callback)
    if not character or not Progress.isManaged(item) then
        return callback()
    end

    Progress.resetAfterCooldown(character, item)
    character:setAlreadyReadPages(
        item:getFullType(),
        math.max(0, math.min(
            item:getNumberOfPages(),
            item:getAlreadyReadPages()
        ))
    )

    local ok, result1, result2, result3 = pcall(callback)
    character:setAlreadyReadPages(item:getFullType(), 0)

    if not ok then
        error(result1)
    end
    return result1, result2, result3
end


return Progress
