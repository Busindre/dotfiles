-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
-- Vicious
local vicious = require("vicious")


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/patate-theme/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "terminator"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper

--if beautiful.wallpaper then
--    for s = 1, screen.count() do
--        gears.wallpaper.centered(beautiful.wallpaper, s, "black")
--    end
--end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, ')', '+', '<-',}, s,
        { layouts[6], layouts[2], layouts[6], layouts[6], layouts[6], layouts[4], layouts[4], layouts[4], layouts[4], layouts[6], layouts[6], layouts[6], layouts[6],})
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "Manual", terminal .. " -e 'man awesome'" },
   { "Edit config", editor_cmd .. " " .. awesome.conffile },
   { "Restart", awesome.restart },
   { "Quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "Awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Open terminal", terminal },
                                    { "Reboot", terminal .. " -e 'sudo reboot'" },
                                    { "Shutdown", terminal .. " -e 'systemctl poweroff'" },
                                    { "Sleep", terminal .. " -e 'systemctl suspend'" },
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox

-- Create a textclock widget
mytextclock = awful.widget.textclock(" %a %d %b %H:%M ", 10)

separator = wibox.widget.textbox('|')

-- Battery Widget
batwidget = wibox.widget.textbox()
vicious.register(batwidget, vicious.widgets.bat,
    function (widget, args)
        r = ' BAT: '

        if args[3] == 'N/A' then
            r = r .. '<span color="#00ff00">↯</span>'
        elseif args[1] == '+' then
            r = r .. '<span color="#00ff00">+</span>'
        else
            r = r .. '<span color="red">-</span>'
        end

        r = r .. ' '

	    if args[2] < 15 then
		    r = r .. '<span color="red">' .. args[2] .. '</span>'
	    elseif	args[2] < 25 then
		    r = r .. '<span color="orange">' .. args[2] .. '</span>'
	    elseif  args[2] < 35 then
		    r = r .. '<span color="yellow">' .. args[2] .. '</span>'
	    else
		    r = r .. '<span color="#00ff00">' .. args[2] .. '</span>'
	    end

        r = r .. '% '
        if args[3] ~= 'N/A' then
            r = r .. '(' .. args[3] .. ') '
        end

        -- notification if need to load
        if args[1] == '-' and args[2] < 15 then
            naughty.notify({
                preset = naughty.config.presets.critical,
                title = 'Batterie',
                text = 'La batterie doit être chargée immédiatement !',
                timeout = 5 })
        end

        return r
    end, 5, 'BAT0')

-- Volume Widget
volwidget = wibox.widget.textbox()
vicious.register(volwidget, vicious.widgets.volume,
    function (widget, args)
        r = ' SOUND: '

        if args[2] == '♫' then
            r = r .. '<span color="#00ff00">' .. args[1] .. '</span>% '
        else
            r = r .. '<span color="red">' .. args[1] .. '</span>M '
        end

        return r
    end, 10, 'Master')

-- Memory Widget
memwidget = wibox.widget.textbox()
vicious.register(memwidget, vicious.widgets.mem,
    function (widget, args)
        color = '#00ff00'
        if args[1] >= 86 then
            color = "red"
        elseif args[1] >= 71 then
            color = "orange"
        elseif args[1] >= 51 then
            color = "yellow"
        end

	    return ' RAM: <span color="' .. color .. '">' .. args[1] .. '</span>% (<span color="' .. color .. '">' .. args[2] .. '</span>MB/' .. args[3] .. 'MB) '
    end, 2)

-- CPU Temperature Widget
cputempwidget = wibox.widget.textbox()
vicious.register(cputempwidget, vicious.widgets.thermal,
    function (widget, args)
        r = ' T: '

        if args[1] < 46 then
            r = r .. '<span color="turquoise">' .. args[1] .. '</span>'
        elseif	args[1] < 61 then
            r = r .. '<span color="yellow">' .. args[1] .. '</span>'
        elseif  args[1] < 76 then
            r = r .. '<span color="orange">' .. args[1] .. '</span>'
        else
            r = r .. '<span color="red">' .. args[1] .. '</span>'
        end

        r = r .. '°C '
        return r
    end, 2, 'thermal_zone0')

-- CPU Information Widget
cpuinfowidget = wibox.widget.textbox()
vicious.register(cpuinfowidget, vicious.widgets.cpu,
    function (widget, args)
        r = ' CPU: '

        if args[1] < 31 then
            r = r .. '<span color="#00ff00">' .. args[1] .. '</span>'
        elseif args[1] < 51 then
            r = r .. '<span color="yellow">' .. args[1] .. '</span>'
        elseif args[1] < 70 then
            r = r .. '<span color="orange">' .. args[1] .. '</span>'
        else
            r = r ..'<span color="red">' .. args[1] .. '</span>'
        end

        r = r .. '% '
        return r
    end, 2)

-- LAN Widget
lanwidget = wibox.widget.textbox()
vicious.register(lanwidget, vicious.widgets.net,
    function (widget, args)
        r = ' LAN: '

        if args['{enp2s0 carrier}'] == 1 then
            r = r .. '<span color="#00ff00">ON</span> '
        else
            r = r .. '<span color="red">OFF</span> '
        end

        return r
    end, 10)

-- WIFI Widget
wifiwidget = wibox.widget.textbox()
vicious.register(wifiwidget, vicious.widgets.wifi,
    function (widget, args)
        r = ' WLAN: '

        if args['{ssid}'] == 'N/A' then
            r = r .. '<span color="red">OFF</span> '
        else
            r = r .. '<span color="#00ff00">' .. args['{ssid}'] .. '</span> '
        end

        return r
    end, 10, 'wlp3s0')

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, fg = beautiful.wibox_fg })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(wifiwidget)
    right_layout:add(separator)
    right_layout:add(lanwidget)
    right_layout:add(separator)
    right_layout:add(cpuinfowidget)
    right_layout:add(separator)
    right_layout:add(cputempwidget)
    right_layout:add(separator)
    right_layout:add(memwidget)
    right_layout:add(separator)
    right_layout:add(volwidget)
    right_layout:add(separator)
    right_layout:add(batwidget)
    right_layout:add(separator)
    right_layout:add(mytextclock)
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
Numeric_Pad = { "KP_End", "KP_Down", "KP_Next", "KP_Left", "KP_Begin", "KP_Right", "KP_Home", "KP_Up", "KP_Prior" }

