---Inspector 持久配置
local InspectorConfiguration = plus.Class()

function InspectorConfiguration:init()
    self.enabled = false
    self.enabled_groups = {
        [GROUP_GHOST] = true,
        [GROUP_ENEMY_BULLET] = true,
        [GROUP_ENEMY] = true,
        [GROUP_NONTJT] = true,
    }
    self.statistics = {
        show_counts = true,
        show_groups = false,
        max_rows = 50,
    }
    self.object_meta_info = {
        show = true,
        show_invalid = true,
        show_group_id = false,
        show_editor = true,
        show_global = true,
        show_local = true,
        font_scale = 0.3,
    }
    self.instance_info = {
        show = true,
        show_protect = true,
        font_scale = 0.3,
    }
    self.indicator = {
        position = {
            show = true,
            size = 10,
            thickness = 1,
        },
        box = {
            show = true,
            thickness = 1,
        },
        polyline = {
            show = true,
            thickness = 1,
        },
        bezier3 = {
            show = true,
            width = 4,
            node_count = 48,
            texture = "laser_bent2",
            blend = "mul+add",
            uv_left = 0,
            uv_top = 0,
            uv_width = 256,
            uv_height = 32,
            scale = 1,
        },
        bezier5 = {
            show = true,
            width = 4,
            node_count = 64,
            texture = "laser_bent2",
            blend = "mul+add",
            uv_left = 0,
            uv_top = 0,
            uv_width = 256,
            uv_height = 32,
            scale = 1,
        },
    }
    self.group_names = {
        [GROUP_GHOST] = "GHOST",
        [GROUP_ENEMY_BULLET] = "ENEMY_BULLET",
        [GROUP_ENEMY] = "ENEMY",
        [GROUP_PLAYER_BULLET] = "PLAYER_BULLET",
        [GROUP_PLAYER] = "PLAYER",
        [GROUP_INDES] = "INDES",
        [GROUP_ITEM] = "ITEM",
        [GROUP_NONTJT] = "NONTJT",
        [GROUP_SPELL] = "SPELL",
        [GROUP_CPLAYER] = "CPLAYER",
    }
end

function InspectorConfiguration:load()
end

function InspectorConfiguration:save()
end

return InspectorConfiguration()
