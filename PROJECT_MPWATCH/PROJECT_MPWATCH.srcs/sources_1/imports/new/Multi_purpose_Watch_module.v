`timescale 1ns / 1ps

// T-flipflop Edge Detector (positive)
module edge_detector_p(
        input clk, reset_p,
        input cp,               // ck = clock pulse 
        output p_edge, n_edge);
        
        reg ff_cur, ff_old;
        always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                ff_cur = 0;
                ff_old = 0;
            end
            else begin   
                ff_old = ff_cur;
                ff_cur = cp;      
            end
        end
        
        assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;        // cur = 1, old = 0 일때만 1이고, 나머지는 0인 LUT
        assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;        // cur = 0, old = 1 일때 하강엣지 발생
        
endmodule

// T-flipflop Edge Detector (negative)
module edge_detector_n(
        input clk, reset_p,
        input cp,               // ck = clock pulse 
        output p_edge, n_edge);
        
        reg ff_cur, ff_old;
        always @(negedge clk or posedge reset_p)begin
            if(reset_p)begin
                ff_cur = 0;
                ff_old = 0;
            end
            else begin  
                ff_old = ff_cur;
                ff_cur = cp;   
            end
        end
        
        assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;        // cur = 1, old = 0 일때만 1이고, 나머지는 0인 LUT
        assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;        // cur = 0, old = 1 일때 하강엣지 발생
        
endmodule

// T-flipflop 상승엣지
module T_flip_flop_p(
        input clk, reset_p,
        input t,
        output reg q);
        
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p) q = 0;
                else begin
                        if(t) q = ~q;                   // toggle 
                        else q = q;                    // latch             
               end
       end   

endmodule

//1us 주기 clk
module clock_div_100(               // 100분주
        input clk, reset_p,
        output clk_div_100,
        output clk_div_100_nedge);
        
        reg [6:0] cnt_sysclk;               // 99까지 세기 위한 clk 수 :  7비트 필요함
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_sysclk = 0;
                else begin
                        if(cnt_sysclk >= 99) cnt_sysclk = 0;
                        else cnt_sysclk = cnt_sysclk + 1;
                end
        end
        
        assign clk_div_100 = (cnt_sysclk < 50) ? 0 : 1;        // cnt_sysclk 이 50보다 작으면 0, 크면 1 ( 주기가 1us인 펄스) duty rate : 50%
         
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div_100), .n_edge(clk_div_100_nedge)); 
         
endmodule

// 1ms
module clock_div_1000(               // 1000분주
        input clk, reset_p,
        input clk_source,
        output clk_div_1000,
        output clk_div_1000_nedge);
        
        reg [9:0] cnt_clksource;               // 999까지 세기 위한 clk 수 :  10비트 필요함
        
        wire clk_source_nedge;
         edge_detector_n ed_source(.clk(clk), .reset_p(reset_p), .cp(clk_source), .n_edge(clk_source_nedge));
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_clksource = 0;
                else if(clk_source_nedge)begin
                        if(cnt_clksource >= 999) cnt_clksource = 0;
                        else cnt_clksource = cnt_clksource + 1;
                end
        end                
        
        assign clk_div_1000 = (cnt_clksource < 500) ? 0 : 1;        // cnt_clksource 이 500보다 작으면 0, 크면 1 ( 주기가 1ms인 펄스)
         
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div_1000), .n_edge(clk_div_1000_nedge)); 
         
endmodule

//60분주
module clock_div_60(         // 60분주
        input clk, reset_p,
        input clk_source,
        output clk_div_60,
        output clk_div_60_nedge);
        
        reg [5:0] cnt_clksource;               // 60까지 세기 위한 clk 수 :  6비트 필요함
        
        wire clk_source_nedge;
        edge_detector_n ed_source(.clk(clk), .reset_p(reset_p), .cp(clk_source), .n_edge(clk_source_nedge));
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_clksource = 0;
                else if(clk_source_nedge)begin
                        if(cnt_clksource >= 59) cnt_clksource = 0;
                        else cnt_clksource = cnt_clksource + 1;
                end
        end                
        
        assign clk_div_60 = (cnt_clksource < 30) ? 0 : 1;        // cnt_clksource 이 30보다 작으면 0, 크면 1 ( 주기가 1ms인 펄스)
         
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div_60), .n_edge(clk_div_60_nedge)); 
         
endmodule

// loadable 60진 업카운터(시계)_upgrade Ver
module  loadable_counter_bcd_60(
        input   clk, reset_p,
        input   clk_time,
        input   load_enable,
        input   [3:0] load_bcd1, load_bcd10,
        output  reg [3:0]   bcd1, bcd10);
        
        wire clk_time_nedge;
        edge_detector_n ed_clk(.clk(clk), .reset_p(reset_p), .cp(clk_time), .n_edge(clk_time_nedge)); 
        
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                    bcd1 = 0;
                    bcd10 = 0;
                end    
                else begin
                    if(load_enable)begin
                        bcd1 = load_bcd1;
                        bcd10 = load_bcd10;
                    end                   
                    else if(clk_time_nedge)begin
                        if(bcd1 >= 9)begin
                            bcd1 = 0;
                            if(bcd10 >= 5)bcd10 =0;         //bcd1이 9가 되는 순간 bcd10 1 증가
                            else bcd10 = bcd10 + 1;
                        end    
                        else bcd1 = bcd1 + 1;
                    end
                end     
        end
endmodule

// loadable 60진 다운카운터(시계)_upgrade Ver
module  loadable_downcounter_bcd_60(
        input   clk, reset_p,
        input   clk_time,
        input   load_enable,
        input   [3:0] load_bcd1, load_bcd10,
        output  reg [3:0]   bcd1, bcd10,
        output  reg dec_clk);   // 초가 0 -> 59이 될때 한 clk만큼만 1을 발생시키는 one-cylce-pulse
        
        wire clk_time_nedge;
        edge_detector_n ed_clk(.clk(clk), .reset_p(reset_p), .cp(clk_time), .n_edge(clk_time_nedge)); 
        
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                    bcd1 = 0;
                    bcd10 = 0;
                    dec_clk = 0;
                end    
                else begin
                    if(load_enable)begin
                        bcd1 = load_bcd1;
                        bcd10 = load_bcd10;
                    end                   
                    else if(clk_time_nedge)begin
                        if(bcd1 == 0)begin
                            bcd1 = 9;
                            if(bcd10 == 0)begin        // bcd10 = 0이되는 순간 다시 5로 만들어줌 
                                bcd10 = 5;
                                dec_clk = 1;
                            end    
                            else bcd10 = bcd10 -1;
                        end    
                        else bcd1 = bcd1 -1;
                    end
                    else dec_clk = 0;                
                end     
        end
endmodule

// STOP watch CLEAR 
module  counter_bcd_60_clear(
        input   clk, reset_p,
        input   clk_time,
        input   clear,
        output  reg [3:0]   bcd1, bcd10);
        
        wire clk_time_nedge;
        edge_detector_n ed_clk(.clk(clk), .reset_p(reset_p), .cp(clk_time), .n_edge(clk_time_nedge)); 
        
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                    bcd1 = 0;
                    bcd10 = 0;
                end    
                else begin
                     if(clear)begin
                            bcd1 = 0;
                            bcd10 =0;
                     end
                     else if(clk_time_nedge)begin
                            if(bcd1 >= 9)begin
                                bcd1 = 0;
                                if(bcd10 >= 5)bcd10 =0;         //bcd1이 9가 되는 순간 bcd10 1 증가
                                else bcd10 = bcd10 + 1;
                            end    
                            else bcd1 = bcd1 + 1;
                     end
                end     
        end
endmodule

// 60진 카운터(시계)
module  counter_bcd_60(
        input   clk, reset_p,
        input   clk_time,
        output  reg [3:0]   bcd1, bcd10);
        
        wire clk_time_nedge;
        edge_detector_n ed_clk(.clk(clk), .reset_p(reset_p), .cp(clk_time), .n_edge(clk_time_nedge)); 
        
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                    bcd1 = 0;
                    bcd10 = 0;
                end    
                else if(clk_time_nedge)begin
                    if(bcd1 >= 9)begin
                        bcd1 = 0;
                        if(bcd10 >= 5)bcd10 =0;         //bcd1이 9가 되는 순간 bcd10 1 증가
                        else bcd10 = bcd10 + 1;
                    end    
                    else bcd1 = bcd1 + 1;
                end
        end
endmodule

// button(채터링 문제 해결)
module button_cntrl(
        input   clk, reset_p,
        input   btn,
        output  btn_pedge, btn_nedge);
        
        reg [20:0]  clk_div = 0;   
        always @(posedge clk) clk_div = clk_div + 1;
        
        wire clk_div_nedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));     // 16번 비트가 1.33ms
        
        reg debounced_btn;
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p)debounced_btn = 0;
                else if(clk_div_nedge)debounced_btn = btn;
        end
        
       edge_detector_p ed_btn(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .n_edge(btn_nedge), .p_edge(btn_pedge));                 
                
endmodule

// 디코더 세그먼트
module decoder_7seg(
        input [3:0] hex_value,
        output reg [7:0] seg_7);
        
        always @(hex_value)begin
                case(hex_value)
                                                      //abcd_efgp  
                        4'b0000 : seg_7 = 8'b0000_0011;     // 0
                        4'b0001 : seg_7 = 8'b1001_1111;     // 1
                        4'b0010 : seg_7 = 8'b0010_0101;     // 2
                        4'b0011 : seg_7 = 8'b0000_1101;     // 3
                        4'b0100 : seg_7 = 8'b1001_1001;     // 4
                        4'b0101 : seg_7 = 8'b0100_1001;     // 5
                        4'b0110 : seg_7 = 8'b0100_0001;     // 6
                        4'b0111 : seg_7 = 8'b0001_1011;     // 7
                        4'b1000 : seg_7 = 8'b0000_0001;     // 8
                        4'b1001 : seg_7 = 8'b0000_1001;     // 9
                        4'b1010 : seg_7 = 8'b0001_0001;     // A(10)
                        4'b1011 : seg_7 = 8'b1100_0001;     // b(11)
                        4'b1100 : seg_7 = 8'b0110_0011;     // C(12)
                        4'b1101 : seg_7 = 8'b1000_0101;     // d(13)
                        4'b1110 : seg_7 = 8'b0110_0001;     // E(14)
                        4'b1111 : seg_7 = 8'b0111_0001;     // F(15)
                endcase
        end                

endmodule

//FND Ring counter(com)
module ring_counter_fnd(
        input clk, reset_p,
        output  reg [3:0] com);
        
        reg [20:0]  clk_div = 0;        // '= 0'은 시뮬레이션 편의상 0으로 초기화 / 보드에서는 영향없음 
        always @(posedge clk) clk_div = clk_div + 1;
        
        wire clk_div_nedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) com = 4'b1110;
                else if(clk_div_nedge) begin
                        if(com == 4'b0111) com = 4'b1110;
                        else com[3:0] = {com[2:0], 1'b1};
                end
       end
endmodule

// fnd
module fnd_cntrl(
        input clk, reset_p,
        input [15:0] value,
        output  [3:0] com,
        output  [7:0] seg_7);
        
        ring_counter_fnd  rc(.clk(clk), .reset_p(reset_p), .com(com));
        
        reg [3:0] hex_value;
        always @(posedge clk)begin
                case(com)
                    4'b1110 : hex_value = value[3:0];
                    4'b1101 : hex_value = value[7:4];
                    4'b1011 : hex_value = value[11:8];
                    4'b0111 : hex_value = value[15:12];
                endcase    
        end
        
        decoder_7seg(.hex_value(hex_value), .seg_7(seg_7));
        
endmodule

// 모드 변경용 링카운터
module ring_counter_mode(
        input clk, reset_p,
        input [3:0] btn,
        output reg [2:0] btn_mode_ring,
        output reg [2:0] led_mode);
        
        wire btn_mode_nedge;
        button_cntrl    btn_mode( .clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode_pedge), .btn_nedge(btn_mode_nedge));
        
        // Mode 변경 버튼
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) btn_mode_ring = 3'b001;
                else if(btn_mode_nedge)begin
                    if(btn_mode_ring == 3'b100) btn_mode_ring = 3'b001; 
                    else btn_mode_ring = {btn_mode_ring[2:0], 1'b0};
                end
        end
        
        // Mode 변경에 따른 Mode 확인용 led 활성화 
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) led_mode = 3'b001;
                else if(btn_mode_nedge)begin
                    if(led_mode == 3'b100) led_mode = 3'b001; 
                    else led_mode = {led_mode[2:0], 1'b0};
                end
        end
endmodule               
        
 //loadable Watch(Upgrade Version)
 //모드가 변경되어도 동기화되어서 시간이 맞춰서 흐른다
module loadable_watch_project(
        input clk, reset_p,        
        input [3:0] btn,
        output reg [15:0] value);         
    
        wire set_watch;          // 1이면(누르면) set , 0이면 watch
        wire inc_sec, inc_min;
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire watch_load_en, set_load_en;
      
         //버튼 종류별기능 부여 (채터링 문제 해결)
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_mode_set_watch));                  
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_sec));
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_min));
                
        // 모드 변경 버튼 토글 설정 
        T_flip_flop_p   t_mode(.clk(clk), .reset_p(reset_p), .t(btn_mode_set_watch), .q(set_watch));
        
        // 시간 동기화(load)
        edge_detector_n ed_source(.clk(clk), .reset_p(reset_p), .cp(set_watch), .n_edge(watch_load_en), .p_edge(set_load_en));
        
        // 모드에 따른 대입 값 변경 선언 
        assign  inc_sec =  set_watch ? btn_sec : clk_sec;        // set 모드에서는 초 증가, watch모드에서는 시계모드
        assign  inc_min = set_watch ? btn_min : clk_min;        // set 모드에서는 분 증가, watch모드에서는 시계모드
        
        // 주기 생성
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));     // 1us         
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));     // 1ms  
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));         // 1s   
        clock_div_60    min_clk( .clk(clk), .reset_p(reset_p), .clk_source(inc_sec), .clk_div_60_nedge(clk_min));        // 1min 
       
        // loadable 60진 카운터 
        loadable_counter_bcd_60 sec_watch(
            .clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(watch_load_en),
            .load_bcd1(set_sec_1), .load_bcd10(set_sec_10),
            .bcd1(watch_sec_1), .bcd10(watch_sec_10));    
        loadable_counter_bcd_60 min_watch(
            .clk(clk), .reset_p(reset_p), .clk_time(clk_min), .load_enable(watch_load_en),
            .load_bcd1(set_min_1), .load_bcd10(set_min_10),
            .bcd1(watch_min_1), .bcd10(watch_min_10));
        loadable_counter_bcd_60 sec_set(
            .clk(clk), .reset_p(reset_p), .clk_time(btn_sec), .load_enable(set_load_en),
            .load_bcd1(watch_sec_1), .load_bcd10(watch_sec_10),
            .bcd1(set_sec_1), .bcd10(set_sec_10));    
        loadable_counter_bcd_60 min_set(
            .clk(clk), .reset_p(reset_p), .clk_time(btn_min), .load_enable(set_load_en),
            .load_bcd1(watch_min_1), .load_bcd10(watch_min_10),
            .bcd1(set_min_1), .bcd10(set_min_10));     
                
             wire [3:0] watch_sec_1,watch_sec_10, watch_min_1, watch_min_10;
             wire [3:0] set_sec_1,set_sec_10, set_min_1, set_min_10;
             wire [15:0] watch_value, set_value;  

            assign watch_value = {watch_min_10, watch_min_1, watch_sec_10, watch_sec_1};
            assign set_value = {set_min_10, set_min_1, set_sec_10, set_sec_1};
            
            always @(posedge clk or posedge reset_p)begin
                    if(reset_p) value = 0;
                    else begin
                         if(set_watch) value = set_value;
                         else value = watch_value;
                    end    
            end
            
endmodule


// STOP watch (start, stop, lap, clear)
module  stop_watch_project(
        input   clk, reset_p,
        input   [3:0] btn,
        output reg [15:0] value,
        output  led_start, led_lap);
        
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire [3:0] sec_1, sec_10, min_1, min_10;
        wire clk_start;
        wire start_stop; 
        reg lap;
        wire reset_start;
        
        // 시스템 리셋 버튼 / 클리어 버튼 분류
        assign reset_start = reset_p | btn_clear;
        // start / stop 버튼 대입 값 선언 
        assign clk_start = start_stop ? clk : 0;
        
        // 주기 생성 
        clock_div_100   usec_clk( .clk(clk_start), .reset_p(reset_start), .clk_div_100(clk_usec));   // 1us           
        clock_div_1000  msec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_usec), .clk_div_1000(clk_msec));   // 1ms  
        clock_div_1000  sec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));   // 1 sec   
        clock_div_60      min_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_sec), .clk_div_60_nedge(clk_min));   // 1min 
        
        // 종류별 버튼 기능 부여(채터링 문제 해결) 
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_start));   
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_lap));
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_clear));
        
        // start, stop 모드 토글 설정 + led on/off 
        T_flip_flop_p  t_start(.clk(clk), .reset_p(reset_start), .t(btn_start), .q(start_stop));
        assign  led_start = start_stop;
         
        // lap 모드 변경(lap 리셋 / 클리어 버튼 따로 생성) 
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p) lap = 0;
                else begin
                        if(btn_lap) lap = ~lap;     // lap 토글 
                        else if(btn_clear) lap = 0;
               end
        end   
        // lap 모드 변경
        assign  led_lap = lap;
        
        // clear기능이 있는 60진 카운터
        counter_bcd_60_clear counter_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .clear(btn_clear), .bcd1(sec_1), .bcd10(sec_10));     
        counter_bcd_60_clear counter_min(.clk(clk), .reset_p(reset_p), .clk_time(clk_min), .clear(btn_clear), .bcd1(min_1), .bcd10(min_10));
        
        reg [15:0] lap_time;
        wire [15:0] cur_time;
        assign  cur_time = {min_10, min_1, sec_10, sec_1};      // 현재 시간 
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) lap_time = 0;
                else if(btn_lap) lap_time = cur_time;                    // lap 버튼이 눌리면 현재 시간 저장
                else if(btn_clear) lap_time = 0; 
        end  
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) value = 0;
                else begin
                        if(lap) value = lap_time;
                        else value = cur_time;
                end
        end
endmodule

// cooktimer
module cook_timer_project(
        input clk, reset_p,
        input [4:0] btn,
        output reg [15:0] value,
        output led_alarm, led_start_timer, buzz);
        
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire [3:0] set_sec_1, set_sec_10, set_min_1, set_min_10;
        wire [3:0] cur_sec_1, cur_sec_10, cur_min_1, cur_min_10;
        wire dec_clk;
        reg start_set, alarm;
        wire [15:0] set_time, cur_time;
        
        // 주기 설정 
        clock_div_100   usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));   // 1us           
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));   // 1ms  
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));   // 1 sec   
        
        // 버튼 기능 부여
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_start_timer)); 
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_sec_timer));
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_min_timer));
        button_cntrl  btn4(.clk(clk), .reset_p(reset_p), .btn(btn[4]), .btn_pedge(btn_alarm_off));
        
        // 60진 업카운터(시간 셋팅용)
        counter_bcd_60  counter_sec( .clk(clk), .reset_p(reset_p), .clk_time(btn_sec_timer), .bcd1(set_sec_1), .bcd10(set_sec_10));
        counter_bcd_60  counter_min( .clk(clk), .reset_p(reset_p), .clk_time(btn_min_timer), .bcd1(set_min_1), .bcd10(set_min_10));
        
        // 60진 다운카운터(타이머 용)
        loadable_downcounter_bcd_60 cur_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(btn_start_timer), 
                .load_bcd1(set_sec_1), .load_bcd10(set_sec_10), .bcd1(cur_sec_1), .bcd10(cur_sec_10), .dec_clk(dec_clk));   // 초시간 동기화
        loadable_downcounter_bcd_60 cur_min(.clk(clk), .reset_p(reset_p), .clk_time(dec_clk), .load_enable(btn_start_timer), 
                .load_bcd1(set_min_1), .load_bcd10(set_min_10), .bcd1(cur_min_1), .bcd10(cur_min_10));
        
        // start_set 설정 
        assign cur_time = { cur_min_10, cur_min_1, cur_sec_10, cur_sec_1 };
        assign set_time = { set_min_10, set_min_1, set_sec_10, set_sec_1 };

        always @(posedge clk or posedge reset_p)begin
               if(reset_p)begin
                       start_set = 0;
                       alarm = 0;
               end
               else begin
                       if(btn_start_timer)start_set = ~ start_set;
                       else if(cur_time == 0 && start_set)begin
                               start_set = 0;              // set 모드로 변경 
                               alarm = 1;                   // 시간이 다되면 알람이 켜져야 하므로
                       end
                       else if(btn_alarm_off) alarm = 0;
               end
        end       
        
        // 출력부 
        assign buzz = alarm;
        assign led_alarm = alarm;
        assign led_start_timer = start_set;
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) value = 0;
                else begin
                    if(start_set) value = cur_time;
                    else value = set_time;
                end    
        end
    endmodule