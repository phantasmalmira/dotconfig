local wezterm = require("wezterm")
local action = wezterm.action
local nerdfonts = wezterm.nerdfonts
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Appearance
config.max_fps = 144
config.front_end = "OpenGL"
for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
	if gpu.backend == "Vulkan" and gpu.device_type == "DiscreteGpu" then
		config.webgpu_preferred_adapter = gpu
		config.webgpu_power_preference = "HighPerformance"
		config.front_end = "WebGpu"
		break
	end
end
config.color_scheme = "Catppuccin Frappe"
config.default_prog = { "nu" }
config.font = wezterm.font("Iosevka NFM")
config.font_size = 13
config.freetype_load_target = "Normal"
config.freetype_render_target = "Normal"
config.line_height = 1.00
config.prefer_egl = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.window_padding = {
	left = "0",
	right = "0",
	top = "5pt",
	bottom = "0",
}
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_button_alignment = "Right"
config.integrated_title_button_style = "Windows"
-- config.win32_system_backdrop = "Acrylic"
-- config.window_background_opacity = 0.5
-- config.background = {
-- 	{
-- 		source = { Color = "black" },
-- 		width = "100%",
-- 	},
-- }

-- Tab bar styles

local color_scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
color_scheme.tab_bar.active_tab_hover = color_scheme.tab_bar.active_tab_hover or color_scheme.tab_bar.active_tab
color_scheme.tab_bar.inactive_tab_hover = color_scheme.tab_bar.inactive_tab_hover or color_scheme.tab_bar.inactive_tab
config.tab_max_width = 32
config.tab_bar_style = {
	new_tab = wezterm.format({
		{ Foreground = { Color = color_scheme.tab_bar.background } },
		{ Text = nerdfonts.ple_upper_left_triangle },
		{ Foreground = { Color = color_scheme.tab_bar.new_tab.fg_color } },
		{ Text = " " .. nerdfonts.cod_add .. " " },
		{ Foreground = { Color = color_scheme.tab_bar.background } },
		{ Text = nerdfonts.ple_lower_right_triangle },
	}),
	new_tab_hover = wezterm.format({
		{ Foreground = { Color = color_scheme.tab_bar.background } },
		{ Text = nerdfonts.ple_upper_left_triangle },
		{ Foreground = { Color = color_scheme.tab_bar.new_tab_hover.fg_color } },
		{ Text = " " .. nerdfonts.cod_add .. " " },
		{ Foreground = { Color = color_scheme.tab_bar.background } },
		{ Text = nerdfonts.ple_lower_right_triangle },
	}),
	window_hide = " " .. nerdfonts.cod_chrome_minimize .. " ",
	window_maximize = " " .. nerdfonts.cod_chrome_maximize .. " ",
	window_close = " " .. nerdfonts.cod_chrome_close .. " ",
	window_hide_hover = " " .. nerdfonts.cod_chrome_minimize .. " ",
	window_maximize_hover = " " .. nerdfonts.cod_chrome_maximize .. " ",
	window_close_hover = " " .. nerdfonts.cod_chrome_close .. " ",
}
local function get_tab_title(tab_info)
	local title = tab_info.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	-- Otherwise, use the title from the active pane
	-- in that tab
	local is_nvim = tab_info.active_pane.user_vars.IS_NVIM == "true"
	if is_nvim then
		return wezterm.nerdfonts.dev_vim .. " Neovim"
	end
	return tab_info.active_pane.title
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local segments = {}

	local active_tab_color = {
		fg = hover and color_scheme.tab_bar.active_tab_hover.fg_color or color_scheme.tab_bar.active_tab.fg_color,
		bg = hover and color_scheme.tab_bar.active_tab_hover.bg_color or color_scheme.tab_bar.active_tab.bg_color,
	}
	local inactive_tab_color = {
		fg = hover and color_scheme.tab_bar.inactive_tab_hover.fg_color or color_scheme.tab_bar.inactive_tab.fg_color,
		bg = hover and color_scheme.tab_bar.inactive_tab_hover.bg_color or color_scheme.tab_bar.inactive_tab.bg_color,
	}
	local tab_background = tab.is_active and active_tab_color.bg or inactive_tab_color.bg

	if tab.tab_index == 0 then
		table.insert(segments, { Background = { Color = tab_background } })
		table.insert(segments, { Text = " " })
	elseif tab.is_active then
		table.insert(segments, { Foreground = { Color = color_scheme.tab_bar.inactive_tab.bg_color } })
		table.insert(segments, { Background = { Color = tab_background } })
		table.insert(segments, { Text = nerdfonts.ple_upper_left_triangle .. " " })
	elseif tabs[tab.tab_index].is_active then
		table.insert(segments, { Text = " " })
	else
		table.insert(segments, { Text = nerdfonts.ple_forwardslash_separator .. " " })
	end

	local title = tab.tab_index + 1 .. ": " .. get_tab_title(tab)
	title = wezterm.truncate_right(title, config.tab_max_width - 4)
	table.insert(segments, { Text = title })

	if tab.is_active then
		table.insert(segments, { Background = { Color = tab_background } })
		if tab.tab_index == #tabs - 1 then
			table.insert(segments, { Foreground = { Color = color_scheme.tab_bar.background } })
		else
			table.insert(segments, { Foreground = { Color = color_scheme.tab_bar.inactive_tab.bg_color } })
		end
		table.insert(segments, { Text = " " })
		table.insert(segments, { Text = nerdfonts.ple_lower_right_triangle })
	else
		table.insert(segments, { Text = " " })
		if tab.tab_index == #tabs - 1 then
			table.insert(segments, { Foreground = { Color = color_scheme.tab_bar.background } })
			table.insert(segments, { Text = nerdfonts.ple_lower_right_triangle })
		end
	end

	return segments
