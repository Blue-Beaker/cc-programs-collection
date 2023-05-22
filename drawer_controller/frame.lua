function Move(axis,steps,fast)
    local color=0
    local dir
    if steps>0 then
        dir=1
    elseif steps<0 then
        dir=-1
    else
        return
    end
    if axis==3 then
        color=colors.lightBlue
    elseif axis==2 then
        color=0
    elseif axis==1 then
        color=colors.magenta
    end
    if dir==1 then
        color=color+colors.orange
    end
    local i=0
    while i~=steps do
        if fast then
            redstone.setBundledOutput("left",color+colors.yellow)
            sleep(0.25)
        else
            redstone.setBundledOutput("left",color)
            sleep(0.3)
            redstone.setBundledOutput("left",color+colors.white)
            sleep(0.2)
        end
        Pos[axis]=Pos[axis]+dir
        i=i+dir
    end
    sleep(0.5)
    redstone.setBundledOutput("left",0)
    print("X:"..Pos[1].." Y:"..Pos[2].." Z:"..Pos[3])
end
function MoveDir(direction,steps)
    local axis,dir
    if direction=="up" then
        axis=3
        dir=1
    elseif direction=="down" then
        axis=3
        dir=-1
    elseif direction=="north" then
        axis=2
        dir=-1
    elseif direction=="south" then
        axis=2
        dir=1
    elseif direction=="west" then
        axis=1
        dir=1
    elseif direction=="east" then
        axis=1
        dir=-1
    end
    Move(axis,steps*dir)
end
function MoveAxis(x,y,z,relative,force,fast)
    if relative then
        x=x and x+Pos[1]
        y=y and y+Pos[2]
        z=z and z+Pos[3]
    end
    x=x or Pos[1]
    y=y or Pos[2]
    z=z or Pos[3]
    if not force then
        x=math.min(math.max(x,0),Max[1])
        y=math.min(math.max(y,0),Max[2])
        z=math.min(math.max(z,0),Max[3])
    end
    local x1,y1,z1
    if x~=nil then x1=x-Pos[1] end
    if y~=nil then y1=y-Pos[2] end
    if z~=nil then z1=z-Pos[3] end
    if z1~=nil and z1<0 then
        print("Moving Z "..z1)
        Move(3,z1,fast)
    end
    if y1~=nil and y1>0 then
        print("Moving Y "..y1)
        Move(2,y1,fast)
    end
    if x1~=nil then
        print("Moving X "..x1)
        Move(1,x1,fast)
    end
    if y1~=nil and y1<0 then
        print("Moving Y "..y1)
        Move(2,y1,fast)
    end
    if z1~=nil and z1>0 then
        print("Moving Z "..z1)
        Move(3,z1,fast)
    end
end
function Grab()
    local color=redstone.getBundledOutput("left")
    sleep(0.2)
    redstone.setBundledOutput("left",colors.combine(color,colors.black))
    sleep(0.2)
    redstone.setBundledOutput("left",color)
end
function Home()
    if Reader.getBlockName()~="create:sticker" then
        print("HOMING...")
        MoveAxis(-32,-32,-24,true,true,true)
    end
    Pos={0,0,0}
    print("HOMED!")
end
function Pickup()
    Home()
    MoveAxis(0,0,1,false)
    Grab()
    MoveAxis(0,0,0,false)
end
function Read(show)
    MoveAxis(0,1,0,false)
    local block=Reader.getBlockName()
    print("Found "..block)
    print(Reader.getBlockData())
    return block
end
function ListItems(show,showFull)
    local list=Controller.list()
    for i,j in pairs(list) do
        -- print(j)
        local str1=""
        if show then
            if showFull then
                str1="/"..Controller.getItemLimit(i)
            end
            print(j["count"]..str1.." * "..j["name"])
        end
    end
end
function Push(y)
    y=y or 32
    MoveAxis(nil,y,nil,false)
    MoveAxis(32,nil,32,false,false,true)
    Grab()
end
function PickAndPush()
    Pickup()
    local block=Read()
    if block=="storagedrawers:compacting_drawers_3" then
        Push(14)
    else
        Push(31)
    end
    Home()
