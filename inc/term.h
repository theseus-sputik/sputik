//=======================
//-----------------------
// term.h
// 初始状态的数据结构
// 和asm*.inc一致
//-----------------------
//=======================

#ifndef TERM_H  // 文件定义
#define TERM_H

// 标准库调用
# include <stdint.h>

typedef struct {
    // windows
    int32_t     cols;                            // cols number
    int32_t     rows;                            // rows number
    int32_t     width;                           // pixel witdth
    int32_t     height;                          // pixel length

    // cursor
    int32_t     cx, cy;                          // cursor position
    uint8_t     cursor_style;                    // 0 = block, 1 = underline, 2=bar
    uint8_t     cursor_blink;                    // 判断闪烁

    // buffer
    uint64_t    *cells;                          // [rows][cols], per cells: glyph:16][fg:12][bg:12][attr:8][pad:16]

    // runtime
    uint8_t     mode;                            // position domain: ALT_SCREEN, MOUSE, etc.
    uint8_t     focused;                         // bool; check wether fouse exist; but firstly, take 4 bits blank position on regi
    uint8_t     need_redraw;                     // re-draw
    uint8_t     _pad[1];                         // align 1, follow above runtime define

    // tty
    int32_t     tty_fd;                          // main tty file desc

    // process
    int32_t     child_pid;                       // process PID

    // selected area
    int32_t     sel_start_x, sel_start_y;        //
    int32_t     sel_end_x, sel_end_y;            //
    uint8_t     sel_active;                      //
    uint8_t     sel_rect;                        //

    //delay rendering
    uint64_t    last_blink;                     //上次闪烁的时间   us
    uint64_t    last_draw;                      //上次绘制的时间点 us
} Term;

extern Term term;                               // global Instantiation, initialized by assembly

#endif