end)

-- Launch menu
config.launch_menu = {
	{
		label = "Nvim",
		args = { "nvim" },
	},
	{
		label = "Nvim (Scratch)",
		args = { "nvim" },
		set_environment_variables = {
			NVIM_APPNAME = "nvim-scratch",
		},
	},
}
-- Windows shells
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	table.insert(config.launch_menu, {
		label = "Nushell",
		args = { "nu" },
	})
	table.insert(config.launch_menu, {
		label = "Windows Powershell",
		args = { "powershell.exe", "-NoLogo" },
	})
	for _, verPwsh in ipairs(wezterm.glob("Powershell/*", "C:/Program Files")) do
		local version = verPwsh:gsub("Powershell/", "")
		table.insert(config.launch_menu, {
			label = "Powershell Core " .. version,
			args = { "C:/Program Files/Powershell/" .. version .. "/pwsh.exe", "-NoLogo" },
		})
	end
end

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	Left = "h",
	Down = "j",
	Up = "k",
	Right = "l",
	-- reverse lookup
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
				}, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

-- Key maps
config.disable_default_key_bindings = true
config.leader = { key = "w", mods = "ALT" }
config.keys = {
	-- -- move between split panes
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	-- -- resize panes
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),
	{
		key = "c",
		mods = "CTRL|SHIFT",
		action = action.CopyTo("Clipboard"),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT",
		action = action.PasteFrom("Clipboard"),
	},
	{
		key = "y",
		mods = "LEADER",
		action = action.ActivateCopyMode,
	},
	{
		key = "v",
		mods = "LEADER",
		action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "s",
		mods = "LEADER",
		action = action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "h",
		mods = "SHIFT|ALT",
		action = action.ActivateTabRelative(-1),
	},
	{
		key = "l",
		mods = "SHIFT|ALT",
		action = action.ActivateTabRelative(1),
	},
	{
		key = "UpArrow",
		mods = "ALT",
		action = action.AdjustPaneSize({ "Up", 1 }),
	},
	{
		key = "DownArrow",
		mods = "ALT",
		action = action.AdjustPaneSize({ "Down", 1 }),
	},
	{
		key = "LeftArrow",
		mods = "ALT",
		action = action.AdjustPaneSize({ "Left", 1 }),
	},
	{
		key = "RightArrow",
		mods = "ALT",
		action = action.AdjustPaneSize({ "Right", 1 }),
	},
	{
		key = "z",
		mods = "LEADER",
		action = action.TogglePaneZoomState,
	},
	{
		key = "c",
		mods = "LEADER",
		action = action.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "C",
		mods = "LEADER",
		action = action.ShowLauncher,
	},
	{
		key = "x",
		mods = "LEADER",
		action = action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "d",
		mods = "LEADER",
		action = action.CloseCurrentTab({ confirm = true }),
	},
	{
		key = "p",
		mods = "LEADER",
		action = action.ActivateCommandPalette,
	},
	{
		key = "w",
		mods = "LEADER",
		action = action.ShowTabNavigator,
	},
	{
		key = "Enter",
		mods = "LEADER",
		action = action.ToggleFullScreen,
	},
	{
		key = "i",
		mods = "LEADER",
		action = action.ShowDebugOverlay,
	},
}

-- Mouse bindings
config.bypass_mouse_reporting_modifiers = "CTRL"
config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = action.OpenLinkAtMouseCursor,
	},
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = action.Nop,
	},
}

return config
