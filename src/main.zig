const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const ZGL = @import("SpacialGrid").ZigGridLib(.{ .Profiling = true });

const EntType = enum { rect, circle, point };

const total_count = 1000;
const fps_cap = 60;
const shape_size = 12;
const screenWidth = 1000;
const screenHeight = 1000;
const m_threaded = true;
const rect_count = @divTrunc(total_count, 3);
const circle_count = @divTrunc(total_count, 3);
const point_count = @divTrunc(total_count, 3);
const point_radius = 3;
const speed = 100;
var moving = true;

const EntRef = struct {
    kind: EntType,
    index: usize,
};

var ents: []EntRef = undefined;
var ent_counter: usize = 0;

const field_map = ZGL.InsertionFieldMap{
    .xs = "x",
    .ys = "y",
    .ws = "w",
    .hs = "h",
    .ids = "id",
    .radii = "r",
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var buf: [1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(io, &buf);
    const writer = &stdout.interface;

    var grid: *ZGL.SpacialGrid = try .init(.{
        .allocator = allocator,
        .io = io,
        .width = screenWidth,
        .height = screenHeight,
        .cell_size_multiplier = 2,
        .multi_threaded = m_threaded,
    });
    defer grid.deinit();

    ents = try allocator.alloc(EntRef, rect_count + point_count + circle_count + 1);
    defer allocator.free(ents);

    var mouse_color: rl.Color = .gray;
    mouse_color.a = 100;
    var mouse_circ = CircleEnt{
        .x = 0,
        .y = 0,
        .r = 30,
        .color = mouse_color,
        .x_vel = 0,
        .y_vel = 0,
        .id = @intCast(ent_counter),
    };

    ent_counter += 1;

    var circles: std.MultiArrayList(CircleEnt) = .empty;
    defer circles.deinit(allocator);

    var rects: std.MultiArrayList(RectEnt) = .empty;
    defer rects.deinit(allocator);
    try genRects(allocator, io, &rects);

    var points: std.MultiArrayList(PointEnt) = .empty;
    defer points.deinit(allocator);
    try genPoints(allocator, io, &points);

    try genCircles(allocator, io, &circles);

    rl.setTraceLogLevel(.warning);
    rl.initWindow(screenWidth, screenHeight, "Test");
    defer rl.closeWindow();

    rl.hideCursor();
    rl.setTargetFPS(fps_cap);

    const circle_xs = circles.items(.x);
    const circle_ys = circles.items(.y);
    const circle_rs = circles.items(.r);
    const circle_colors = circles.items(.color);
    const circle_x_vels = circles.items(.x_vel);
    const circle_y_vels = circles.items(.y_vel);

    const point_xs = points.items(.x);
    const point_ys = points.items(.y);
    const point_ids = points.items(.id);
    const point_colors = points.items(.color);

    try grid.insert.Circle.mal(field_map, circles);
    try grid.insert.Rect.many(rects.items(.id), rects.items(.x), rects.items(.y), rects.items(.w), rects.items(.h));
    try grid.insert.Point.many(point_ids, point_xs, point_ys);
    try grid.updateCellSize(null);

    var snapshot = false;
    grid.startProfiler(500);
    // gameloop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.white);

        controller(.{
            .allocator = allocator,
            .io = io,
            .snapshot = &snapshot,
            .rects = &rects,
        });

        const rect_xs = rects.items(.x);
        const rect_ys = rects.items(.y);
        const rect_ws = rects.items(.w);
        const rect_hs = rects.items(.h);
        const rect_colors = rects.items(.color);
        const rect_x_vels = rects.items(.x_vel);
        const rect_y_vels = rects.items(.y_vel);

        mouse_circ.color = mouse_color;
        mouse_circ.x = rl.getMousePosition().x;
        mouse_circ.y = rl.getMousePosition().y;

        for (rect_xs, rect_x_vels, rect_ys, rect_y_vels, rect_ws, rect_hs, rect_colors) |*x, *x_vel, *y, *y_vel, w, h, *color| {
            color.* = rl.Color.light_gray;
            move(x, x_vel, y, y_vel);
            bounce(x, x_vel, w, screenWidth);
            bounce(y, y_vel, h, screenHeight);
        }

        for (circle_xs, circle_x_vels, circle_ys, circle_y_vels, circle_rs, circle_colors) |*x, *x_vel, *y, *y_vel, r, *color| {
            color.* = .gray;
            move(x, x_vel, y, y_vel);
            bounce(x, x_vel, r, screenWidth);
            bounce(y, y_vel, r, screenHeight);
        }

        try grid.insert.Circle.mal(field_map, circles);
        try grid.insert.Rect.mal(field_map, rects);
        try grid.insert.Point.mal(field_map, points);

        for (point_colors) |*color| {
            color.* = .dark_gray;
        }

        const mouse_query = try grid.query(mouse_circ.x, mouse_circ.y, .{ .Circle = mouse_circ.r });
        for (mouse_query) |id| {
            const ref = ents[id];
            switch (ref.kind) {
                .circle => circle_colors[ref.index] = .green,
                .rect => rect_colors[ref.index] = .green,
                .point => point_colors[ref.index] = .green,
            }
        }

        const results = try grid.update();

        if (results.items.len == 0) std.debug.print("No results \r", .{});
        for (results.items) |result| {
            markCollision(result.a, &rects, &circles, &points);
            markCollision(result.b, &rects, &circles, &points);
        }

        for (rect_xs, rect_ys, rect_ws, rect_hs, rect_colors) |x, y, w, h, color| {
            rl.drawRectangleV(.init(x, y), .init(w, h), color);
        }

        for (circle_xs, circle_ys, circle_rs, circle_colors) |x, y, r, color| {
            rl.drawCircleV(.init(x, y), r, color);
        }

        for (point_xs, point_ys, point_colors) |x, y, color| {
            rl.drawCircleV(.init(x, y), point_radius, color);
        }

        rl.drawCircleV(.init(mouse_circ.x, mouse_circ.y), 25, mouse_circ.color);
        const p_results = try grid.getProfileResults(true);

        try writer.print("{s}\n\n", .{p_results});
        try writer.flush();
        
        if(snapshot) {
            const path = "results.txt";
            var f_buf: [1024]u8 = undefined;
            var file = std.Io.Dir.cwd().openFile(io, path, .{.mode = .read_write}) catch |err| switch(err) {
                error.FileNotFound => try std.Io.Dir.cwd().createFile(io, path, .{}),
                else => return err,
            };
            defer file.close(io); 

            var f_writer = file.writer(io, &f_buf);
            try f_writer.seekTo(try file.length(io));
            try f_writer.interface.print("{s}\n", .{p_results});
            for(0..50) |_| try f_writer.interface.writeAll("_");
            try f_writer.interface.writeAll("\n\n\n\n");
            try f_writer.interface.flush();
        }
    }
}

