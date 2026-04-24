pub const packages = struct {
    pub const @"N-V-__8AAHvybwBw1kyBGn0BW_s1RqIpycNjLf_XbE-fpLUF" = struct {
        pub const build_root = "/home/dogmaticpolack/Documents/TestSpacialGrid/zig-pkg/N-V-__8AAHvybwBw1kyBGn0BW_s1RqIpycNjLf_XbE-fpLUF";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"N-V-__8AAJl1DwBezhYo_VE6f53mPVm00R-Fk28NPW7P14EQ" = struct {
        pub const build_root = "/home/dogmaticpolack/Documents/TestSpacialGrid/zig-pkg/N-V-__8AAJl1DwBezhYo_VE6f53mPVm00R-Fk28NPW7P14EQ";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"N-V-__8AALShqgXkvqYU6f__FrA22SMWmi2TXCJjNTO1m8XJ" = struct {
        pub const available = false;
    };
    pub const @"SpacialGrid-0.0.0-JQsE6Ak0AQAmdU6t1c-0b8tTzZMOV_Zck3RHp9OamfPg" = struct {
        pub const build_root = "/home/dogmaticpolack/Documents/TestSpacialGrid/zig-pkg/SpacialGrid-0.0.0-JQsE6Ak0AQAmdU6t1c-0b8tTzZMOV_Zck3RHp9OamfPg";
        pub const build_zig = @import("SpacialGrid-0.0.0-JQsE6Ak0AQAmdU6t1c-0b8tTzZMOV_Zck3RHp9OamfPg");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"raylib-5.6.0-dev-whq8uGJqKQUEDd38DCov-XG29PYzw3kM_LNbPUkcDGyM" = struct {
        pub const build_root = "/home/dogmaticpolack/Documents/TestSpacialGrid/zig-pkg/raylib-5.6.0-dev-whq8uGJqKQUEDd38DCov-XG29PYzw3kM_LNbPUkcDGyM";
        pub const build_zig = @import("raylib-5.6.0-dev-whq8uGJqKQUEDd38DCov-XG29PYzw3kM_LNbPUkcDGyM");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "xcode_frameworks", "N-V-__8AALShqgXkvqYU6f__FrA22SMWmi2TXCJjNTO1m8XJ" },
            .{ "emsdk", "N-V-__8AAJl1DwBezhYo_VE6f53mPVm00R-Fk28NPW7P14EQ" },
            .{ "zemscripten", "zemscripten-0.2.0-dev-sRlDqApRAACspTbAZnuNKWIzfWzSYgYkb2nWAXZ-tqqt" },
        };
    };
    pub const @"raylib_zig-5.6.0-dev-KE8REKNmBQDek2Sz27ULioxYpY9IYR0K0CeIC-iJRLCI" = struct {
        pub const build_root = "/home/dogmaticpolack/Documents/TestSpacialGrid/zig-pkg/raylib_zig-5.6.0-dev-KE8REKNmBQDek2Sz27ULioxYpY9IYR0K0CeIC-iJRLCI";
        pub const build_zig = @import("raylib_zig-5.6.0-dev-KE8REKNmBQDek2Sz27ULioxYpY9IYR0K0CeIC-iJRLCI");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "raylib", "raylib-5.6.0-dev-whq8uGJqKQUEDd38DCov-XG29PYzw3kM_LNbPUkcDGyM" },
            .{ "raygui", "N-V-__8AAHvybwBw1kyBGn0BW_s1RqIpycNjLf_XbE-fpLUF" },
            .{ "emsdk", "N-V-__8AAJl1DwBezhYo_VE6f53mPVm00R-Fk28NPW7P14EQ" },
            .{ "zemscripten", "zemscripten-0.2.0-dev-sRlDqFJSAAB8hgnRt5DDMKP3zLlDtMnUDwYRJVCa5lGY" },
        };
    };
    pub const @"zemscripten-0.2.0-dev-sRlDqApRAACspTbAZnuNKWIzfWzSYgYkb2nWAXZ-tqqt" = struct {
        pub const build_root = "/home/dogmaticpolack/Documents/TestSpacialGrid/zig-pkg/zemscripten-0.2.0-dev-sRlDqApRAACspTbAZnuNKWIzfWzSYgYkb2nWAXZ-tqqt";
        pub const build_zig = @import("zemscripten-0.2.0-dev-sRlDqApRAACspTbAZnuNKWIzfWzSYgYkb2nWAXZ-tqqt");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"zemscripten-0.2.0-dev-sRlDqFJSAAB8hgnRt5DDMKP3zLlDtMnUDwYRJVCa5lGY" = struct {
        pub const build_root = "/home/dogmaticpolack/Documents/TestSpacialGrid/zig-pkg/zemscripten-0.2.0-dev-sRlDqFJSAAB8hgnRt5DDMKP3zLlDtMnUDwYRJVCa5lGY";
        pub const build_zig = @import("zemscripten-0.2.0-dev-sRlDqFJSAAB8hgnRt5DDMKP3zLlDtMnUDwYRJVCa5lGY");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "raylib_zig", "raylib_zig-5.6.0-dev-KE8REKNmBQDek2Sz27ULioxYpY9IYR0K0CeIC-iJRLCI" },
    .{ "SpacialGrid", "SpacialGrid-0.0.0-JQsE6Ak0AQAmdU6t1c-0b8tTzZMOV_Zck3RHp9OamfPg" },
};