end
function Analyze()
    local function sort(item1,item2)
        return item1[1]/item1[2]<item2[1]/item2[2]
    end
    local list=Controller.list()
    local items={}
    for i,j in pairs(list) do
        local content={j["count"],Controller.getItemLimit(i),j["name"]}
        table.insert(items,content)
        local cx,cy=term.getCursorPos()
        term.write("Analyzing "..i.."/"..#list)
        term.setCursorPos(cx,cy)
    end
    table.sort(items,sort)
    local outFile=fs.open("analyze.txt","w")
    for i,j in pairs(items) do
        local str=string.format("%q/%q\t%q\t%.2f%%",j[1],j[2],j[3],j[1]/j[2]*100)
        print(str)
        outFile.write(str.."\n")
    end
    outFile.close()
    print("Result saved to file analyze.txt")
end
function MonitorPrint(message)
    local mx,my=Monitor.getSize()
    if string.len(message)>mx then
        MonitorPrint(string.sub(message,1,mx))
        MonitorPrint(string.sub(message,mx+1))
    else
        Monitor.setCursorPos(1, my)
        Monitor.write(message)
        Monitor.scroll(1)
    end
end
function GetNumber(str)
    local success,result=pcall(GetNumberRaw,str)
    return success and result
end
function GetNumberRaw(str)
    return str+0
end
function DoCommand(code)
    local list={}
    local x,y,z
    print(code,false)
    for section in string.gmatch(string.upper(code), "[^ ]+") do
        list[#list+1]=section
        local label=string.sub(section,1,1)
        if label=="X" then
            x=GetNumber(string.sub(section,2))
        elseif label=="Y" then
            y=GetNumber(string.sub(section,2))
        elseif label=="Z" then
            z=GetNumber(string.sub(section,2))
        end
    end
    -- print(string.format("%q,%q,%q",x,y,z))
    local instruct = list[1]
    if instruct=="MOVE" then
        MoveAxis(x,y,z,false)
    elseif instruct=="MOVEREL" then
        MoveAxis(x,y,z,false)
    elseif instruct=="HOME" then
        Home()
    elseif instruct=="GRAB" then
        Grab()

    elseif instruct=="PICK" then
        Pickup()
    elseif instruct=="PUSH" then
        Push()

    elseif instruct=="PICKPUSH" then
        PickAndPush()
    elseif instruct=="ADD" then
        PlaceDrawer()
        PickAndPush()
    elseif instruct=="HALT" or instruct=="STOP" then
        print("Halted!")
        Run=false

    elseif instruct=="READ" then
        Read(true)
    elseif instruct=="LIST" then
        ListItems(true)
    elseif instruct=="LISTFULL" then
        ListItems(true,true)
    elseif instruct=="ANALYZE" then
        Analyze()
    else
        print("Usage:\nMOVE|MOVEREL X[X] Y[Y] Z[Z]\nGRAB\nPICK|PUSH|PICKPUSH|ADD\nREAD|LIST|LISTFULL\n[HALT|STOP]")
    end
    print("X:"..Pos[1].." Y:"..Pos[2].." Z:"..Pos[3])
end
function SplitString(str)
end
Max={31,31,23}
Pos={0,0,0}
Run=true
Relative=false
Monitor = peripheral.find("monitor")
ChatBox = peripheral.find("chatBox")
Reader = peripheral.find("blockReader")
Controller = peripheral.find("storagedrawers:controller")
ShowChat=false
termprint=print
function print(message,noterm,nomonitor)
    if type(message)~="string" then
        message = textutils.serialize(message)
    end
    if not noterm then termprint(message) end
    if not nomonitor then MonitorPrint(message) end
    if ShowChat then ChatBox.sendMessage(message,"DRAWER") end
end
while Run do
    local command
    local event, value1,value2,value3 = os.pullEvent()
    if event=="chat" then
        ShowChat=true
        local message=value2
        if string.upper(string.sub(message,1,7))=="DRAWER " then
            command=string.sub(message,8)
            DoCommand(command)
        end
    elseif event=="key" then
        write("Input command or cancel:")
        command=read()
        if string.len(command)>0 then
            DoCommand(command)
        end
    elseif event=="redstone" then
        while redstone.getInput("right") do
            PickAndPush()
        end
    end
    ShowChat=false
end