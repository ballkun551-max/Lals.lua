--========================================================
-- BALL KUN MAHANAKHON AI AUTO HUB V6 | IN-GAME UI
-- Credit: บอลคุง ไงหนู
-- Game: MAHANAKHON RACING
-- Executor: Ninja Executor (Client-Side Lua)
--
-- Features:
-- 1. Pure White Typography System (ฟอนต์สีขาวทั้งระบบ อ่านชัดพรีเมียม)
-- 2. Smart Thai Pin Translator (กรองชิ้นส่วนหลอกเช่น KneeBrace และแปลปักหมุดเป็นภาษาไทย)
-- 3. Responsive UIScale + Drag/Resize (ไม่ล้นขอบจอมือถือ/แท็บเล็ต)
-- 4. Full In-Game UI Customizer (ระบบปรับแต่ง UI ได้ทั้งหมดแบบเรียลไทม์)
-- 5. Safe Prep Mode for Auto Systems (เตรียมระบบออโต้ไว้ต่อยอดภายหลัง)
-- Background Asset: BALL_KUN_BG.png
--========================================================

if game.PlaceId ~= 104549080643413 then
    warn("[BALL KUN MAHANAKHON] PlaceId ไม่ตรงกับ MAHANAKHON RACING")
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local LP = Players.LocalPlayer

local CONFIG = {
    HubTitle = "BALL KUN MAHANAKHON",
    Subtitle = "AI AUTO HUB V6",
    Tagline = "INTELLIGENT CONTROL CENTER  •  IN-GAME UI  •  ANDROID TOUCH",
    Credit = "บอลคุง ไงหนู",
    Background = "BALL_KUN_BG.png",
    BackgroundEnabled = true,
    BackgroundTransparency = 0.56,
    BackgroundScrimTransparency = 0.52,
    BackgroundScaleMode = Enum.ScaleType.Crop,
    WindowWidth = 1000,
    WindowHeight = 680,
    SidebarWidth = 220,
    CornerRadius = 14,
    PanelTransparency = 0.10,
    BorderThickness = 1.5,
    BorderTransparency = 0.55,
    UiScale = 1.00,
    AutoFitMobile = true,
    FontScale = 1.00,
    FontBold = Enum.Font.GothamBold,
    FontRegular = Enum.Font.GothamMedium,
    ShowRightPanel = true,
    ShowFooter = true,
    SmoothMotion = true,
    FilterInvalidParts = true,
    ShowRawNameHint = false,
}

local Theme = {
    surface = Color3.fromRGB(4, 9, 7),
    card = Color3.fromRGB(10, 19, 15),
    cardActive = Color3.fromRGB(17, 43, 31),
    accent = Color3.fromRGB(34, 220, 132),
    accentFill = Color3.fromRGB(8, 82, 49),
    white = Color3.fromRGB(255, 255, 255), -- ฟอนต์ทั้งหมดเป็นสีขาวบริสุทธิ์
    mutedWhite = Color3.fromRGB(242, 246, 244),
    switchOff = Color3.fromRGB(40, 48, 44),
}

local PIN_RULES = {
    { keyword = "racestart", thai = "จุดปล่อยตัวสนามแข่ง", category = "สนามแข่ง" },
    { keyword = "racefinish", thai = "เส้นชัยสนามแข่ง", category = "สนามแข่ง" },
    { keyword = "drag", thai = "สนามแดร็กทางตรง", category = "สนามแข่ง" },
    { keyword = "tuneshop", thai = "ร้านจูนรถและแต่งเครื่อง", category = "จูนและแต่งรถ" },
    { keyword = "dyno", thai = "แท่นทดสอบแรงม้า (ไดโน่)", category = "จูนและแต่งรถ" },
    { keyword = "tune", thai = "จุดจูนรถ", category = "จูนและแต่งรถ" },
    { keyword = "garage", thai = "อู่ซ่อมและเก็บรถ", category = "อู่รถ" },
    { keyword = "repair", thai = "จุดซ่อมรถฉุกเฉิน", category = "อู่รถ" },
    { keyword = "dealer", thai = "โชว์รูมซื้อขายรถ", category = "ร้านค้า" },
    { keyword = "piston", thai = "ร้านลูกสูบ 53–90", category = "ร้านค้า" },
    { keyword = "fuel", thai = "ปั๊มน้ำมันเชื้อเพลิง", category = "บริการ" },
    { keyword = "gas", thai = "จุดเติมน้ำมัน", category = "บริการ" },
    { keyword = "shop", thai = "ร้านค้าอุปกรณ์รถ", category = "ร้านค้า" },
    { keyword = "race", thai = "จุดแข่งขันในแผนที่", category = "สนามแข่ง" },
}

local IGNORED_PART_KEYWORDS = {
    "kneebrace", "brace", "accessory", "humanoid", "torso",
    "leftarm", "rightarm", "leftleg", "rightleg", "head",
    "handle", "shirt", "pants", "helmet", "glove", "shoe", "boot", "wheel", "tire"
}

local S = {
    page = "หน้าหลัก",
    selectedCar = nil,
    selectedTarget = nil,
    route = {},
    fps = false,
    saved = {},
    flags = {},
    alive = true,
    piston = 53,
    lastPiston = "",
    dynamicRefs = {},
}

local function new(class, props, parent)
    local x = Instance.new(class)
    for k, v in pairs(props or {}) do x[k] = v end
    x.Parent = parent
    return x
end

local function corner(obj, r)
    return new("UICorner", {CornerRadius = UDim.new(0, r or CONFIG.CornerRadius)}, obj)
end

local function stroke(obj, color, thick, trans)
    return new("UIStroke", {
        Color = color or Theme.accent,
        Thickness = thick or CONFIG.BorderThickness,
        Transparency = trans or CONFIG.BorderTransparency,
    }, obj)
end

