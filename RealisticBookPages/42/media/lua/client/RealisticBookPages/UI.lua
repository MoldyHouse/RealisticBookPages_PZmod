require("ISUI/ISToolTipInv")

local Progress = require("RealisticBookPages/Progress")

if not ISToolTipInv.RBP_originalRender then
    ISToolTipInv.RBP_originalRender = ISToolTipInv.render

    function ISToolTipInv:render()
        local character = self.tooltip and self.tooltip:getCharacter()
        if not character or not Progress.isManaged(self.item) then
            return ISToolTipInv.RBP_originalRender(self)
        end

        return Progress.withItemProgress(character, self.item, function()
            return ISToolTipInv.RBP_originalRender(self)
        end)
    end
end