globalkeys = awful.util.table.join(
    awful.key({ modkey }, "Left",
        awful.tag.viewprev
    ),

    awful.key({ modkey }, "Right",
        awful.tag.viewnext
    ),

    awful.key({ modkey }, "Escape",
        awful.tag.history.restore
    ),

    awful.key({ modkey }, "j", function ()
        awful.client.focus.byidx( 1)
        if client.focus then client.focus:raise() end
    end),

    awful.key({ modkey }, "k", function ()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end),

    awful.key({ modkey }, "w", function ()
        mymainmenu:show()
    end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function ()
        awful.client.swap.byidx(  1)
    end),

    awful.key({ modkey, "Shift"   }, "k", function ()
        awful.client.swap.byidx(-1)
    end),

    awful.key({ modkey, "Control" }, "j", function ()
        awful.screen.focus_relative(1)
    end),

    awful.key({ modkey, "Control" }, "k", function ()
        awful.screen.focus_relative(-1)
    end),

    awful.key({ modkey }, "u",
        awful.client.urgent.jumpto
    ),

    awful.key({ modkey }, "Tab", function ()
        awful.client.focus.byidx(1)
        if client.focus then client.focus:raise() end
    end),

    -- Standard program
    awful.key({ modkey }, "Return", function ()
        awful.util.spawn(terminal)
    end),

    awful.key({ modkey, "Control" }, "r",
        awesome.restart
    ),

    awful.key({ modkey, "Shift"   }, "q",
        awesome.quit
    ),


    awful.key({ modkey }, "l", function ()
        awful.tag.incmwfact( 0.05)
    end),

    awful.key({ modkey }, "h", function ()
        awful.tag.incmwfact(-0.05)
    end),

    awful.key({ modkey, "Shift" }, "h", function ()
        awful.tag.incnmaster(1)
    end),

    awful.key({ modkey, "Shift" }, "l", function ()
        awful.tag.incnmaster(-1)
    end),

    awful.key({ modkey, "Control" }, "h", function ()
        awful.tag.incncol(1)
    end),

    awful.key({ modkey, "Control" }, "l", function ()
        awful.tag.incncol(-1)
    end),

    awful.key({ modkey }, "space", function ()
        awful.layout.inc(layouts, 1)
    end),

    awful.key({ modkey, "Shift" }, "space", function ()
        awful.layout.inc(layouts, -1)
    end),

    awful.key({ modkey, "Control" }, "n",
        awful.client.restore
    ),

    -- Prompt
    awful.key({ modkey }, "r", function ()
        mypromptbox[mouse.screen]:run()
    end),

    awful.key({ modkey }, "x", function ()
        awful.prompt.run({ prompt = "Run Lua code: " },
        mypromptbox[mouse.screen].widget,
        awful.util.eval, nil,
        awful.util.getdir("cache") .. "/history_eval")
    end),

    -- Menubar
    --awful.key({ modkey }, "p", function()
    --    menubar.show()
    --end),

    -- Personnal Key Bindings
    awful.key({ modkey }, "F1", function ()
        awful.util.spawn_with_shell("scrot /tmp/screentmp.png; i3lock -u -i /tmp/screentmp.png > /dev/null; systemctl suspend")
    end),

    awful.key({ modkey }, "F3", function ()
        awful.util.spawn_with_shell(terminal .. "-e 'sudo " .. os.getenv("HOME") .. "/disconnectWiFi.sh'")
    end),

    awful.key({ modkey }, "F2", function ()
        awful.util.spawn_with_shell("scrot /tmp/screentmp.png; i3lock -u -i /tmp/screentmp.png > /dev/null")
    end),

    awful.key({ modkey }, "f", function ()
        awful.util.spawn("firefox")
    end),

    awful.key({ modkey }, "s", function ()
        awful.util.spawn("pavucontrol")
        awful.util.spawn("rhythmbox")
    end),

    awful.key({ modkey }, "t", function ()
        awful.util.spawn("thunar")
    end),

    awful.key({ modkey }, "e", function ()
        awful.util.spawn("evince")
    end),

    awful.key({ modkey }, "b", function ()
        awful.util.spawn("thunderbird")
    end),

    awful.key({ modkey }, "F9", function ()
        awful.util.spawn_with_shell("synclient TouchpadOff=$(synclient -l | grep -c 'TouchpadOff.*=.*0')")
    end),

    awful.key({ modkey }, "p", function ()
        awful.util.spawn("pidgin")
    end),

    awful.key({ modkey }, "q", function ()
        awful.util.spawn("scrot")
    end),

    -- Audio Keybindings
    awful.key({ }, "XF86AudioRaiseVolume", function ()
        awful.util.spawn("amixer -q sset Master 2%+")
        vicious.force({ volwidget, })
    end),

    awful.key({ modkey }, "F3", function ()
        awful.util.spawn("amixer -q sset Master 2%+")
        vicious.force({ volwidget, })
    end),

    awful.key({ }, "XF86AudioLowerVolume", function ()
        awful.util.spawn("amixer -q sset Master 2%-")
        vicious.force({ volwidget, })
    end),

    awful.key({ modkey }, "F2", function ()
        awful.util.spawn("amixer -q sset Master 2%-")
        vicious.force({ volwidget, })
    end),

    awful.key({ }, "XF86AudioMute", function ()
        awful.util.spawn("amixer -q sset Master toggle")
        vicious.force({ volwidget, })
    end),

    awful.key({ modkey }, "F12", function ()
        awful.util.spawn("amixer -q sset Master 2%+")
        vicious.force({ volwidget, })
    end),

    awful.key({ modkey }, "F11", function ()
        awful.util.spawn("amixer -q sset Master 2%-")
        vicious.force({ volwidget, })
    end),

    awful.key({ modkey }, "F10", function ()
        awful.util.spawn("amixer -q sset Master toggle")
        vicious.force({ volwidget, })
    end),

    awful.key({ modkey }, "n", function ()
        awful.util.spawn("mocp --next")
    end),

    -- Troll Keybindings
    awful.key({ modkey }, Numeric_Pad[1], function ()
        awful.util.spawn("paplay /home/toffan/Musique/Répliques/cest_pas_faux.ogg")
    end),

    awful.key({ modkey }, Numeric_Pad[2], function ()
        awful.util.spawn("paplay /home/toffan/Musique/Répliques/cest_de_la_merde.ogg")
    end),

    awful.key({ modkey }, Numeric_Pad[3], function ()
        awful.util.spawn("paplay /home/toffan/Musique/Répliques/faire_toi_meme.ogg")
    end),

    awful.key({ modkey }, Numeric_Pad[4], function ()
        awful.util.spawn("paplay /home/toffan/Musique/Répliques/insinuyer_sir.ogg")
    end),

    awful.key({ modkey }, Numeric_Pad[5], function ()
        awful.util.spawn("paplay /home/toffan/Musique/Répliques/pas_drole.ogg")
    end),

    awful.key({ modkey }, Numeric_Pad[6], function ()
        awful.util.spawn("paplay /home/toffan/Musique/Répliques/pas_une_blague.ogg")
    end),

    awful.key({ modkey }, Numeric_Pad[7], function ()
        awful.util.spawn("paplay /home/toffan/Musique/Répliques/coup_masse_gueule.ogg")
    end),

    awful.key({ modkey }, Numeric_Pad[8], function ()
        awful.util.spawn("paplay /home/toffan/Musique/Répliques/mur_monte_démonte.ogg")
    end),

    awful.key({ modkey }, Numeric_Pad[9], function ()
        awful.util.spawn("paplay /home/toffan/Musique/Répliques/deconcentration.ogg")
    end),
    awful.key({ modkey, "Shift"   }, "s", function ()
        wp_timer:emit_signal("timeout")
    end)

)

clientkeys = awful.util.table.join(
    --awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey },            "c",      function (c) c:kill()                         end),
    awful.key({ "Mod1" },            "F4",     function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    --awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    --awful.key({ modkey,           }, "n",      function (c) c.minimized = true               end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 13 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.movetotag(tag)
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.toggletag(tag)
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = {
          border_width = beautiful.border_width,
          border_color = beautiful.border_normal,
          focus = awful.client.focus.filter,
          keys = clientkeys,
          buttons = clientbuttons,
          size_hints_honor = false } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Mapping rules
    { rule = { class = "Thunderbird" },
      properties = { tag = tags[1][13] } },
    { rule = { class = "Firefox" },
      properties = { tag = tags[1][12] } },
    { rule = { class = "Pidgin" },
      properties = { tag = tags[1][11] } },
    { rule = { class = "Pavucontrol" },
      properties = { tag = tags[1][9] } },
    { rule = { class = "Rhythmbox" },
      properties = { tag = tags[1][9] } },
    { rule = { class = "Poezio" },
      properties = { tag = tags[1][11] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

-- }}}