local function gradient(obj, c1, c2, rot)
    return new("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 30}, obj)
end

local function fs(baseSize)
    return math.max(9, math.round(baseSize * CONFIG.FontScale))
end

local function tweenProp(obj, props, dur)
    if not CONFIG.SmoothMotion then
        for k, v in pairs(props) do obj[k] = v end
        return
    end
    TweenService:Create(obj, TweenInfo.new(dur or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

-- Clean old instance if re-executed
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("BALL_KUN_MAHANAKHON_AI_AUTO_HUB_V6")
    if old then old:Destroy() end
    local pg = LP:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("BALL_KUN_MAHANAKHON_AI_AUTO_HUB_V6") then pg.BALL_KUN_MAHANAKHON_AI_AUTO_HUB_V6:Destroy() end
end)

pcall(function()
    local oldV4 = game:GetService("CoreGui"):FindFirstChild("BALL_KUN_HUB_PREMIUM_V4")
    if oldV4 then oldV4:Destroy() end
    local pg = LP:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("BALL_KUN_HUB_PREMIUM_V4") then pg.BALL_KUN_HUB_PREMIUM_V4:Destroy() end
end)

local Gui = new("ScreenGui", {
    Name = "BALL_KUN_MAHANAKHON_AI_AUTO_HUB_V6",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, nil)

local parentOk = pcall(function() Gui.Parent = game:GetService("CoreGui") end)
if not parentOk or not Gui.Parent then Gui.Parent = LP:WaitForChild("PlayerGui") end

local Main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(CONFIG.WindowWidth, CONFIG.WindowHeight),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = Theme.surface,
    BackgroundTransparency = CONFIG.PanelTransparency,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, Gui)
local MainCorner = corner(Main, CONFIG.CornerRadius)
local MainStroke = stroke(Main, Theme.accent, CONFIG.BorderThickness, 0.15)
gradient(Main, Theme.card, Theme.surface, 35)

local MainScale = new("UIScale", {Scale = CONFIG.UiScale}, Main)

local function updateResponsiveScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    if vp.X < 700 then
        -- Mobile uses a viewport-sized window; do not shrink all text to desktop scale.
        MainScale.Scale = 1
    elseif CONFIG.AutoFitMobile then
        local fitX = (vp.X - 36) / math.max(1, CONFIG.WindowWidth)
        local fitY = (vp.Y - 36) / math.max(1, CONFIG.WindowHeight)
        MainScale.Scale = math.clamp(math.min(CONFIG.UiScale, fitX, fitY, 1), 0.55, 1.25)
    else
        MainScale.Scale = math.clamp(CONFIG.UiScale, 0.55, 1.25)
    end
end
updateResponsiveScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale)
end

-- Background Artwork + Dark Scrim for readable White Text
local Art = new("ImageLabel", {
    Name = "Backdrop",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ImageTransparency = CONFIG.BackgroundTransparency,
    ScaleType = CONFIG.BackgroundScaleMode,
    Visible = CONFIG.BackgroundEnabled,
    ZIndex = 0,
}, Main)
pcall(function()
    if getcustomasset then Art.Image = getcustomasset(CONFIG.Background) end
end)

local Scrim = new("Frame", {
    Name = "BackdropScrim",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Theme.surface,
    BackgroundTransparency = CONFIG.BackgroundScrimTransparency,
    BorderSizePixel = 0,
    ZIndex = 1,
}, Main)

-- Top Header (Premium Luxury Bar, All White Typography)
local Top = new("Frame", {
    Size = UDim2.new(1, 0, 0, 88),
    BackgroundColor3 = Theme.surface,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
    ZIndex = 3,
}, Main)
local TopStroke = stroke(Top, Theme.accent, 1, 0.45)

local Logo = new("TextLabel", {
    Position = UDim2.new(0, 18, 0, 10),
    Size = UDim2.new(1, -178, 0, 32),
    BackgroundTransparency = 1,
    Text = "♛  " .. CONFIG.HubTitle,
    TextColor3 = Theme.white,
    Font = Enum.Font.GothamBlack,
    TextSize = fs(24),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
}, Top)

local Sub = new("TextLabel", {
    Position = UDim2.new(0, 18, 0, 42),
    Size = UDim2.new(1, -178, 0, 18),
    BackgroundTransparency = 1,
    Text = CONFIG.Subtitle .. "  •  โดย " .. CONFIG.Credit,
    TextColor3 = Theme.white,
    Font = CONFIG.FontBold,
    TextSize = fs(12),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
}, Top)

local Tagline = new("TextLabel", {
    Position = UDim2.new(0, 18, 0, 62),
    Size = UDim2.new(1, -130, 0, 18),
    BackgroundTransparency = 1,
    Text = CONFIG.Tagline,
    TextColor3 = Theme.mutedWhite,
    Font = CONFIG.FontRegular,
    TextSize = fs(11),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
}, Top)

local Reopen = new("TextButton", {
    Size = UDim2.fromOffset(164, 42),
    Position = UDim2.new(0, 16, 0.5, -21),
    BackgroundColor3 = Theme.surface,
    Text = "♛  " .. CONFIG.HubTitle,
    TextColor3 = Theme.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 13,
    Visible = false,
    ZIndex = 50,
}, Gui)
corner(Reopen, 10)
stroke(Reopen, Theme.accent, 1.5, 0.2)

local function topButton(text, xOffset, callback)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(34, 32),
        Position = UDim2.new(1, xOffset, 0, 14),
        BackgroundColor3 = Theme.cardActive,
        Text = text,
        TextColor3 = Theme.white,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        ZIndex = 5,
    }, Top)
    corner(b, 8)
    stroke(b, Theme.accent, 1, 0.35)
    b.MouseButton1Click:Connect(callback)
    return b
end

topButton("■", -128, function()
    if S.stopAll then
        S.stopAll()
    else
        clearRoute()
        toast("หยุดระบบตรวจสอบที่กำลังทำงานแล้ว")
    end
end)

topButton("—", -86, function()
    Main.Visible = false
    Reopen.Visible = true
end)

topButton("×", -44, function()
    if S.stopAll then pcall(S.stopAll) end
    S.alive = false
    if S.fps then
        Lighting.GlobalShadows = S.saved.shadows
        Lighting.FogEnd = S.saved.fog
        for obj, v in pairs(S.saved.effects or {}) do
            if obj and obj.Parent then pcall(function() obj.Enabled = v end) end
        end
    end
    Gui:Destroy()
end)

Reopen.MouseButton1Click:Connect(function()
    Main.Visible = true
    Reopen.Visible = false
end)

-- Layout Containers
local Sidebar = new("ScrollingFrame", {
    Position = UDim2.fromOffset(12, 98),
    Size = UDim2.new(0, CONFIG.SidebarWidth, 1, CONFIG.ShowFooter and -150 or -110),
    BackgroundColor3 = Theme.surface,
    BackgroundTransparency = 0.16,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Theme.accent,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 3,
}, Main)
corner(Sidebar, math.max(6, CONFIG.CornerRadius - 2))
stroke(Sidebar, Theme.accent, 1, 0.55)
new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, Sidebar)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, Sidebar)

local RightWidth = 196
local Right = new("Frame", {
    Position = UDim2.new(1, -(RightWidth + 12), 0, 98),
    Size = UDim2.new(0, RightWidth, 1, CONFIG.ShowFooter and -150 or -110),
    BackgroundTransparency = 1,
    Visible = CONFIG.ShowRightPanel,
    ZIndex = 3,
}, Main)
new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, Right)

local Body = new("Frame", {
    Position = UDim2.fromOffset(CONFIG.SidebarWidth + 22, 98),
    Size = UDim2.new(1, -(CONFIG.SidebarWidth + (CONFIG.ShowRightPanel and (RightWidth + 44) or 34)), 1, CONFIG.ShowFooter and -150 or -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 3,
}, Main)

local Scroll = new("ScrollingFrame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.accent,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 3,
}, Body)
local BodyList = new("UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder}, Scroll)
new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12)}, Scroll)

local Footer = new("Frame", {
    Position = UDim2.new(0, 12, 1, -44),
    Size = UDim2.new(1, -24, 0, 32),
    BackgroundColor3 = Theme.surface,
    BackgroundTransparency = 0.14,
    Visible = CONFIG.ShowFooter,
    ZIndex = 4,
}, Main)
corner(Footer, 9)
stroke(Footer, Theme.accent, 1, 0.5)
new("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "⚡ ใช้งานง่าย   •   🛡 โหมดตรวจสอบปลอดภัย   •   🇹🇭 ปักหมุดแปลไทย   •   ♛ " .. CONFIG.Credit,
    TextColor3 = Theme.white,
    Font = CONFIG.FontBold,
    TextSize = fs(11),
    ZIndex = 5,
}, Footer)

local Grip

local function applyLayoutRefresh()
    local cam = Workspace.CurrentCamera
    local mobile = cam ~= nil and cam.ViewportSize.X < 700
    Main.BackgroundTransparency = CONFIG.PanelTransparency
    MainCorner.CornerRadius = UDim.new(0, CONFIG.CornerRadius)
    MainStroke.Color = Theme.accent
    MainStroke.Thickness = CONFIG.BorderThickness
    TopStroke.Color = Theme.accent
    Art.Visible = CONFIG.BackgroundEnabled
    Art.ImageTransparency = CONFIG.BackgroundTransparency
    Scrim.BackgroundTransparency = CONFIG.BackgroundScrimTransparency

    if mobile then
        Main.Size = UDim2.new(0.96, 0, 0.84, 0)
        MainScale.Scale = 1
        Top.Size = UDim2.new(1, 0, 0, 78)
        Logo.TextSize = fs(18)
        Sub.TextSize = fs(9)
        Right.Visible = false
        Footer.Visible = false
        Sidebar.Position = UDim2.fromOffset(8, 88)
        Sidebar.Size = UDim2.new(0, 126, 1, -98)
        Body.Position = UDim2.fromOffset(142, 88)
        Body.Size = UDim2.new(1, -150, 1, -98)
        Grip.Visible = false
        for _, nav in ipairs(Sidebar:GetChildren()) do
            if nav:IsA("TextButton") then
                nav.Size = UDim2.new(1, 0, 0, 50)
                nav.Text = "•  " .. nav.Name
                nav.TextSize = fs(10)
            end
        end
    else
        Main.Size = UDim2.fromOffset(CONFIG.WindowWidth, CONFIG.WindowHeight)
        Top.Size = UDim2.new(1, 0, 0, 88)
        Logo.TextSize = fs(24)
        Sub.TextSize = fs(11)
        Right.Visible = CONFIG.ShowRightPanel
        Footer.Visible = CONFIG.ShowFooter
        Sidebar.Position = UDim2.fromOffset(12, 98)
        Sidebar.Size = UDim2.new(0, CONFIG.SidebarWidth, 1, CONFIG.ShowFooter and -150 or -110)
        Right.Size = UDim2.new(0, RightWidth, 1, CONFIG.ShowFooter and -150 or -110)
        Body.Position = UDim2.fromOffset(CONFIG.SidebarWidth + 22, 98)
        Body.Size = UDim2.new(1, -(CONFIG.SidebarWidth + (CONFIG.ShowRightPanel and (RightWidth + 44) or 34)), 1, CONFIG.ShowFooter and -150 or -110)
        Grip.Visible = true
        for _, nav in ipairs(Sidebar:GetChildren()) do
            if nav:IsA("TextButton") then
                nav.Size = UDim2.new(1, 0, 0, 44)
                local desktopText = nav:GetAttribute("DesktopText")
                if desktopText then nav.Text = desktopText end
                nav.TextSize = fs(11)
            end
        end
        updateResponsiveScale()
    end
