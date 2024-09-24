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
        
        assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;        // cur = 1, old = 0 �϶��� 1�̰�, �������� 0�� LUT
        assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;        // cur = 0, old = 1 �϶� �ϰ����� �߻�
        
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
        
        assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;        // cur = 1, old = 0 �϶��� 1�̰�, �������� 0�� LUT
        assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;        // cur = 0, old = 1 �϶� �ϰ����� �߻�
        
endmodule

// T-flipflop ��¿���
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

//1us �ֱ� clk
module clock_div_100(               // 100����
        input clk, reset_p,
        output clk_div_100,
        output clk_div_100_nedge);
        
        reg [6:0] cnt_sysclk;               // 99���� ���� ���� clk �� :  7��Ʈ �ʿ���
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_sysclk = 0;
                else begin
                        if(cnt_sysclk >= 99) cnt_sysclk = 0;
                        else cnt_sysclk = cnt_sysclk + 1;
                end
        end
        
        assign clk_div_100 = (cnt_sysclk < 50) ? 0 : 1;        // cnt_sysclk �� 50���� ������ 0, ũ�� 1 ( �ֱⰡ 1us�� �޽�) duty rate : 50%
         
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div_100), .n_edge(clk_div_100_nedge)); 
         
endmodule

// 1ms
module clock_div_1000(               // 1000����
        input clk, reset_p,
        input clk_source,
        output clk_div_1000,
        output clk_div_1000_nedge);
        
        reg [9:0] cnt_clksource;               // 999���� ���� ���� clk �� :  10��Ʈ �ʿ���
        
        wire clk_source_nedge;
         edge_detector_n ed_source(.clk(clk), .reset_p(reset_p), .cp(clk_source), .n_edge(clk_source_nedge));
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_clksource = 0;
                else if(clk_source_nedge)begin
                        if(cnt_clksource >= 999) cnt_clksource = 0;
                        else cnt_clksource = cnt_clksource + 1;
                end
        end                
        
        assign clk_div_1000 = (cnt_clksource < 500) ? 0 : 1;        // cnt_clksource �� 500���� ������ 0, ũ�� 1 ( �ֱⰡ 1ms�� �޽�)
         
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div_1000), .n_edge(clk_div_1000_nedge)); 
         
endmodule

//60����
module clock_div_60(         // 60����
        input clk, reset_p,
        input clk_source,
        output clk_div_60,
        output clk_div_60_nedge);
        
        reg [5:0] cnt_clksource;               // 60���� ���� ���� clk �� :  6��Ʈ �ʿ���
        
        wire clk_source_nedge;
        edge_detector_n ed_source(.clk(clk), .reset_p(reset_p), .cp(clk_source), .n_edge(clk_source_nedge));
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_clksource = 0;
                else if(clk_source_nedge)begin
                        if(cnt_clksource >= 59) cnt_clksource = 0;
                        else cnt_clksource = cnt_clksource + 1;
                end
        end                
        
        assign clk_div_60 = (cnt_clksource < 30) ? 0 : 1;        // cnt_clksource �� 30���� ������ 0, ũ�� 1 ( �ֱⰡ 1ms�� �޽�)
         
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div_60), .n_edge(clk_div_60_nedge)); 
         
endmodule

// loadable 60�� ��ī����(�ð�)_upgrade Ver
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
                            if(bcd10 >= 5)bcd10 =0;         //bcd1�� 9�� �Ǵ� ���� bcd10 1 ����
                            else bcd10 = bcd10 + 1;
                        end    
                        else bcd1 = bcd1 + 1;
                    end
                end     
        end
endmodule

// loadable 60�� �ٿ�ī����(�ð�)_upgrade Ver
module  loadable_downcounter_bcd_60(
        input   clk, reset_p,
        input   clk_time,
        input   load_enable,
        input   [3:0] load_bcd1, load_bcd10,
        output  reg [3:0]   bcd1, bcd10,
        output  reg dec_clk);   // �ʰ� 0 -> 59�� �ɶ� �� clk��ŭ�� 1�� �߻���Ű�� one-cylce-pulse
        
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
                            if(bcd10 == 0)begin        // bcd10 = 0�̵Ǵ� ���� �ٽ� 5�� ������� 
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
                                if(bcd10 >= 5)bcd10 =0;         //bcd1�� 9�� �Ǵ� ���� bcd10 1 ����
                                else bcd10 = bcd10 + 1;
                            end    
                            else bcd1 = bcd1 + 1;
                     end
                end     
        end