fn markCollision(
    global_id: u32,
    rects: *std.MultiArrayList(RectEnt),
    circles: *std.MultiArrayList(CircleEnt),
    points: *std.MultiArrayList(PointEnt),
) void {
    const ent_ref = ents[@intCast(global_id)];
    switch (ent_ref.kind) {
        .rect => {
            rects.items(.color)[ent_ref.index] = .green;
        },
        .circle => {
            circles.items(.color)[ent_ref.index] = .green;
        },
        .point => {
            points.items(.color)[ent_ref.index] = .green;
        },
    }
}

fn move(x: *f32, x_vel: *f32, y: *f32, y_vel: *f32) void {
    if (!moving) return;
    x.* += x_vel.* * rl.getFrameTime();
    y.* += y_vel.* * rl.getFrameTime();
}

fn bounce(pos: *f32, vel: *f32, size: f32, bound: f32) void {
    if (pos.* < 0) {
        pos.* = 0;
        vel.* = @abs(vel.*);
    } else if (pos.* + size > bound) {
        pos.* = bound - size;
        vel.* = -@abs(vel.*);
    }
}

fn addRects(allocator: std.mem.Allocator, io: std.Io, rects: *std.MultiArrayList(RectEnt), count: usize) !void {
    const src: std.Random.IoSource = .{ .io = io };
    const rng = src.interface();

    ents = try allocator.realloc(ents, ents.len + count);

    for (0..count) |_| {
        const x: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenWidth));
        const y: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenHeight));
        const x_vel: f32 = if (rng.intRangeAtMost(usize, 0, 1) == 0) speed else -speed;
        const y_vel: f32 = if (rng.intRangeAtMost(usize, 0, 1) == 0) speed else -speed;

        const rect: RectEnt = .{
            .x = x,
            .y = y,
            .x_vel = x_vel,
            .y_vel = y_vel,
            .id = @intCast(ent_counter),
        };
        const local_index = rects.len;
        try rects.append(allocator, rect);

        ents[ent_counter] = .{ .kind = .rect, .index = local_index };
        ent_counter += 1;
    }
}

