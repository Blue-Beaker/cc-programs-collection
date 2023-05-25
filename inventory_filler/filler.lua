KeepCount=16
DrainCount=32
termprint=print
function print(message,noterm)
    if type(message)~="string" then
        message = textutils.serialize(message)
    end
    if not noterm then termprint(message) end
end
function FillItem(item,i)
    local item2={}
    item2["name"]=item["name"]
    -- item2["nbt"]=textutils.serialize(item["nbt"])
    local itemME,err1=MEBridge.getItem(item2)
    -- print(itemME)
    if itemME~=nil then
        local count=item["count"]
        local countME=itemME["count"]
        if count>4 and countME>0 then
            if count<KeepCount then
                itemME["count"]=KeepCount-count
                MEBridge.exportItem(itemME,"up")
                InventoryManager.addItemToPlayer("right",64,i)
                print("Filled "..KeepCount-count.." x "..itemME["name"])
            elseif count>DrainCount then
                InventoryManager.removeItemFromPlayer("right",count-DrainCount,i)
                item2["count"]=65535
                MEBridge.importItem(item2,"up")
                print("Drained "..count-DrainCount.." x "..itemME["name"])
            end

        end
    end
end
MEBridge=peripheral.find("meBridge")
InventoryManager=peripheral.find("inventoryManager")
print("ME Filler Loaded!\nFills or drains items in hotbar from/to ME network automatically.\nKeeping "..KeepCount.."~"..DrainCount.." For every stack.")
while true do
    local items=InventoryManager.getItems()
    for i=0,8 do
        local item=items[i]
        -- local item=InventoryManager.getItemInHand()
        if item~=nil then
            -- print(i)
            -- print(item)
            FillItem(item,i)
        end
    end
    sleep(1)
end