endmodule

// 60�� ī����(�ð�)
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
                        if(bcd10 >= 5)bcd10 =0;         //bcd1�� 9�� �Ǵ� ���� bcd10 1 ����
                        else bcd10 = bcd10 + 1;
                    end    
                    else bcd1 = bcd1 + 1;
                end
        end
endmodule

// button(ä�͸� ���� �ذ�)
module button_cntrl(
        input   clk, reset_p,
        input   btn,
        output  btn_pedge, btn_nedge);
        
        reg [20:0]  clk_div = 0;   
        always @(posedge clk) clk_div = clk_div + 1;
        
        wire clk_div_nedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));     // 16�� ��Ʈ�� 1.33ms
        
        reg debounced_btn;
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p)debounced_btn = 0;
                else if(clk_div_nedge)debounced_btn = btn;
        end
        
       edge_detector_p ed_btn(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .n_edge(btn_nedge), .p_edge(btn_pedge));                 
                
endmodule

// ���ڴ� ���׸�Ʈ
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
        
        reg [20:0]  clk_div = 0;        // '= 0'�� �ùķ��̼� ���ǻ� 0���� �ʱ�ȭ / ���忡���� ������� 
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

// ��� ����� ��ī����
module ring_counter_mode(
        input clk, reset_p,
        input [3:0] btn,
        output reg [2:0] btn_mode_ring,
        output reg [2:0] led_mode);
        
        wire btn_mode_nedge;
        button_cntrl    btn_mode( .clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode_pedge), .btn_nedge(btn_mode_nedge));
        
        // Mode ���� ��ư
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) btn_mode_ring = 3'b001;
                else if(btn_mode_nedge)begin
                    if(btn_mode_ring == 3'b100) btn_mode_ring = 3'b001; 
                    else btn_mode_ring = {btn_mode_ring[2:0], 1'b0};
                end
        end
        
        // Mode ���濡 ���� Mode Ȯ�ο� led Ȱ��ȭ 
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) led_mode = 3'b001;
                else if(btn_mode_nedge)begin
                    if(led_mode == 3'b100) led_mode = 3'b001; 
                    else led_mode = {led_mode[2:0], 1'b0};
                end
        end
endmodule               
        
 //loadable Watch(Upgrade Version)
 //��尡 ����Ǿ ����ȭ�Ǿ �ð��� ���缭 �帥��
module loadable_watch_project(
        input clk, reset_p,        
        input [3:0] btn,
        output reg [15:0] value);         
    
        wire set_watch;          // 1�̸�(������) set , 0�̸� watch
        wire inc_sec, inc_min;
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire watch_load_en, set_load_en;
      
         //��ư ��������� �ο� (ä�͸� ���� �ذ�)
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_mode_set_watch));                  
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_sec));
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_min));
                
        // ��� ���� ��ư ��� ���� 
        T_flip_flop_p   t_mode(.clk(clk), .reset_p(reset_p), .t(btn_mode_set_watch), .q(set_watch));
        
        // �ð� ����ȭ(load)
        edge_detector_n ed_source(.clk(clk), .reset_p(reset_p), .cp(set_watch), .n_edge(watch_load_en), .p_edge(set_load_en));
        
        // ��忡 ���� ���� �� ���� ���� 
        assign  inc_sec =  set_watch ? btn_sec : clk_sec;        // set ��忡���� �� ����, watch��忡���� �ð���
        assign  inc_min = set_watch ? btn_min : clk_min;        // set ��忡���� �� ����, watch��忡���� �ð���
        
        // �ֱ� ����
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));     // 1us         
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));     // 1ms  
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));         // 1s   
        clock_div_60    min_clk( .clk(clk), .reset_p(reset_p), .clk_source(inc_sec), .clk_div_60_nedge(clk_min));        // 1min 
       
        // loadable 60�� ī���� 
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
        
        // �ý��� ���� ��ư / Ŭ���� ��ư �з�
        assign reset_start = reset_p | btn_clear;
        // start / stop ��ư ���� �� ���� 
        assign clk_start = start_stop ? clk : 0;
        
        // �ֱ� ���� 
        clock_div_100   usec_clk( .clk(clk_start), .reset_p(reset_start), .clk_div_100(clk_usec));   // 1us           
        clock_div_1000  msec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_usec), .clk_div_1000(clk_msec));   // 1ms  
        clock_div_1000  sec_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));   // 1 sec   
        clock_div_60      min_clk(.clk(clk_start), .reset_p(reset_start), .clk_source(clk_sec), .clk_div_60_nedge(clk_min));   // 1min 
        
        // ������ ��ư ��� �ο�(ä�͸� ���� �ذ�) 
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_start));   
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_lap));
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_clear));
        
        // start, stop ��� ��� ���� + led on/off 
        T_flip_flop_p  t_start(.clk(clk), .reset_p(reset_start), .t(btn_start), .q(start_stop));
        assign  led_start = start_stop;
         
        // lap ��� ����(lap ���� / Ŭ���� ��ư ���� ����) 
        always  @(posedge clk or posedge reset_p)begin
                if(reset_p) lap = 0;
                else begin
                        if(btn_lap) lap = ~lap;     // lap ��� 
                        else if(btn_clear) lap = 0;
               end
        end   
        // lap ��� ����
        assign  led_lap = lap;
        
        // clear����� �ִ� 60�� ī����
        counter_bcd_60_clear counter_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .clear(btn_clear), .bcd1(sec_1), .bcd10(sec_10));     
        counter_bcd_60_clear counter_min(.clk(clk), .reset_p(reset_p), .clk_time(clk_min), .clear(btn_clear), .bcd1(min_1), .bcd10(min_10));
        
        reg [15:0] lap_time;
        wire [15:0] cur_time;
        assign  cur_time = {min_10, min_1, sec_10, sec_1};      // ���� �ð� 
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) lap_time = 0;
                else if(btn_lap) lap_time = cur_time;                    // lap ��ư�� ������ ���� �ð� ����
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
        
        // �ֱ� ���� 
        clock_div_100   usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));   // 1us           
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));   // 1ms  
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));   // 1 sec   
        
        // ��ư ��� �ο�
        button_cntrl  btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_start_timer)); 
        button_cntrl  btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_sec_timer));
        button_cntrl  btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_min_timer));
        button_cntrl  btn4(.clk(clk), .reset_p(reset_p), .btn(btn[4]), .btn_pedge(btn_alarm_off));
        
        // 60�� ��ī����(�ð� ���ÿ�)
        counter_bcd_60  counter_sec( .clk(clk), .reset_p(reset_p), .clk_time(btn_sec_timer), .bcd1(set_sec_1), .bcd10(set_sec_10));
        counter_bcd_60  counter_min( .clk(clk), .reset_p(reset_p), .clk_time(btn_min_timer), .bcd1(set_min_1), .bcd10(set_min_10));
        
        // 60�� �ٿ�ī����(Ÿ�̸� ��)
        loadable_downcounter_bcd_60 cur_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(btn_start_timer), 
                .load_bcd1(set_sec_1), .load_bcd10(set_sec_10), .bcd1(cur_sec_1), .bcd10(cur_sec_10), .dec_clk(dec_clk));   // �ʽð� ����ȭ
        loadable_downcounter_bcd_60 cur_min(.clk(clk), .reset_p(reset_p), .clk_time(dec_clk), .load_enable(btn_start_timer), 
                .load_bcd1(set_min_1), .load_bcd10(set_min_10), .bcd1(cur_min_1), .bcd10(cur_min_10));
        
        // start_set ���� 
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
                               start_set = 0;              // set ���� ���� 
                               alarm = 1;                   // �ð��� �ٵǸ� �˶��� ������ �ϹǷ�
                       end
                       else if(btn_alarm_off) alarm = 0;
               end
        end       
        
        // ��º� 
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