end

local function toast(msg)
    local t = new("TextLabel", {
        Size = UDim2.fromOffset(340, 42),
        Position = UDim2.new(1, -356, 1, -58),
        BackgroundColor3 = Theme.surface,
        Text = "  " .. tostring(msg),
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(12),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 80,
    }, Gui)
    corner(t, 9)
    stroke(t, Theme.accent, 1.3, 0.15)
    task.delay(3.0, function() if t then t:Destroy() end end)
end

local function clearBody()
    for _, v in ipairs(Scroll:GetChildren()) do
        if v ~= BodyList and v:IsA("GuiObject") then v:Destroy() end
    end
end

local function section(text)
    return new("TextLabel", {
        Size = UDim2.new(1, -4, 0, 28),
        BackgroundTransparency = 1,
        Text = "  " .. text,
        TextColor3 = Theme.white,
        Font = Enum.Font.GothamBlack,
        TextSize = fs(15),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, Scroll)
end

local function info(text, h)
    local f = new("TextLabel", {
        Size = UDim2.new(1, -4, 0, h or 48),
        BackgroundColor3 = Theme.card,
        BackgroundTransparency = 0.12,
        Text = text,
        TextColor3 = Theme.white,
        Font = CONFIG.FontRegular,
        TextSize = fs(11),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, Scroll)
    new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, f)
    corner(f, 9)
    stroke(f, Theme.accent, 1, 0.62)
    return f
end

local function button(text, fn)
    local b = new("TextButton", {
        Size = UDim2.new(1, -4, 0, 40),
        BackgroundColor3 = Theme.cardActive,
        Text = text,
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(12),
        AutoButtonColor = false,
        ZIndex = 4,
    }, Scroll)
    corner(b, 9)
    local st = stroke(b, Theme.accent, 1, 0.45)
    b.MouseEnter:Connect(function()
        tweenProp(b, {BackgroundColor3 = Theme.accentFill})
        tweenProp(st, {Transparency = 0.05})
    end)
    b.MouseLeave:Connect(function()
        tweenProp(b, {BackgroundColor3 = Theme.cardActive})
        tweenProp(st, {Transparency = 0.45})
    end)
    b.MouseButton1Click:Connect(fn)
    return b
end

local function toggle(title, desc, default, fn)
    S.flags[title] = default or false
    local f = new("Frame", {
        Size = UDim2.new(1, -4, 0, 68),
        BackgroundColor3 = Theme.card,
        BackgroundTransparency = 0.1,
        ZIndex = 4,
    }, Scroll)
    corner(f, 10)
    stroke(f, Theme.accent, 1, 0.55)
    new("TextLabel", {
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -100, 0, 22),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(12),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    }, f)
    new("TextLabel", {
        Position = UDim2.fromOffset(12, 32),
        Size = UDim2.new(1, -100, 0, 28),
        BackgroundTransparency = 1,
        Text = desc,
        TextColor3 = Theme.mutedWhite,
        Font = CONFIG.FontRegular,
        TextSize = fs(10),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    }, f)
    local sw = new("TextButton", {
        Position = UDim2.new(1, -78, 0.5, -14),
        Size = UDim2.fromOffset(64, 28),
        BackgroundColor3 = S.flags[title] and Theme.accentFill or Theme.switchOff,
        Text = S.flags[title] and "เปิด" or "ปิด",
        TextColor3 = Theme.white,
        Font = Enum.Font.GothamBlack,
        TextSize = fs(11),
        ZIndex = 5,
    }, f)
    corner(sw, 14)
    stroke(sw, Theme.accent, 1, 0.35)
    sw.MouseButton1Click:Connect(function()
        S.flags[title] = not S.flags[title]
        sw.Text = S.flags[title] and "เปิด" or "ปิด"
        tweenProp(sw, {BackgroundColor3 = S.flags[title] and Theme.accentFill or Theme.switchOff})
        if fn then fn(S.flags[title]) end
        toast(title .. " : " .. (S.flags[title] and "เปิดใช้งาน" or "ปิดใช้งาน"))
    end)
end

local function cardGrid(items)
    local wrap = new("Frame", {
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, Scroll)
    new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -5, 0, 118),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, wrap)
    for _, item in ipairs(items) do
        local f = new("Frame", {
            BackgroundColor3 = Theme.card,
            BackgroundTransparency = 0.08,
            ZIndex = 4,
        }, wrap)
        corner(f, 10)
        stroke(f, Theme.accent, 1.1, 0.45)
        gradient(f, Theme.cardActive, Theme.surface, 25)
        new("TextLabel", {
            Position = UDim2.fromOffset(10, 8),
            Size = UDim2.new(1, -20, 0, 24),
            BackgroundTransparency = 1,
            Text = item.icon .. "  " .. item.title,
            TextColor3 = Theme.white,
            Font = Enum.Font.GothamBlack,
            TextSize = fs(12),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        }, f)
        new("TextLabel", {
            Position = UDim2.fromOffset(10, 34),
            Size = UDim2.new(1, -20, 0, 44),
            BackgroundTransparency = 1,
            Text = item.desc,
            TextColor3 = Theme.mutedWhite,
            Font = CONFIG.FontRegular,
            TextSize = fs(10),
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        }, f)
        local b = new("TextButton", {
            Position = UDim2.new(1, -86, 1, -30),
            Size = UDim2.fromOffset(76, 22),
            BackgroundColor3 = Theme.cardActive,
            Text = "ตั้งค่า",
            TextColor3 = Theme.white,
            Font = Enum.Font.GothamBlack,
            TextSize = fs(10),
            ZIndex = 5,
        }, f)
        corner(b, 6)
        stroke(b, Theme.accent, 1, 0.3)
        b.MouseButton1Click:Connect(item.fn or function() toast(item.title .. " (โหมดเตรียมระบบออโต้)") end)
    end
end

