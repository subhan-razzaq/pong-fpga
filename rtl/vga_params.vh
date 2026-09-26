`ifndef VGA_PARAMS_VH
`define VGA_PARAMS_VH

// VGA 640x480 @ 60 Hz timing
`define ACTIVE_COLUMNS 640
`define ACTIVE_ROWS    480
`define FRONT_PORCH_H  16
`define BACK_PORCH_H   48
`define SYNCPULSE_H    96
`define FRONT_PORCH_V  10
`define BACK_PORCH_V   33
`define SYNCPULSE_V    2

// Game grid
`define TILE_SIZE   16
`define TILE_COLUMN (`ACTIVE_COLUMNS / `TILE_SIZE)
`define TILE_ROW    (`ACTIVE_ROWS / `TILE_SIZE)
`define X_MIN       1
`define X_MAX       (`TILE_COLUMN - 2)
`define Y_MIN       0
`define Y_MAX       (`TILE_ROW - 1)
`define CENTER_X    (`TILE_COLUMN / 2)
`define CENTER_Y    (`TILE_ROW / 2)

// Derived sync timing
`define SYNC_START_H  (`ACTIVE_COLUMNS + `FRONT_PORCH_H)
`define SYNC_STOP_H   (`SYNC_START_H + `SYNCPULSE_H)
`define SYNC_START_V  (`ACTIVE_ROWS + `FRONT_PORCH_V)
`define SYNC_STOP_V   (`SYNC_START_V + `SYNCPULSE_V)
`define TOTAL_COLUMNS (`ACTIVE_COLUMNS + `FRONT_PORCH_H + `BACK_PORCH_H + `SYNCPULSE_H)
`define TOTAL_ROWS    (`ACTIVE_ROWS + `FRONT_PORCH_V + `BACK_PORCH_V + `SYNCPULSE_V)

`endif