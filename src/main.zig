const std = @import("std");
const raylib = @cImport(@cInclude("raylib.h"));

fn color(c: u32) raylib.Color {
    return .{
        .r = @intCast(c & 0xFF),
        .g = @intCast((c >> 8) & 0xFF),
        .b = @intCast((c >> 16) & 0xFF),
        .a = @intCast((c >> 24) & 0xFF),
    };
}

const Vec2 = struct { x: f32, y: f32 };
fn mulvf32(v: Vec2, f: f32) Vec2 {
    return .{ .x = v.x * f, .y = v.y * f };
}

fn add2v2(v: Vec2, w: Vec2) Vec2 {
    return .{ .x = v.x + w.x, .y = v.y + w.y };
}

fn width() f32 {
    return @as(f32, @floatFromInt(raylib.GetRenderWidth()));
}

fn height() f32 {
    return @as(f32, @floatFromInt(raylib.GetRenderHeight()));
}

fn screenCenter() Vec2 {
    return .{
        .x = width() / 2,
        .y = height() / 2,
    };
}

fn drawText(text: [*c]const u8, posX: f32, posY: f32, fontSize: f32, col: u32) void {
    raylib.DrawText(text, @intFromFloat(posX), @intFromFloat(posY), @intFromFloat(fontSize), color(col));
}

pub fn main() !void {
    raylib.SetConfigFlags(raylib.FLAG_WINDOW_RESIZABLE);
    raylib.InitWindow(800, 600, "Pong");
    var player1_pos = height() / 2;
    var player1_vel: f32 = 0;
    var player1_score: i32 = 0;
    var player2_pos = height() / 2;
    var player2_vel: f32 = 0;
    var player2_score: i32 = 0;

    var ball_pos: Vec2 = screenCenter();

    var ball_vel: Vec2 = .{
        .x = -300,
        .y = -300,
    };
    const ball_size = 10;

    const pad_begin = 20;
    const player_width = 10;
    const player_height = 100;
    var buff: [1024]u8 = undefined;
    var arena = std.heap.FixedBufferAllocator.init(buff[0..]);
    while (raylib.WindowShouldClose() == false) {
        raylib.BeginDrawing();
        raylib.ClearBackground(color(0x15151515));

        const player1_rect: raylib.Rectangle = .{ .x = pad_begin, .y = player1_pos, .width = player_width, .height = player_height };
        const player2_rect: raylib.Rectangle = .{ .x = width() - pad_begin - player_width, .y = player2_pos, .width = player_width, .height = player_height };
        const ball_rect: raylib.Rectangle = .{ .x = ball_pos.x, .y = ball_pos.y, .width = ball_size, .height = ball_size };

        raylib.DrawRectangleRec(player1_rect, color(0xA6A6A6A6));
        raylib.DrawRectangleRec(player2_rect, color(0xA6A6A6A6));
        raylib.DrawRectangleRec(ball_rect, color(0xC6C6C6C6));

        if (raylib.IsKeyDown(raylib.KEY_S)) player1_vel += 100;
        if (raylib.IsKeyDown(raylib.KEY_W)) player1_vel -= 100;
        player1_pos += player1_vel * raylib.GetFrameTime();
        player1_vel *= 0.80;

        if (raylib.IsKeyDown(raylib.KEY_DOWN)) player2_vel += 100;
        if (raylib.IsKeyDown(raylib.KEY_UP)) player2_vel -= 100;
        player2_pos += player2_vel * raylib.GetFrameTime();
        player2_vel *= 0.80;

        ball_pos = add2v2(ball_pos, mulvf32(ball_vel, raylib.GetFrameTime()));
        if (ball_pos.y <= 0.0) ball_vel.y = @fabs(ball_vel.y);
        if (ball_pos.y + ball_size >= height()) ball_vel.y = -@fabs(ball_vel.y);
        if (ball_pos.x <= 0.0) {
            ball_pos = screenCenter();
            player2_score += 1;
        }
        if (ball_pos.x > width()) {
            ball_pos = screenCenter();
            player1_score += 1;
        }
        if (raylib.CheckCollisionRecs(player1_rect, ball_rect)) {
            ball_vel.x = @fabs(ball_vel.x);
            ball_vel.y += player1_vel;
            ball_vel.y = std.math.sign(ball_vel.y) * @min(@fabs(ball_vel.y), 300);
            ball_pos.x = pad_begin + 2 * player_width;
        }
        if (raylib.CheckCollisionRecs(player2_rect, ball_rect)) {
            ball_vel.x = -@fabs(ball_vel.x);
            ball_vel.y += player2_vel;
            ball_vel.y = std.math.sign(ball_vel.y) * @min(@fabs(ball_vel.y), 300);
            ball_pos.x = width() - pad_begin - 2 * player_width;
        }

        {
            var s = std.ArrayList(u8).init(arena.allocator());
            try std.fmt.format(s.writer(), "{}", .{player1_score});
            try s.append(0);
            drawText(@as([*c]const u8, @ptrCast(&buff[0])), width() / 4, height() - 60, 60, 0xB1B1B1B1);
            arena.reset();
        }

        {
            var s = std.ArrayList(u8).init(arena.allocator());
            try std.fmt.format(s.writer(), "{}", .{player2_score});
            try s.append(0);
            drawText(@as([*c]const u8, @ptrCast(&buff[0])), 3 * width() / 4, height() - 60, 60, 0xB1B1B1B1);
            arena.reset();
        }

        raylib.EndDrawing();
    }
    std.log.info("EXITING", .{});
}