fn genRects(allocator: std.mem.Allocator, io: std.Io, rects: *std.MultiArrayList(RectEnt)) !void {
    const src: std.Random.IoSource = .{ .io = io };
    const rng = src.interface();

    for (0..rect_count) |_| {
        const x: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenWidth));
        const y: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenHeight));
        const x_vel: f32 = if (rng.intRangeAtMost(usize, 0, 1) == 0) speed else -speed;
        const y_vel: f32 = if (rng.intRangeAtMost(usize, 0, 1) == 0) speed else -speed;

        const rect: RectEnt = .{
            .x = x,
            .y = y,
            .x_vel = x_vel,
            .y_vel = y_vel,
            .id = @intCast(ent_counter),
        };
        const local_index = rects.len;
        try rects.append(allocator, rect);

        ents[ent_counter] = .{ .kind = .rect, .index = local_index };
        ent_counter += 1;
    }
}

fn genCircles(allocator: std.mem.Allocator, io: std.Io, circles: *std.MultiArrayList(CircleEnt)) !void {
    const src: std.Random.IoSource = .{ .io = io };
    const rng = src.interface();

    for (0..circle_count) |_| {
        const x: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenWidth));
        const y: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenHeight));
        const x_vel: f32 = if (rng.intRangeAtMost(usize, 0, 1) == 0) speed else -speed;
        const y_vel: f32 = if (rng.intRangeAtMost(usize, 0, 1) == 0) speed else -speed;

        const circle: CircleEnt = .{
            .x = x,
            .y = y,
            .x_vel = x_vel,
            .y_vel = y_vel,
            .id = @intCast(ent_counter),
        };

        const local_index = circles.len;
        try circles.append(allocator, circle);

        ents[ent_counter] = .{ .kind = .circle, .index = local_index };
        ent_counter += 1;
    }
}

fn genPoints(allocator: std.mem.Allocator, io: std.Io, points: *std.MultiArrayList(PointEnt)) !void {
    const src: std.Random.IoSource = .{ .io = io };
    const rng = src.interface();

    for (0..point_count) |_| {
        const x: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenWidth));
        const y: f32 = @floatFromInt(rng.intRangeAtMost(u32, 0, screenHeight));

        const point: PointEnt = .{
            .x = x,
            .y = y,
            .id = @intCast(ent_counter),
        };

        const local_index = points.len;
        try points.append(allocator, point);

        ents[ent_counter] = .{ .kind = .point, .index = local_index };
        ent_counter += 1;
    }
}

fn controller(stuff: anytype) void {
    if(rl.isKeyPressed(.space)) { if (moving) moving = false else moving = true; }
    if(rl.isKeyPressed(.enter)) stuff.snapshot.* = true;
}

const RectEnt = struct {
    x: f32,
    y: f32,
    w: f32 = shape_size,
    h: f32 = shape_size,
    x_vel: f32,
    y_vel: f32,
    color: rl.Color = .gray,
    id: u32,
};

const CircleEnt = struct {
    x: f32,
    y: f32,
    r: f32 = shape_size / 2,
    x_vel: f32,
    y_vel: f32,
    color: rl.Color = .gray,
    id: u32,
};

const PointEnt = struct {
    x: f32,
    y: f32,
    color: rl.Color = .gray,
    id: u32,
};
