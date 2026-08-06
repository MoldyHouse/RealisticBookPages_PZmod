require("ISUI/ISToolTipInv")

local API = require("RealisticBookPages/Applicator")

local function isManagedLiterature(item)
    if not item or not instanceof or not instanceof(item, "Literature") then
        return false
    end

    API.prepareLiteratureMoodEffects(item)
    return item:hasModData()
        and item:getModData().RBP_GradualMoodEffects == true
        and item:getNumberOfPages() > 0
end

local function renderWithTotalPages(tooltip)
    local item = tooltip.item
    local pages = item:getNumberOfPages()
    local data = item:getModData()
    local previousTooltip = data.Tooltip

    -- Literature.DoTooltip hardcodes "shared progress / total". Suppress that
    -- row only while the tooltip renders and use InventoryItem's custom text
    -- row for the stable total instead. The reading item is restored before
    -- this function returns and its actual progress is never accessed here.
    item:setNumberOfPages(-1)
    data.Tooltip = getText("Tooltip_literature_Number_of_Pages")
        .. ": " .. tostring(pages)

    local ok, result = pcall(function()
        return ISToolTipInv.RBP_originalRender(tooltip)
    end)

    data.Tooltip = previousTooltip
    item:setNumberOfPages(pages)

    if not ok then
        error(result)
    end
    return result
end

if not ISToolTipInv.RBP_originalRender then
    ISToolTipInv.RBP_originalRender = ISToolTipInv.render

    function ISToolTipInv:render()
        if not isManagedLiterature(self.item) then
            return ISToolTipInv.RBP_originalRender(self)
        end
        return renderWithTotalPages(self)
    end
end
