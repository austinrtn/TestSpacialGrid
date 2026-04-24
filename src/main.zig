const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const ZGL = @import("SpacialGrid").ZigGridLib(.{});

const SpawnLoc = enum {top, bottom, left, right};
const RectEnt = struct {
    x: f32, 
    y: f32,
    w: f32, 
    h: f32, 
    id: u32,
    spawn_loc: SpawnLoc,
    passed_test: bool = false,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const screenWidth = 800;
    const screenHeight = 800;
    const speed = 250;

    var grid: *ZGL.SpacialGrid = try .init(.{
        .allocator = allocator,
        .io = io,
        .width = screenWidth,
        .height = screenHeight,
        .cell_size_multiplier = 2, 
        .multi_threaded = true,
    });
    defer grid.deinit();

    var rects: std.MultiArrayList(RectEnt) = .empty;
    defer rects.deinit(allocator);
    try genRects(allocator, &rects, screenWidth, screenHeight);

    rl.initWindow(screenWidth, screenHeight, "Test");
    defer rl.closeWindow(); 

    rl.setTargetFPS(60);
                         
    const xs = rects.items(.x);
    const ys = rects.items(.y);
    const ws = rects.items(.w);
    const hs = rects.items(.h);
    const ids = rects.items(.id);
    const locs = rects.items(.spawn_loc);
    const tests = rects.items(.passed_test);

    try grid.ensureCapacity(rects.len, .Rect);
    try grid.insertRects(ids, xs, ys, ws, hs);
    try grid.updateCellSize(null);

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.white);

        try grid.insertRects(ids, xs, ys, ws, hs);

        for(xs, ys, locs) |*x, *y, loc| {
            _ = x;
            if(loc == .top) {
                y.* += speed * rl.getFrameTime();
            } else if(loc == .bottom) {
                y.* += -speed * rl.getFrameTime();
            }
        }

        const results = try grid.update();
        if(results.items.len == 0) std.debug.print("No results \r", .{});
        for(results.items) |result| {
            tests[result.a] = true;
            tests[result.b] = true;
        }

        for(xs, ys, ws, hs, tests) |x, y, w, h, passed| {
            const color: rl.Color = if(passed) .green else .red;
            rl.drawRectangleV(.init(x, y), .init(w, h), color);
        }
    }
}

fn genRects(allocator: std.mem.Allocator, rects: *std.MultiArrayList(RectEnt), screenWidth: f32, screenHeight: f32) !void {
    var i: usize = 0;
    var x: f32 = 0;
    var y: f32 = 10;
    const w: f32 = 25;
    const h: f32 = 25;
    const pad: f32 = 5;

    var passed_once = false;
    while(true) {
        while(x + pad < screenWidth) : (i += 1) {
            const rect: RectEnt = .{
                .x = x,
                .y = y, 
                .w = w,
                .h = h,
                .id = @intCast(i), 
                .spawn_loc = if(y < screenHeight / 2) .top else .bottom,
            };

            try rects.append(allocator, rect); 
            x += w + pad;
        }
        if(passed_once) break;

        passed_once = true;
        y = screenHeight - 10;
        x = 0;
    }
}
