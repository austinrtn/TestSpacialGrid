const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const ZGL = @import("SpacialGrid").ZigGridLib(.{});

const EntType = enum { rect, circle, point };

const EntRef = struct {
    kind: EntType,
    index: usize,
};

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

const PointEnt = struct {
    x: f32,
    y: f32,
    color: rl.Color = .gray,
    id: u32,
};

const screenWidth = 800;
const screenHeight = 800;
const rect_count = 50;
const circle_count = 50;
const point_count = 50;
const point_radius = 3;
const speed = 100;

var ents: []EntRef = undefined;
var ent_counter: usize = 0;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var grid: *ZGL.SpacialGrid = try .init(.{
        .allocator = allocator,
        .io = io,
        .width = screenWidth,
        .height = screenHeight,
        .cell_size_multiplier = 2,
        .multi_threaded = true,
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

    const point_xs = points.items(.x);
    const point_ys = points.items(.y);
    const point_ids = points.items(.id);
    const point_colors = points.items(.color);

    try grid.insert().rects(rect_ids, rect_xs, rect_ys, rect_ws, rect_hs);
    try grid.insert().circles(circle_ids, circle_xs, circle_ys, circle_rs);
    try grid.insert().points(point_ids, point_xs, point_ys);
    try grid.updateCellSize(null);

    // gameloop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.white);

        mouse_circ.color = mouse_color;
        mouse_circ.x = rl.getMousePosition().x;
        mouse_circ.y = rl.getMousePosition().y;

        for (rect_xs, rect_x_vels, rect_ys, rect_y_vels, rect_ws, rect_hs, rect_colors) |*x, *x_vel, *y, *y_vel, w, h, *color| {
            color.* = .gray;
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

        try grid.insert().rects(rect_ids, rect_xs, rect_ys, rect_ws, rect_hs);
        try grid.insert().circles(circle_ids, circle_xs, circle_ys, circle_rs);
        try grid.insert().points(point_ids, point_xs, point_ys);

        for (point_colors) |*color| {
            color.* = .gray;
        }
    
        const mouse_query = try grid.query(mouse_circ.x, mouse_circ.y, .{ .Circle = mouse_circ.r});
        for(mouse_query) |id| {
            const ref = ents[id];
            switch(ref.kind) {
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
            var ent = rects.get(ent_ref.index);
            ent.color = .green;
            rects.set(ent_ref.index, ent);
        },
        .circle => {
            var ent = circles.get(ent_ref.index);
            ent.color = .green;
            circles.set(ent_ref.index, ent);
        },
        .point => {
            var ent = points.get(ent_ref.index);
            ent.color = .green;
            points.set(ent_ref.index, ent);
        },
    }
}

fn move(x: *f32, x_vel: *f32, y: *f32, y_vel: *f32) void {
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
