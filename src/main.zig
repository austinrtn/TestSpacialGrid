const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const ZGL = @import("SpacialGrid").ZigGridLib(.{});

const RectEnt = struct {
    x: f32, 
    y: f32,
    w: f32 = 15,
    h: f32 = 15, 
    x_vel: f32,
    y_vel: f32,
    color: rl.Color = .gray,
    id: u32,
};

const CircleEnt = struct {
    x: f32, 
    y: f32,
    r: f32 = 15,
    x_vel: f32,
    y_vel: f32,
    color: rl.Color = .gray,
    id: u32,
};

const screenWidth = 800;
const screenHeight = 800;
const rect_count = 100;
const circle_count = 100;
const speed = 100;
var id: u32 = 0;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var grid: *ZGL.SpacialGrid = try .init(.{
        .allocator = allocator,
        .io = io,
        .width = screenWidth,
        .height = screenHeight,
        .cell_size_multiplier = 2, 
        .multi_threaded = false,
    });
    defer grid.deinit();

    var rects: std.MultiArrayList(RectEnt) = .empty;
    defer rects.deinit(allocator);
    try genRects(allocator, io, &rects);

    var circles: std.MultiArrayList(CircleEnt) = .empty;
    defer circles.deinit(allocator);
    try genCircles(allocator, io, &circles);

    rl.initWindow(screenWidth, screenHeight, "Test");
    defer rl.closeWindow(); 

    rl.setTargetFPS(60);
                         
    const rect_xs = rects.items(.x);
    const rect_ys = rects.items(.y);
    const rect_ws = rects.items(.w);
    const rect_hs = rects.items(.h);
    const rect_ids = rects.items(.id);
    const rect_colors = rects.items(.color);
    const rect_x_vels = rects.items(.x_vel);
    const rect_y_vels = rects.items(.y_vel);

    const circle_xs = circles.items(.x);
    const circle_ys = circles.items(.y);
    const circle_rs = circles.items(.r);
    const circle_ids = circles.items(.id);
    const circle_colors = circles.items(.color);
    const circle_x_vels = circles.items(.x_vel);
    const circle_y_vels = circles.items(.y_vel);

    try grid.ensureCapacity(rects.len, .Rect);
    try grid.insertRects(rect_ids, rect_xs, rect_ys, rect_ws, rect_hs);
    try grid.updateCellSize(null);

    // gameloop
    while(!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.white);

        try grid.insertRects(rect_ids, rect_xs, rect_ys, rect_ws, rect_hs);
        try grid.insertCircles(circle_ids, circle_xs, circle_ys, circle_rs);

        for(rect_xs, rect_x_vels, rect_ys, rect_y_vels, rect_ws, rect_hs, rect_colors) |*x, *x_vel, *y, *y_vel, w, h, *color| {
            color.* = .gray;
            move(x, x_vel, y, y_vel);
            bounce(x, x_vel, w, screenWidth);
            bounce(y, y_vel, h, screenHeight);
        }

        for(circle_xs, circle_x_vels, circle_ys, circle_y_vels, circle_rs, circle_colors) |*x, *x_vel, *y, *y_vel, r, *color| {
            color.* = .gray;
            move(x, x_vel, y, y_vel);
            bounce(x, x_vel, r, screenWidth);
            bounce(y, y_vel, r, screenHeight);
        }

        const results = try grid.update();
        if(results.items.len == 0) std.debug.print("No results \r", .{});
        for(results.items) |result| {
            if(std.mem.findScalar(u32, rect_ids, result.a)) |idx| {
                var ent = rects.get(idx); 
                ent.color = .green;
                rects.set(idx, ent);
            }
            else if(std.mem.findScalar(u32, circle_ids, result.a)) |idx| {
                var ent = circles.get(idx); 
                ent.color = .green;
                circles.set(idx, ent);
            }

            if(std.mem.findScalar(u32, rect_ids, result.b)) |idx| {
                var ent = rects.get(idx); 
                ent.color = .green;
                rects.set(idx, ent);
            }
            else if(std.mem.findScalar(u32, circle_ids, result.b)) |idx| {
                var ent = circles.get(idx); 
                ent.color = .green;
                circles.set(idx, ent);
            }
        }

        for(rect_xs, rect_ys, rect_ws, rect_hs, rect_colors) |x, y, w, h, color| {
            rl.drawRectangleV(.init(x, y), .init(w, h), color);
        }

        for(circle_xs, circle_ys, circle_rs, circle_colors) |x, y, r, color| {
            rl.drawCircleV(.init(x, y), r, color);
        }
    }
}

fn move(x: *f32, x_vel: *f32, y: *f32, y_vel: *f32) void {
    x.* += x_vel.* * rl.getFrameTime();
    y.* += y_vel.* * rl.getFrameTime();
}

fn bounce(pos: *f32, vel: *f32, size: f32, bound: f32) void {
    if(pos.* < 0) {
        pos.* = 0;
        vel.* = @abs(vel.*);
    } else if(pos.* + size > bound) {
        pos.* = bound - size;
        vel.* = -@abs(vel.*);
    }
}

fn genRects(allocator: std.mem.Allocator, io: std.Io, rects: *std.MultiArrayList(RectEnt)) !void {
    const src: std.Random.IoSource = .{.io = io};
    const rng = src.interface();

    for(0..rect_count) |_| {
        const x: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenWidth));
        const y: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenHeight));
        const x_vel: f32 = if(rng.intRangeAtMost(usize, 0, 1) == 0) speed else -speed;
        const y_vel: f32 = if(rng.intRangeAtMost(usize, 0, 1) == 0) speed else -speed;

        const rect: RectEnt = .{
            .x = x,
            .y = y,
            .x_vel = x_vel,
            .y_vel = y_vel,
            .id = id,
        };
        try rects.append(allocator, rect);
        id += 1;
    }
}

fn genCircles(allocator: std.mem.Allocator, io: std.Io, circles: *std.MultiArrayList(CircleEnt)) !void {
    const src: std.Random.IoSource = .{.io = io};
    const rng = src.interface();

    for(0..rect_count) |_| {
        const x: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenWidth));
        const y: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenHeight));
        const x_vel: f32 = if(rng.intRangeAtMost(usize, 0, 1) == 0) speed else -speed;
        const y_vel: f32 = if(rng.intRangeAtMost(usize, 0, 1) == 0) speed else -speed;

        const circle: CircleEnt = .{
            .x = x,
            .y = y,
            .x_vel = x_vel,
            .y_vel = y_vel,
            .id = id,
        };

        try circles.append(allocator, circle);
        id += 1;
    }
}