--========================================================
-- Smart Vehicle & Thai Pin Destination Scanner
--========================================================
local function vehicles()
    local out, seen = {}, {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("VehicleSeat") then
            local m = v:FindFirstAncestorOfClass("Model")
            if m and not seen[m] then
                seen[m] = true
                table.insert(out, m)
            end
        end
    end
    table.sort(out, function(a, b) return a.Name < b.Name end)
    return out
end

local function isIgnoredPart(part)
    if not CONFIG.FilterInvalidParts then return false end
    local fullLower = part:GetFullName():lower()
    local nameLower = part.Name:lower()
    -- ข้ามชิ้นส่วนของตัวละครผู้เล่น เช่น KneeBrace ที่ไปตรงกับคำว่า race
    if part:FindFirstAncestorOfClass("Accessory") then return true end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and part:IsDescendantOf(plr.Character) then return true end
    end
    if fullLower:find("players%.") or fullLower:find("accessory") then return true end
    for _, kw in ipairs(IGNORED_PART_KEYWORDS) do
        if nameLower:find(kw, 1, true) then return true end
    end
    return false
end

local function translateDestination(rawName)
    local lower = rawName:lower()
    for _, rule in ipairs(PIN_RULES) do
        if lower:find(rule.keyword, 1, true) then
            if CONFIG.ShowRawNameHint then
                return rule.thai .. " (" .. rawName .. ")", rule.category
            end
            return rule.thai, rule.category
        end
    end
    if CONFIG.ShowRawNameHint then
        return "จุดหมายในแผนที่ (" .. rawName .. ")", "จุดหมาย"
    end
    return "จุดหมาย: " .. rawName, "จุดหมาย"
end

local function destinations()
    local out, seen = {}, {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not isIgnoredPart(v) then
            local n = v.Name:lower()
            local matched = false
            for _, rule in ipairs(PIN_RULES) do
                if n:find(rule.keyword, 1, true) then matched = true; break end
            end
            if matched and not seen[v] then
                seen[v] = true
                local thaiName, cat = translateDestination(v.Name)
                table.insert(out, {part = v, thai = thaiName, category = cat})
            end
        end
    end
    table.sort(out, function(a, b) return a.thai < b.thai end)
    return out
end

local function clearRoute()
    for _, v in ipairs(S.route) do pcall(function() v:Destroy() end) end
    table.clear(S.route)
end

local function routeTo(part, thaiLabel)
    clearRoute()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not part then toast("ไม่พบตัวละครหรือจุดหมาย"); return end
    local path = PathfindingService:CreatePath({AgentRadius = 4, AgentHeight = 6, AgentCanJump = true, WaypointSpacing = 12})
    local ok = pcall(function() path:ComputeAsync(root.Position, part.Position) end)
    local pts = {}
    if ok and path.Status == Enum.PathStatus.Success then
        for _, w in ipairs(path:GetWaypoints()) do table.insert(pts, w.Position) end
    else
        pts = {root.Position, part.Position}
    end
    for i = 1, #pts - 1 do
        local a, b = pts[i], pts[i + 1]
        local d = b - a
        local beam = new("Part", {
            Name = "BALLKUN_ROUTE",
            Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
            Material = Enum.Material.Neon, Color = Theme.accent, Transparency = 0.08,
            Size = Vector3.new(0.45, 0.45, d.Magnitude),
            CFrame = CFrame.lookAt((a + b) / 2, b),
        }, Workspace)
        table.insert(S.route, beam)
    end
    local pin = new("Part", {
        Name = "BALLKUN_PIN",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(2.2, 2.2, 2.2),
        Position = part.Position + Vector3.new(0, 3, 0),
        Anchored = true, CanCollide = false,
        Material = Enum.Material.Neon, Color = Theme.white,
    }, Workspace)
    table.insert(S.route, pin)
    S.selectedTarget = part
    toast("ปักหมุดเส้นทาง: " .. (thaiLabel or "จุดหมาย"))
end

--========================================================
-- Pages
--========================================================
local showPage

local function dashboard()
    section("COMMAND DASHBOARD  •  BALL KUN V6")
    info("ยินดีต้อนรับสู่ " .. CONFIG.HubTitle .. " — ศูนย์ควบคุมภายในเกม พร้อมเมนูสัมผัสสำหรับ Android", 48)
    cardGrid({
        {icon = "⛽", title = "ระบบน้ำมัน", desc = "หน้าตรวจสอบสถานะ — ยังไม่เชื่อมกลไกเติมน้ำมัน", fn = function() toast("ระบบน้ำมัน: โหมดเตรียมพร้อมออโต้") end},
        {icon = "🔧", title = "ระบบซ่อมรถ", desc = "หน้าตรวจสอบสถานะ — ยังไม่เชื่อมกลไกซ่อม", fn = function() toast("ระบบซ่อมรถ: โหมดเตรียมพร้อมออโต้") end},
        {icon = "📍", title = "ปักหมุดนำทางไทย", desc = "สแกนร้าน จุดจูน และสนามแข่งเป็นภาษาไทยทั้งหมด", fn = function() showPage("การนำทาง") end},
        {icon = "🎨", title = "ปรับแต่ง UI ทั้งหมด", desc = "เปลี่ยนสี ขนาดหน้าต่าง ความโปร่งใส และพื้นหลังได้ทันที", fn = function() showPage("ปรับแต่ง UI") end},
    })
    section("ระบบจูนรถและผู้เล่น")
    button("🚘  เลือกรถเป้าหมายสำหรับจูน", function() showPage("ระบบรถยนต์") end)
    button("⚙  เปิดห้องทดลอง ECU (เตรียมออโต้)", function() showPage("ECU Tuning") end)
    local c = LP.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    info("ผู้เล่น: " .. LP.DisplayName .. " (@" .. LP.Name .. ")  •  พลังชีวิต: " .. (h and math.floor(h.Health) or 0) .. "/" .. (h and math.floor(h.MaxHealth) or 0), 44)
end

local function carPage()
    section("ระบบรถยนต์  •  เลือกคันเป้าหมาย")
    info("สแกนรถที่มี VehicleSeat ใน Workspace แล้วเลือกคันที่ต้องการวิเคราะห์", 44)
    button("🔍  สแกนรถทั้งหมดในแผนที่", function()
        local list = vehicles()
        toast("พบรถทั้งหมด " .. #list .. " คัน")
        for _, car in ipairs(list) do
            button("เลือกรถ  •  " .. car.Name, function()
                S.selectedCar = car
                toast("เลือกรถ " .. car.Name .. " เรียบร้อย")
            end)
        end
    end)
    button("แสดงข้อมูลรถที่เลือกไว้", function()
        toast(S.selectedCar and ("รถที่เลือก: " .. S.selectedCar.Name) or "ยังไม่ได้เลือกรถ")
    end)
end

local function navPage()
    section("การนำทาง  •  ปักหมุดภาษาไทยอัจฉริยะ")
    info("กรองชิ้นส่วนตัวละครออกอัตโนมัติ (เช่น KneeBrace) และแปลชื่อจุดหมายในแผนที่เป็นภาษาไทยทั้งหมด", 50)
    button("🔍  สแกนร้าน / อู่ / สนามแข่ง (แปลไทย)", function()
        local list = destinations()
        toast("พบจุดหมายที่ใช้งานได้ " .. #list .. " จุด")
        for _, item in ipairs(list) do
            button("ปักหมุด  •  " .. item.thai .. "  [" .. item.category .. "]", function()
                routeTo(item.part, item.thai)
            end)
        end
    end)
    button("ล้างเส้นทางและหมุดทั้งหมด", function()
        clearRoute()
        toast("ล้างเส้นทางแล้ว")
    end)
    toggle("อัปเดตเส้นทางตามตำแหน่ง", "คำนวณเส้นทางใหม่อัตโนมัติทุก 3 วินาที", false, function(on)
        if on then
            task.spawn(function()
                while S.alive and S.flags["อัปเดตเส้นทางตามตำแหน่ง"] do
                    task.wait(3)
                    if S.selectedTarget and S.selectedTarget.Parent then
                        local thaiName = translateDestination(S.selectedTarget.Name)
                        routeTo(S.selectedTarget, thaiName)
                    end
                end
            end)
        end
    end)
end

local function ecuPage()
    section("ห้องทดลอง ECU  •  เตรียมระบบออโต้")
    info("อ่านค่าความเร็ว/แรงบิดของรถที่เลือกไว้ ส่วนระบบจูนออโต้จะเพิ่มในรอบถัดไปเพื่อความปลอดภัย", 50)
    button("สแกนค่ารถที่เลือก", function()
        local v = S.selectedCar
        if not v then toast("กรุณาเลือกรถในเมนู ระบบรถยนต์ ก่อน"); return end
        local seat = v:FindFirstChildWhichIsA("VehicleSeat", true)
        info("รถ: " .. v.Name .. "\nความเร็วสูงสุด: " .. tostring(seat and seat.MaxSpeed or "ไม่พบ") ..
            "  |  แรงบิด: " .. tostring(seat and seat.Torque or "ไม่พบ"), 54)
    end)
    toggle("ผู้ช่วยวิเคราะห์ ECU", "เปรียบเทียบค่าที่อ่านได้ (โหมดตรวจสอบ)", false)
    toggle("ค้นหาค่าจูนอัตโนมัติ (รอรอบถัดไป)", "เตรียมระบบออโต้ไว้สำหรับเชื่อมต่อรอบหน้า", false)
    toggle("จูนรถทุกคันทีละคัน (รอรอบถัดไป)", "เตรียมคิวรถไว้พร้อมสำหรับระบบออโต้", false)
end

local function pistonPage()
    section("เรดาร์ลูกสูบ  •  เบอร์ 53–90")
    info("กำหนดเบอร์ลูกสูบที่ต้องการ ระบบจะคอยตรวจจับบนหน้าจอ (ระบบซื้อออโต้จะเพิ่มทีหลัง)", 46)
    local box = new("TextBox", {
        Size = UDim2.new(1, -4, 0, 40),
        BackgroundColor3 = Theme.cardActive,
        Text = tostring(S.piston),
        PlaceholderText = "ใส่เบอร์ลูกสูบ 53–90",
        PlaceholderColor3 = Theme.mutedWhite,
        TextColor3 = Theme.white,
        Font = Enum.Font.GothamBold,
        TextSize = fs(14),
        ClearTextOnFocus = false,
        ZIndex = 5,
    }, Scroll)
    corner(box, 9)
    stroke(box, Theme.accent, 1, 0.35)
    button("บันทึกเบอร์ลูกสูบเป้าหมาย", function()
        local n = tonumber(box.Text)
        if n and n % 1 == 0 and n >= 53 and n <= 90 then
            S.piston = n
            toast("ตั้งเป้าลูกสูบเบอร์ " .. n .. " เรียบร้อย")
        else
            toast("กรุณาใส่เลขจำนวนเต็ม 53–90 เท่านั้น")
        end
    end)
    section("PRODUCT DATABASE  •  38 SIZES")
    info("แสดงครบเบอร์ 53–90 ข้อมูลราคาและสต็อกจะเป็น UNKNOWN จนกว่าจะอ่านได้จากข้อมูลจริงของเกม", 44)
    local pistonGrid = new("Frame", {
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, Scroll)
    new("UIGridLayout", {
        CellSize = UDim2.new(1/3, -6, 0, 46),
        CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, pistonGrid)
    for size = 53, 90 do
        local cell = new("TextLabel", {
            BackgroundColor3 = Theme.card,
            Text = tostring(size) .. "\nUNKNOWN",
            TextColor3 = Theme.white,
            Font = Enum.Font.GothamBold,
            TextSize = fs(10),
            TextWrapped = true,
            ZIndex = 4,
        }, pistonGrid)
        corner(cell, 7)
        stroke(cell, Theme.accent, 1, 0.65)
    end
    toggle("ตรวจจับลูกสูบเป้าหมาย", "แจ้งเตือนทันทีเมื่อพบข้อความลูกสูบตรงเบอร์", false)
    toggle("ซื้อลูกสูบอัตโนมัติ (เพิ่มทีหลัง)", "โหมดเตรียมพร้อม รอเพิ่มระบบออโต้ในรอบถัดไป", false)
end

local function fpsPage()
    section("เพิ่มความลื่นไหล  •  FPS BOOST")
    info("ลดเงา หมอก และเอฟเฟกต์แสงเพื่อเพิ่ม FPS และสามารถกดคืนค่าเดิมได้ทุกเมื่อ", 48)
    toggle("เปิดใช้งาน FPS Boost", "ลดภาระกราฟิกฝั่งเครื่องผู้เล่น", false, function(on)
        if on and not S.fps then
            S.fps = true
            S.saved.shadows = Lighting.GlobalShadows
            S.saved.fog = Lighting.FogEnd
            S.saved.effects = {}
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1000000
            for _, v in ipairs(Lighting:GetDescendants()) do
                if v:IsA("PostEffect") then S.saved.effects[v] = v.Enabled; v.Enabled = false end
            end
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                    S.saved.effects[v] = v.Enabled; v.Enabled = false
                end
            end
            toast("เปิด FPS Boost แล้ว")
        elseif not on and S.fps then
            S.fps = false
            Lighting.GlobalShadows = S.saved.shadows
            Lighting.FogEnd = S.saved.fog
            for obj, val in pairs(S.saved.effects or {}) do
                if obj and obj.Parent then pcall(function() obj.Enabled = val end) end
            end
            toast("คืนค่ากราฟิกเดิมแล้ว")
        end
    end)
end

local function alertsPage()
    section("ศูนย์รวมแจ้งเตือน")
    info("จัดการการแจ้งเตือนแบบเรียลไทม์ทั้งหมดของ BALL KUN MAHANAKHON", 40)
    toggle("แจ้งเตือนลูกสูบ", "แจ้งเตือนเมื่อตรวจพบเบอร์ลูกสูบเป้าหมาย", false)
    toggle("แจ้งเตือนจุดหมายใหม่", "ตรวจจับการเปลี่ยนแปลงของร้านและอู่ในแผนที่", false)
end

local function playerPage()
    section("โปรไฟล์ผู้เล่น")
    local avatar = new("ImageLabel", {
        Size = UDim2.fromOffset(88, 88),
        BackgroundColor3 = Theme.cardActive,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150",
        ZIndex = 4,
    }, Scroll)
    corner(avatar, 44)
    stroke(avatar, Theme.accent, 2, 0.15)
    info("ชื่อแสดง: " .. LP.DisplayName .. "\nบัญชี: @" .. LP.Name .. "\nUser ID: " .. LP.UserId .. "\nอายุบัญชี: " .. LP.AccountAge .. " วัน", 76)
end

local function customizePage()
    section("ปรับแต่ง UI ได้ทั้งหมด (เรียลไทม์)")
    info("ปรับสีธีม พื้นหลัง ความโปร่งใส ขนาดหน้าต่าง และตัวกรองปักหมุดได้ทันทีในเกม", 46)

    button("🎨  เปลี่ยนสีหลัก: มรกตพรีเมียม", function()
        Theme.accent = Color3.fromRGB(16, 185, 129); applyLayoutRefresh(); toast("เปลี่ยนธีมเป็น มรกตพรีเมียม")
    end)
    button("🏆  เปลี่ยนสีหลัก: ทองแชมเปี้ยน", function()
        Theme.accent = Color3.fromRGB(245, 158, 11); applyLayoutRefresh(); toast("เปลี่ยนธีมเป็น ทองแชมเปี้ยน")
    end)
    button("💠  เปลี่ยนสีหลัก: ฟ้าคริสตัล", function()
        Theme.accent = Color3.fromRGB(6, 182, 212); applyLayoutRefresh(); toast("เปลี่ยนธีมเป็น ฟ้าคริสตัล")
    end)
    button("🖼  สลับแสดง / ซ่อนภาพพื้นหลัง", function()
        CONFIG.BackgroundEnabled = not CONFIG.BackgroundEnabled
        applyLayoutRefresh()
        toast(CONFIG.BackgroundEnabled and "แสดงภาพพื้นหลังแล้ว" or "ซ่อนภาพพื้นหลังแล้ว")
    end)
    button("📐  ปรับขนาดหน้าต่าง: โหมดมือถือ / แท็บเล็ต", function()
        CONFIG.WindowWidth = 780; CONFIG.WindowHeight = 500; CONFIG.ShowRightPanel = false
        applyLayoutRefresh(); toast("ปรับเป็นขนาดมือถือแล้ว")
    end)
    button("🖥  ปรับขนาดหน้าต่าง: โหมดเต็มจอพรีเมียม", function()
        CONFIG.WindowWidth = 980; CONFIG.WindowHeight = 620; CONFIG.ShowRightPanel = true
        applyLayoutRefresh(); toast("ปรับเป็นขนาดเต็มจอแล้ว")
    end)
    toggle("ซ่อนแถบสถานะด้านขวา", "เพิ่มพื้นที่แสดงผลตรงกลางให้กว้างขึ้น", not CONFIG.ShowRightPanel, function(on)
        CONFIG.ShowRightPanel = not on
        applyLayoutRefresh()
    end)
    toggle("กรองชิ้นส่วนหลอก (เช่น KneeBrace)", "เปิดไว้เพื่อไม่ให้คำว่า race ในชื่อไอเทมโผล่ในรายการปักหมุด", CONFIG.FilterInvalidParts, function(on)
        CONFIG.FilterInvalidParts = on
    end)
    button("ล้างเส้นทางทั้งหมด", clearRoute)
    button("ปิด BALL KUN MAHANAKHON", function() S.alive = false; clearRoute(); Gui:Destroy() end)
end


-- ===================== AUTO FARM COMMAND CENTER =====================
local FARM_MODULES = {
    { id = "quest", title = "Quest — ภารกิจรายวันและรายสัปดาห์", start = "QUEST_START", stop = "QUEST_STOP", enabled = true, delay = 2, cmds = { "OPEN_PHONE", "OPEN_QUEST_APP", "SELECT_DAILY", "READ_ALL_QUESTS", "READ_PROGRESS", "SORT_BY_EASIEST", "SELECT_TARGET_QUEST", "EXECUTE_REQUIRED_ACTIVITY", "CHECK_PROGRESS", "IF_COMPLETED_CLAIM_REWARD", "VERIFY_REWARD", "SELECT_WEEKLY", "REPEAT" } },
    { id = "delivery", title = "Delivery — ไรเดอร์ส่งอาหาร", start = "DELIVERY_START", stop = "DELIVERY_STOP", enabled = true, delay = 1.5, cmds = { "CHECK_PLAYER", "OPEN_JOBS_APP", "SELECT_DELIVERY", "GO_TO_RIDER_LOCKER", "PRESS_INTERACT", "WEAR_UNIFORM", "GET_MOTORCYCLE", "OPEN_DELIVERY_APP", "START_DELIVERY", "CHECK_ORDER", "ACCEPT_ORDER", "NAVIGATE_TO_PICKUP", "ARRIVE_CHECK", "PICKUP_FOOD", "NAVIGATE_TO_CUSTOMER", "ARRIVE_CHECK", "CONFIRM_DELIVERY", "VERIFY_PAYMENT", "UPDATE_STATISTICS", "REPEAT" } },
    { id = "courier", title = "Courier — ส่งพัสดุ", start = "COURIER_START", stop = "COURIER_STOP", enabled = true, delay = 1.5, cmds = { "SELECT_COURIER", "GO_TO_DELIVERY_OFFICE", "WEAR_UNIFORM", "GET_BIKE", "OPEN_PHONE", "TAKE_PARCEL_ORDER", "CHECK_DESTINATION", "NAVIGATE_TO_HOME", "ARRIVE_CHECK", "COMPLETE_PARCEL_DELIVERY", "VERIFY_TASK", "REPEAT" } },
    { id = "builder", title = "Builder — ช่างก่อสร้าง", start = "BUILDER_START", stop = "BUILDER_STOP", enabled = true, delay = 1.2, cmds = { "SELECT_BUILDER", "GO_TO_BUILDER_LOCKER", "WEAR_UNIFORM", "GO_TO_CONSTRUCTION_SITE", "OPEN_WORK_BOARD", "TAKE_RANDOM_JOB", "READ_TASK", "SELECT_TASK_HANDLER", "VERIFY_COMPLETION", "VERIFY_PAYMENT", "REPEAT" } },
    { id = "mechanic", title = "Mechanic — ช่างซ่อมรถ", start = "MECHANIC_START", stop = "MECHANIC_STOP", enabled = true, delay = 1.2, cmds = { "SELECT_MECHANIC", "GO_TO_MECHANIC_LOCKER", "WEAR_UNIFORM", "GO_TO_AUTO_SERVICE", "CHECK_WORK_BOARD", "TAKE_RANDOM_JOB", "READ_VEHICLE_TASK", "FIND_REQUIRED_BAY", "PERFORM_REPAIR", "VERIFY_REPAIR", "VERIFY_PAYMENT", "REPEAT" } },
    { id = "racing", title = "Racing — แข่งขันรถ Drag", start = "RACING_START", stop = "RACING_STOP", enabled = false, delay = 3, cmds = { "CHECK_COOLDOWN_3MIN", "GO_TO_RACING_LOBBY", "ENTER_RACING_AREA", "OPEN_RACE_MENU", "CHECK_AVAILABLE_RACE", "SELECT_RACE", "JOIN_RACE", "CHECK_RACERS", "READY", "WAIT_FOR_COUNTDOWN", "START_RACE", "CONTROL_VEHICLE", "DETECT_FINISH_LINE", "READ_RESULT", "UPDATE_STATISTICS" } },
    { id = "carwash", title = "Car Wash — ตู้ล้างรถและพนักงาน", start = "CARWASH_START", stop = "CARWASH_STOP", enabled = false, delay = 2, cmds = { "CHECK_VEHICLE", "GO_TO_CARWASH_MACHINE", "DETECT_CARWASH_PROMPT", "CHECK_REQUIRED_PAYMENT", "INTERACT_WITH_MACHINE", "DETECT_CARWASH_UI", "SELECT_AVAILABLE_OPTION", "START_WASH", "WAIT_FOR_COMPLETION", "VERIFY_VEHICLE_STATUS" } },
    { id = "cargo", title = "Cargo — ยกมอเตอร์ไซค์ขึ้นกระบะ", start = "CARGO_START", stop = "CARGO_STOP", enabled = false, delay = 2, cmds = { "CHECK_PICKUP_TRUCK", "ENTER_TRUCK", "OPEN_CARGO_MENU", "DETECT_AVAILABLE_MOTORCYCLES", "SELECT_MOTORCYCLE", "LOAD_ONTO_BED", "SELECT_MOVE_TOOL", "ADJUST_CARGO_POSITION", "VERIFY_CARGO_WELD", "CLOSE_CARGO_MENU", "VERIFY_VEHICLE_LOADED" } },
    { id = "group_reward", title = "Group Reward — รางวัลเข้ากลุ่ม", start = "GROUP_REWARD_START", stop = "GROUP_REWARD_STOP", enabled = true, delay = 2, cmds = { "GO_TO_GROUP_REWARD_GATE", "DETECT_GROUP_REQUIREMENT", "CHECK_MEMBERSHIP_STATUS", "IF_ELIGIBLE_INTERACT_WITH_GATE", "VERIFY_REWARD", "ELSE_SHOW_REQUIREMENT" } },
    { id = "vehicle_care", title = "Vehicle Care — ดูแลรถระหว่างฟาร์ม", start = "VEHICLE_CARE_START", stop = "VEHICLE_CARE_STOP", enabled = true, delay = 2, cmds = { "CHECK_FUEL", "CHECK_ENGINE_HEALTH", "CHECK_DAMAGE", "IF_LOW_FUEL_FIND_STATION", "REFUEL", "IF_DAMAGED_FIND_REPAIR", "REPAIR_VEHICLE", "VERIFY_VEHICLE_STATUS" } },
}

local Farm = {
    status = "IDLE", active = nil, cmd = "IDLE", run = 0,
    paused = false, retries = 0, maxRetries = 3,
    monitored = 0, prepared = 0, tasks = 0,
    stuckWatch = true, stuckSec = 20,
    log = {}, statusLabel = nil, logLabel = nil,
}

-- เฉพาะขั้นตอนที่ฝั่งไคลเอนต์ตรวจจริงได้ (MONITOR) ที่เหลือคือ PREPARATION
local MONITOR_PROBES = {
    CHECK_PLAYER = function()
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        return h ~= nil and h.Health > 0, "ผู้เล่นพร้อม"
    end,
    CHECK_GAME_STATUS = function()
        return game:IsLoaded() and LP.Character ~= nil, "เกมโหลดแล้ว"
    end,
    CHECK_CHARACTER_MOVEMENT = function()
        local c = LP.Character
        return c ~= nil and c:FindFirstChild("HumanoidRootPart") ~= nil, "อ่านตำแหน่งตัวละครได้"
    end,
}

local function farmRefresh()
    if Farm.statusLabel and Farm.statusLabel.Parent then
        Farm.statusLabel.Text = string.format(
            "สถานะ: %s%s\nโมดูลที่ทำงาน: %s\nคำสั่งล่าสุด: %s\nตรวจจริง (MONITOR): %d  |  ยังไม่เชื่อมเกม (PREPARATION): %d\nงานที่ยืนยันสำเร็จจริง: %d  |  Retry: %d/%d",
            Farm.status, Farm.paused and " (พัก)" or "", Farm.active or "-", Farm.cmd,
            Farm.monitored, Farm.prepared, Farm.tasks, Farm.retries, Farm.maxRetries)
    end
    if Farm.logLabel and Farm.logLabel.Parent then
        local lines = {}
        for i = 1, math.min(8, #Farm.log) do
            local e = Farm.log[i]
            lines[#lines + 1] = string.format("[%s] %s %s — %s", e.t, e.level, e.cmd, e.msg)
        end
        Farm.logLabel.Text = #lines > 0 and table.concat(lines, "\n") or "ยังไม่มีบันทึก"
    end
end

local function farmLog(level, cmd, msg)
    table.insert(Farm.log, 1, { t = os.date("%H:%M:%S"), level = level, cmd = cmd, msg = msg })
    while #Farm.log > 60 do table.remove(Farm.log) end
    farmRefresh()
end

local function farmStop(reason, emergency)
    Farm.run = Farm.run + 1 -- ยกเลิกลูปที่กำลังรันอยู่
    Farm.status = emergency and "EMERGENCY_STOP" or "IDLE"
    Farm.paused = false
    Farm.active = nil
    Farm.cmd = emergency and "EMERGENCY_STOP" or "STOP_ALL"
    if emergency then pcall(clearRoute) end
    farmLog(emergency and "ERROR" or "INFO", Farm.cmd, reason)
end

S.stopAll = function()
    farmStop("ผู้ใช้สั่ง STOP ALL จากแถบด้านบน", false)
    for key in pairs(S.flags) do S.flags[key] = false end
    if S.fps then
        S.fps = false
        pcall(function()
            Lighting.GlobalShadows = S.saved.shadows
            Lighting.FogEnd = S.saved.fog
            for obj, val in pairs(S.saved.effects or {}) do
                if obj and obj.Parent then obj.Enabled = val end
            end
        end)
    end
    clearRoute()
    toast("STOP ALL: หยุดคิวฟาร์ม ปิดตัวเฝ้าดู และล้างเส้นทางแล้ว")
end

local function farmWaitStep(runId, seconds)
    local t = 0
    while t < seconds do
        if Farm.run ~= runId then return false end
        task.wait(0.1)
        if not Farm.paused then t = t + 0.1 end
    end
    return Farm.run == runId
end

local function farmStart()
    if Farm.status == "RUNNING" then toast("Auto Farm กำลังทำงานอยู่") return end
    local queue = {}
    for _, m in ipairs(FARM_MODULES) do if m.enabled then queue[#queue + 1] = m end end
    if #queue == 0 then toast("ยังไม่ได้เปิดโมดูลใด") return end
    Farm.run = Farm.run + 1
    local runId = Farm.run
    Farm.status = "RUNNING"; Farm.paused = false; Farm.retries = 0
    Farm.monitored = 0; Farm.prepared = 0
    farmLog("INFO", "START_ALL", "เริ่ม Main Controller (" .. #queue .. " โมดูล, ทำทีละโมดูล)")
    task.spawn(function()
        for _, m in ipairs(queue) do
            if Farm.run ~= runId then return end
            Farm.active = m.id
            farmLog("INFO", m.start, m.title)
            for _, cmd in ipairs(m.cmds) do
                if Farm.run ~= runId then return end
                while Farm.paused and Farm.run == runId do task.wait(0.2) end
                Farm.cmd = cmd
                local probe = MONITOR_PROBES[cmd]
                if probe then
                    local ok, okVal, note = pcall(probe)
                    if ok and okVal then
                        Farm.monitored = Farm.monitored + 1
                        farmLog("INFO", cmd, "MONITOR: " .. tostring(note))
                    else
                        Farm.retries = Farm.retries + 1
                        farmLog("WARN", cmd, "ตรวจไม่ผ่าน (retry " .. Farm.retries .. "/" .. Farm.maxRetries .. ")")
                        if Farm.retries >= Farm.maxRetries then
                            farmStop("ตรวจไม่ผ่านเกินจำนวนที่กำหนด หยุดเพื่อความปลอดภัย", true)
                            return
                        end
                    end
                else
                    Farm.prepared = Farm.prepared + 1
                    farmLog("INFO", cmd, "PREPARATION: ยังไม่เชื่อมระบบเกม (ไม่นับว่าสำเร็จ)")
                end
                if not farmWaitStep(runId, 0.25) then return end
            end
            farmLog("INFO", m.stop, "จบลำดับคำสั่ง — ยังไม่ยืนยันผลงาน/เงินจากเกมจริง")
            if not farmWaitStep(runId, m.delay) then return end
        end
        if Farm.run == runId then
            Farm.status = "IDLE"; Farm.active = nil; Farm.cmd = "IDLE"
            farmLog("INFO", "STATISTICS", "จบรอบ: MONITOR " .. Farm.monitored .. " / PREPARATION " .. Farm.prepared)
        end
    end)
end

-- Stuck Detector (MONITOR): เฝ้าดูเฉพาะตอนมีเส้นทางนำทางอยู่
task.spawn(function()
    local lastPos, lastMove = nil, os.clock()
    while S.alive do
        task.wait(1)
        local c = LP.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local routing = S.route and #S.route > 0
        if hrp and Farm.stuckWatch and routing and Farm.status ~= "PAUSED" then
            if lastPos == nil or (hrp.Position - lastPos).Magnitude > 2 then
                lastPos = hrp.Position; lastMove = os.clock()
            elseif os.clock() - lastMove > Farm.stuckSec then
                lastMove = os.clock()
                farmLog("WARN", "STUCK_DETECTOR", "ตัวละคร/รถหยุดนิ่งเกิน " .. Farm.stuckSec .. " วินาทีขณะนำทาง")
                toast("แจ้งเตือน: รถหยุดนิ่งขณะนำทาง")
            end
        else
            lastPos = nil; lastMove = os.clock()
        end
    end
end)

local function farmPage()
    section("AUTO FARM COMMAND CENTER")
    info("ตัวควบคุมหลักสั่งทีละโมดูล ไม่ให้แย่งกัน\nขั้นตอนที่ตรวจจริงได้ = MONITOR  |  ที่ยังไม่เชื่อมเกม = PREPARATION (ไม่แสดง SUCCESS ปลอม)", 62)
    Farm.statusLabel = info("", 112)
    button("▶  START_ALL — เริ่มทุกโมดูลที่เปิด", farmStart)
    button("⏸  PAUSE / RESUME — พักหรือทำต่อ", function()
        if Farm.status ~= "RUNNING" then toast("ยังไม่ได้เริ่มทำงาน") return end
        Farm.paused = not Farm.paused
        farmLog("INFO", Farm.paused and "PAUSE" or "RESUME", Farm.paused and "พักการทำงาน" or "ทำงานต่อ")
    end)
    button("⏹  STOP_ALL — หยุดทั้งหมด", function() farmStop("ผู้ใช้สั่งหยุด", false) end)
    button("🛑  EMERGENCY STOP — หยุดฉุกเฉิน", function() farmStop("ผู้ใช้สั่งหยุดฉุกเฉิน", true) end)
    section("เลือกโมดูล (ทำทีละอย่างตามลำดับ)")
    for _, m in ipairs(FARM_MODULES) do
        toggle(m.title, m.start .. "  •  " .. #m.cmds .. " ขั้นตอน  •  PREPARATION", m.enabled, function(on) m.enabled = on end)
    end
    toggle("Stuck Detector", "แจ้งเตือนเมื่อหยุดนิ่งขณะนำทาง (MONITOR)", Farm.stuckWatch, function(on) Farm.stuckWatch = on end)
    section("บันทึกการทำงาน (Log)")
    Farm.logLabel = info("", 170)
    farmRefresh()
end


local function aiCorePage()
    section("AI AUTO CORE  •  CENTRAL CONTROL")
    info("ศูนย์ควบคุมสถานะโมดูลและคำสั่งหยุดทั้งหมด ขณะนี้ระบบที่ยังไม่เชื่อม API ที่เกมอนุญาตจะแสดงเป็น PREPARATION ไม่ทำงานแทนเกม", 64)
    info("CORE STATUS: " .. (S.alive and "ONLINE" or "OFFLINE") ..
        "\nAUTO FARM: " .. tostring(Farm.status) ..
        "\nROUTE: " .. ((S.selectedTarget and S.selectedTarget.Parent) and "TARGET SELECTED" or "NO TARGET") ..
        "\nPISTON TARGET: " .. tostring(S.piston) ..
        "\nFPS BOOST: " .. (S.fps and "ON" or "OFF"), 100)
    button("เปิดหน้า AUTO FARM", function() showPage("Auto Farm") end)
    button("เปิดหน้า PISTON SHOP 53–90", function() showPage("ลูกสูบ 53–90") end)
    button("เปิดหน้า SMART NAVIGATION", function() showPage("การนำทาง") end)
    button("STOP ALL  •  หยุดระบบที่กำลังทำงาน", function() if S.stopAll then S.stopAll() end end)
    button("EMERGENCY STOP  •  หยุดคิวและล้างเส้นทาง", function()
        farmStop("EMERGENCY STOP จาก AI CORE", true)
        for key in pairs(S.flags) do S.flags[key] = false end
        clearRoute()
        toast("EMERGENCY STOP ทำงานแล้ว")
    end)
end

local pages = {
    ["AI CORE"] = aiCorePage,
    ["หน้าหลัก"] = dashboard,
    ["Auto Farm"] = farmPage,
    ["ระบบรถยนต์"] = carPage,
    ["การนำทาง"] = navPage,
    ["ECU Tuning"] = ecuPage,
    ["ลูกสูบ 53–90"] = pistonPage,
    ["FPS Boost"] = fpsPage,
    ["แจ้งเตือน"] = alertsPage,
    ["โปรไฟล์ผู้เล่น"] = playerPage,
    ["ปรับแต่ง UI"] = customizePage,
}

local navItems = {
    {"✦", "AI CORE", "ศูนย์ควบคุมหลัก"},
    {"⌂", "หน้าหลัก", "ภาพรวมระบบ"},
    {"🤖", "Auto Farm", "ศูนย์สั่งงานอัตโนมัติ"},
    {"🚘", "ระบบรถยนต์", "เลือกและวิเคราะห์รถ"},
    {"📍", "การนำทาง", "ปักหมุดแปลภาษาไทย"},
    {"⚙", "ECU Tuning", "เตรียมจูนอัตโนมัติ"},
    {"◎", "ลูกสูบ 53–90", "เรดาร์ลูกสูบ"},
    {"⚡", "FPS Boost", "เพิ่มความลื่นไหล"},
    {"🔔", "แจ้งเตือน", "ศูนย์รวมแจ้งเตือน"},
    {"●", "โปรไฟล์ผู้เล่น", "ข้อมูลบัญชี"},
    {"🎨", "ปรับแต่ง UI", "ปรับขนาด สี พื้นหลัง"},
}

showPage = function(name)
    S.page = name
    clearBody()
    if pages[name] then pages[name]() end
    for _, v in ipairs(Sidebar:GetChildren()) do
        if v:IsA("TextButton") then
            local active = (v.Name == name)
            tweenProp(v, {BackgroundColor3 = active and Theme.accentFill or Theme.card})
        end
    end
end

for i, item in ipairs(navItems) do
    local b = new("TextButton", {
        Name = item[2],
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.card,
        Text = item[1] .. "  " .. item[2] .. "\n      " .. item[3],
        TextColor3 = Theme.white,
        Font = CONFIG.FontBold,
        TextSize = fs(11),
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = i,
        ZIndex = 4,
    }, Sidebar)
    new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, b)
    b:SetAttribute("DesktopText", b.Text)
    corner(b, 8)
    stroke(b, Theme.accent, 1, 0.65)
    b.MouseButton1Click:Connect(function() showPage(item[2]) end)
end

-- Right Cards (All White Text)
local function sideCard(title, lines, height)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Theme.surface,
        BackgroundTransparency = 0.14,
        ZIndex = 3,
    }, Right)
    corner(f, 10)
    stroke(f, Theme.accent, 1.1, 0.35)
    gradient(f, Theme.card, Theme.surface, 30)
    new("TextLabel", {
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.new(1, -20, 0, 22),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.white,
        Font = Enum.Font.GothamBlack,
        TextSize = fs(13),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, f)
    new("TextLabel", {
        Position = UDim2.fromOffset(10, 34),
        Size = UDim2.new(1, -20, 1, -40),
        BackgroundTransparency = 1,
        Text = lines,
        TextColor3 = Theme.mutedWhite,
        Font = CONFIG.FontRegular,
        TextSize = fs(10),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, f)
    return f
end

sideCard("♛  BALL KUN V6", "✓ Premium Black Emerald\n✓ Mobile Touch Layout\n✓ Thai Smart Navigation\n✓ Central STOP ALL", 148)
sideCard("✦  สถานะระบบ", "● UI พรีเมียมพร้อมใช้\n● ระบบออโต้: เตรียมรอ\n● ไม่ยิง Remote อันตราย\n● รองรับมือถือพอดีจอ", 132)
sideCard("ผู้เล่นออนไลน์", "ชื่อ: " .. LP.DisplayName .. "\nสถานะ: ออนไลน์\nเครดิต: " .. CONFIG.Credit, 106)

-- Drag & Resize
local dragging, dragStart, startPos
Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

Grip = new("TextButton", {
    Size = UDim2.fromOffset(22, 22),
    Position = UDim2.new(1, -24, 1, -24),
    BackgroundColor3 = Theme.cardActive,
    Text = "◢",
    TextColor3 = Theme.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 12,
    ZIndex = 10,
}, Main)
corner(Grip, 6)
stroke(Grip, Theme.accent, 1, 0.3)

local resizing, rs, sz
Grip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true; rs = input.Position; sz = Main.Size
    end
end)
UIS.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - rs
        CONFIG.WindowWidth = math.clamp(sz.X.Offset + d.X, 680, 1250)
        CONFIG.WindowHeight = math.clamp(sz.Y.Offset + d.Y, 440, 860)
        applyLayoutRefresh()
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
end)

-- Piston Text Watcher (Safe Monitor Only)
task.spawn(function()
    while S.alive and Gui.Parent do
        task.wait(1.2)
        if S.flags["ตรวจจับลูกสูบเป้าหมาย"] or S.flags["แจ้งเตือนลูกสูบ"] then
            for _, o in ipairs(LP:WaitForChild("PlayerGui"):GetDescendants()) do
                if o:IsA("TextLabel") or o:IsA("TextButton") then
                    local txt = (o.Text or ""):lower()
                    if txt:find("ลูกสูบ") and txt:find(tostring(S.piston), 1, true) then
                        local key = o:GetFullName() .. txt
                        if key ~= S.lastPiston then
                            S.lastPiston = key
                            toast("พบข้อความลูกสูบเป้าหมายเบอร์ " .. S.piston)
                        end
                    end
                end
            end
        end
    end
end)

applyLayoutRefresh()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if S.alive and Gui.Parent then applyLayoutRefresh() end
    end)
end

showPage("AI CORE")
toast(CONFIG.HubTitle .. " V6 โหลดสำเร็จ • In-Game UI")
