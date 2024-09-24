`timescale 1ns / 1ps

module clock_div_100(               // 100분주
        input clk, reset_p,
        output clk_div_100,
        output clk_div_100_nedge);
        
        reg [6:0] cnt_sysclk;          
        
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

module pwm_Nstep_freq
 #(
        parameter   sys_clk_freq = 100_000_000,  // 100MHz
        parameter   pwm_freq = 10_000,
        parameter   duty_step = 100,
        parameter   temp = sys_clk_freq / duty_step / pwm_freq,
        parameter   temp_half = temp / 2)
(
        input clk, reset_p,
        input [31:0] duty,
        output pwm);
        
        integer cnt_sysclk; 
        integer cnt_duty;
        wire clk_freqXstep, clk_freqXstep_nedge;
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_sysclk = 0;
                else begin
                        if(cnt_sysclk >= temp - 1) cnt_sysclk = 0;
                        else cnt_sysclk = cnt_sysclk + 1;
                end
        end
        
        assign clk_freqXstep = (cnt_sysclk < temp_half) ? 0 : 1; 
        
        edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_freqXstep), .n_edge(clk_freqXstep_nedge)); 
        
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)cnt_duty = 0;
                else if(clk_freqXstep_nedge)begin
                        if(cnt_duty >= (duty_step - 1)) cnt_duty = 0;
                        else cnt_duty = cnt_duty + 1;
                end
        end
        
        assign pwm = (cnt_duty < duty) ? 1 : 0;      // duty rate
        
endmodule

module fnd_cntr(
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
                    default : hex_value = 4'b0000;
                endcase    
        end
        
        decoder_7seg(.hex_value(hex_value), .seg_7(seg_7));
        
endmodule

// button(채터링 문제 해결)
module button_cntr(
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

// 2진수를 10진수로
module bin_to_dec(
        input [11:0] bin,
        output reg [15:0] bcd
    );

    reg [3:0] i;

    always @(bin) begin
        bcd = 0;
        for (i=0;i<12;i=i+1)begin
            bcd = {bcd[14:0], bin[11-i]};
            if(i < 11 && bcd[3:0] > 4) bcd[3:0] = bcd[3:0] + 3;
            if(i < 11 && bcd[7:4] > 4) bcd[7:4] = bcd[7:4] + 3;
            if(i < 11 && bcd[11:8] > 4) bcd[11:8] = bcd[11:8] + 3;
            if(i < 11 && bcd[15:12] > 4) bcd[15:12] = bcd[15:12] + 3;
        end
    end
endmodule

//디코더 세그먼트
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

////////////////////////////////////////////////////////////////
// dht module

module dht11_cntrl(
        input clk, reset_p,
        inout dht11_data,
        output [15:0] led_debug,        // 현재 state 확인용
        output reg [7:0] humidity, temperature);
        
        parameter S_IDLE = 6'b00_0001; 
        parameter S_LOW_18MS = 6'b00_0010;
        parameter S_HIGH_20US = 6'b00_0100;
        parameter S_LOW_80US = 6'b00_1000;
        parameter S_HIGH_80US = 6'b01_0000;
        parameter S_READ_DATA = 6'b10_0000;
        
        parameter S_WAIT_PEDGE = 2'b01;
        parameter S_WAIT_NEDGE = 2'b10;
        
        reg [5:0] state, next_state;
        reg [1:0] read_state;
        
        assign led_debug[5:0] = state;
        
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us
        
        // 마이크로세컨드 단위로 카운트 
        // enable 이 1이면 카운트 동작 , 1이 아니면 0으로 카운트 초기화 
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count_usec = 0;
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) state = S_IDLE;
                else state = next_state;
        end
        
        // data을 in-out 선언 했으므로 reg 선언을 할 수 없음 
        reg dht11_buffer;
        assign dht11_data = dht11_buffer;
        
        // 엣지 디텍터 
        wire dht_nedge, dht_pedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .n_edge(dht_nedge), .p_edge(dht_pedge));
        
        reg [39:0] temp_data;
        reg [5:0] data_count;
        
        // 상태 천이도에 따른 case문  
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = S_IDLE;
                        read_state = S_WAIT_PEDGE;
                        temp_data = 0;
                        data_count = 0;
                end
                else begin
                        case(state)
                            S_IDLE : begin      // 기본상태
                                    if(count_usec < 22'd3_000_000)begin     // 3초동안 기다림
                                            count_usec_en = 1;    // usec 카운트 세기 시작   
                                            dht11_buffer = 'bz;     // 임피던스 출력하면 풀업에 의해 1이 된다(풀업저항이 달려잇음) 
                                    end
                                    else begin
                                            count_usec_en = 0;      // 카운트를 멈추고 초기화 시킴 
                                            next_state = S_LOW_18MS;    // 다음 state로 천이
                                    end         
                            end
                            S_LOW_18MS : begin      //  MCU에서 시작신호 발송상태 
                                    if(count_usec < 22'd20_000)begin        // 최소값이 18ms 이므로 여유있게 20ms 세팅 
                                            dht11_buffer = 0;       // 저장된 data 초기화 
                                            count_usec_en = 1;   // usec 카운트 시작 
                                    end       
                                    else begin      // 20ms 지나면 실행 
                                            count_usec_en = 0;      // 카운트 초기화
                                            next_state = S_HIGH_20US;   // 다음 상태로 천이 
                                            dht11_buffer = 'bz;     // data 임피던스 부여 -> 풀업에 의해 1
                                    end         
                            end
                            S_HIGH_20US : begin     // dht11으로부터의 응답비트 기다림(20us)
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1초 동안 기다렸는데 응답이 안오면 기본상태로 천이 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                    end
                                    else if(dht_nedge) begin     // 응답이 들어오면(하강엣지 발생)
                                            count_usec_en = 0;
                                            next_state = S_LOW_80US;        // 다음 상태로 천이 
                                    end        
                            end
                            S_LOW_80US : begin      // dht11 응답비트 보냄(상승엣지 발생까지 )
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1초 동안 기다렸는데 응답이 안오면 기본상태로 천이 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                    end
                                    else if(dht_pedge)begin              // 데이터시트의 부정확성때문에 정확한 시간이 아닌 엣지를 기다림 
                                            next_state = S_HIGH_80US;
                                            count_usec_en = 0;
                                    end
                            end
                            S_HIGH_80US : begin     // dht11 응답비트 발생 확인(하강엣지 발생까지 )
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1초 동안 기다렸는데 응답이 안오면 기본상태로 천이 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                    end
                                    else if(dht_nedge)begin      
                                            next_state = S_READ_DATA;  
                                             count_usec_en = 0;
                                    end
                            end
                            S_READ_DATA : begin     // dht11에서 데이터 신호 발생 시작(상승엣지 하강엣지 40번 반복)
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000)begin   // 0.1초 동안 기다렸는데 응답이 안오면 기본상태로 천이 
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                            data_count = 0;
                                            read_state = S_WAIT_PEDGE;
                                    end        
                                    else begin        
                                        case(read_state)
                                                S_WAIT_PEDGE : begin        // 상승엣지 기다림 상태 
                                                        if(dht_pedge) read_state = S_WAIT_NEDGE;
                                                end
                                                S_WAIT_NEDGE :  begin       // 하강엣지 기다림 상태
                                                        if(dht_nedge)begin
                                                                if(count_usec < 95)begin
                                                                        temp_data = {temp_data[38:0] , 1'b0};       // shift 레지스터(좌 시프트)
                                                                end
                                                                else begin
                                                                        temp_data = {temp_data[38:0] , 1'b1};
                                                                end
                                                                data_count = data_count + 1;
                                                                read_state = S_WAIT_PEDGE;
                                                                count_usec_en = 0; 
                                                        end
                                                        else begin
                                                                count_usec_en = 1;
                                                        end
                                                end
                                        endcase 
                                        if(data_count >= 40)begin   // 데이터 발송 비트가 40개가 되면 종료 -> 기본상태로 천이 
                                                data_count = 0;
                                                next_state = S_IDLE;
                                                count_usec_en = 0;
                                                read_state = S_WAIT_PEDGE;
                                                // check_sum 확인(오류 유무 확인)
                                                if(temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8] == temp_data[7:0])begin
                                                    humidity = temp_data[39:32];
                                                    temperature = temp_data[23:16];
                                                end    
                                        end 
                                    end          
                                end
                        endcase
                end        
        end
endmodule


module dht11_fan(
        input clk,
        input reset_p,
        inout dht11_data,
        output  led_G, 
        output  led_Y,
        output  led_R,
        output [15:0] value
);
        wire [7:0] humidity, temperature;  // 온습도 데이터값 출력
        dht11_cntrl dht11_inst(
            .clk(clk), 
            .reset_p(reset_p), 
            .dht11_data(dht11_data), 
            .humidity(humidity), 
            .temperature(temperature)
        );
        
        wire [15:0] humidity_bcd, temperature_bcd;  // 2진화 10진수 변환
        bin_to_dec bcd_humidity(
            .bin({4'b0, humidity}), 
            .bcd(humidity_bcd)
        );
        bin_to_dec bcd_temperature(
            .bin({4'b0, temperature}), 
            .bcd(temperature_bcd)
        );
    
        assign led_G = (temperature > 8'd24 && temperature <= 8'd27) ? 1 : 0;
        assign led_Y = (temperature > 8'd27 && temperature < 8'd30) ? 1 : 0;
        assign led_R = (temperature >= 8'd30) ? 1 : 0;
        
         assign value = {humidity_bcd[7:0], temperature_bcd[7:0]};
    
    endmodule

///////////////////////////////////////////////
// standard white led
module fan_white_led(
        input clk, reset_p,
        input reset_w_led,
        input [3:0] btn,
        output led_r, led_g, led_b
    );
    
        reg [31:0] clk_div;
        reg [2:0] brightness;  // 밝기 단계를 위한 2비트 변수
    
        // 클럭 분주기
        always @(posedge clk or posedge reset_p) begin
            if (reset_p)
                clk_div = 0;
            else
                clk_div = clk_div + 1;
        end
    
        // 버튼 눌림 감지
        wire btn_white_led;
        button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_white_led));
    
        // 밝기 단계 조절 (버튼을 누를 때마다)
        always @(posedge clk or posedge reset_p) begin
            if (reset_p || reset_w_led) brightness = 2'b00;
            else if (btn_white_led) begin
                if (brightness == 2'b11) // 최대 밝기에서 다시 처음으로
                    brightness = 2'b00; 
                else
                   brightness = brightness + 1;
            end
        end
    
        wire [31:0] duty_r, duty_g, duty_b;
    
        // 각 색상별로 밝기 단계에 따른 듀티 싸이클 설정
        assign duty_r = (brightness == 2'b00) ? 32'd0 : 
                        (brightness == 2'b01) ? 32'd20 :
                        (brightness == 2'b10) ? 32'd50 : 
                                                 32'd100; //0%,20%,50%,100%
    
        assign duty_g = duty_r;  // 동일한 듀티 싸이클 사용 (필요시 각 색상별로 다르게 설정 가능)
        assign duty_b = duty_r;  // 동일한 듀티 싸이클 사용
    
        
        pwm_Nstep_freq#(
            .duty_step(100)) pwm_r( .clk(clk), .reset_p(reset_p), .duty(duty_r), .pwm(led_r));
        pwm_Nstep_freq#(
            .duty_step(100)) pwm_g( .clk(clk), .reset_p(reset_p), .duty(duty_g), .pwm(led_g));
        pwm_Nstep_freq#(
            .duty_step(100)) pwm_b( .clk(clk), .reset_p(reset_p), .duty(duty_b), .pwm(led_b));
    
endmodule

// 캠핑모드 주황색 LED 밝기 조절 코드
////////////////////////////////////////////////////////////////////////
module camp_yellow_led(
        input clk, reset_p,
        input reset_y_led,
        input [3:0] btn,
        output y_led_r, y_led_g, y_led_b
    );
    
        reg [31:0] clk_div;
        reg [2:0] brightness;  // 밝기 단계를 위한 2비트 변수
        
        // 클럭 분주기
        always @(posedge clk or posedge reset_p) begin
            if (reset_p)
                clk_div = 0;
            else
                clk_div = clk_div + 1;
        end
    
        // 버튼 눌림 감지
        wire btn_yellow_led;
        button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_yellow_led));
    
        // 밝기 단계 조절 (버튼을 누를 때마다)
        always @(posedge clk or posedge reset_p) begin
            if (reset_p || reset_y_led) brightness = 2'b00;
            else if (btn_yellow_led) begin
                if (brightness == 2'b11) // 최대 밝기에서 다시 처음으로
                    brightness = 2'b00; 
                else
                    brightness = brightness + 1;
            end
        end
    
        wire [31:0] duty_g, duty_r;
    
        // 초록색 LED에만 밝기 단계에 따른 듀티 싸이클 설정
        assign duty_g = (brightness == 2'b00) ? 32'd0 : 
                        (brightness == 2'b01) ? 32'd10 :
                        (brightness == 2'b10) ? 32'd20 :
                                                 32'd30; //0%,10%,20%,30%
        
         assign duty_r = (brightness == 2'b00) ? 32'd0 : 
                        (brightness == 2'b01) ? 32'd40 :
                        (brightness == 2'b10) ? 32'd70 : 
                                                 32'd100; //0%,40%,70%,100%
        
        pwm_Nstep_freq#(
            .duty_step(100)) pwm_g( .clk(clk), .reset_p(reset_p), .duty(duty_g), .pwm(y_led_g));
        pwm_Nstep_freq#(
            .duty_step(100)) pwm_r( .clk(clk), .reset_p(reset_p), .duty(duty_r), .pwm(y_led_r));
    
endmodule

module T_flip_flop_p_reset(
        input clk, reset_p,
        input t,
        input timer_reset,
        output reg q);
    
        always @(posedge clk or posedge reset_p)begin
            if(reset_p)q = 0;
            else begin
                if(t) q = ~q;
                else if(timer_reset) q = 0;
                else q = q;
            end
        end
endmodule

module dc_motor_pwm_mode(
        input clk, reset_p,
        input timer_reset,
        input [3:0] btn,
        output [15:0] led,
        output motor_pwm,
        output survo_pwm);
          
        button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_fan_step));
        button_cntr btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_fan_rotation));
       
        reg [2:0] led_count;
        reg [5:0] duty;
        always @(posedge clk or posedge reset_p)begin
                if(reset_p || timer_reset)begin
                        duty = 0;
                end
                else if(btn_fan_step) begin
                        duty = duty + 1;
                        if(duty >= 4) duty = 0;
                end
        end
       
        always @(posedge clk or posedge reset_p)begin
                    if(reset_p || timer_reset) led_count = 3'b000;
                    else if(btn_fan_step)begin
                        if(led_count == 3'b111) led_count = 3'b000;
                        else led_count = {led_count[1:0], 1'b1};
                    end
            end
           
         assign led = led_count;
       
         pwm_Nstep_freq #(
            .duty_step(4),
            .pwm_freq(100))
         pwm_motor(
            .clk(clk),        
            .reset_p(reset_p), 
            .duty(duty),      
            .pwm(motor_pwm)     
        );
       
         reg [31:0] clk_div;
    
        always @(posedge clk or posedge reset_p) begin
            if (reset_p)
                clk_div = 0;
            else
                clk_div = clk_div + 1;
        end
    
    
        wire clk_div_22_pedge;
    
    
        edge_detector_p ed(
            .clk(clk),
            .reset_p(reset_p),
            .cp(clk_div[22]),
            .p_edge(clk_div_22_pedge)
        );
       
        T_flip_flop_p_reset en(.clk(clk), .reset_p(reset_p),.t(btn_fan_rotation), .timer_reset(timer_reset), .q(on_off));
       
        reg [7:0] sv_duty;     
        reg down_up;    
        reg [7:0] duty_min, duty_max;
        always @(posedge clk or posedge reset_p) begin
            if (reset_p) begin
                sv_duty = 16;    
                down_up = 0;
                duty_min = 16;
                duty_max = 96;
            end
            else if (clk_div_22_pedge && on_off) begin
                if (timer_reset) begin
                    sv_duty = sv_duty;              
                end
                else if (!down_up) begin
                    if (sv_duty < duty_max) 
                        sv_duty = sv_duty + 1;
                    else
                        down_up = 1; 
                end
                else begin
                    if (sv_duty > duty_min)  
                        sv_duty = sv_duty - 1;
                    else
                        down_up = 0; 
                end
            end
        end
    
    
         pwm_Nstep_freq #(
            .duty_step(800),  
            .pwm_freq(50)  
               ) sv_motor(
            .clk(clk),
            .reset_p(reset_p),
            .duty(sv_duty),
            .pwm(survo_pwm)
        );
    

endmodule
/////////////////////////////////////////////////
// Timer Counter
module loadable_down_counter_state(
        input clk,
        input reset_p,
        input [3:0] btn,
        output reg [3:0] bcd1_out,
        output reg [3:0] bcd10_out,
        output reg timer_done);

        wire clk_usec, clk_msec, clk_sec;
        clock_div_100   usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));  
        clock_div_1000  msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));    
        clock_div_1000  sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));
       
        button_cntr btn_timer_start(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(next_timer));
             
        parameter S_0s  = 4'b0001;
        parameter S_3s  = 4'b0010;
        parameter S_5s  = 4'b0100;
        parameter S_10s = 4'b1000;
        reg [3:0] state, next_state;
       
            reg [3:0] bcd1, bcd10;
        always @(posedge clk or posedge reset_p) begin
            if (reset_p) state = S_0s;
            else state = next_state;
        end
       
            always @(negedge clk or posedge reset_p) begin
            if (reset_p) begin
                next_state = S_0s;
                bcd1 = 0;
                bcd10 = 0;
                timer_done = 0;
            end
            else begin
                case (state)
                    S_0s: begin
                        bcd1  = 3;
                        bcd10 = 0;
                        timer_done = 0;
                        if (next_timer) begin
                            timer_done = 0;
                            next_state = S_3s;
                        end
                    end
                    S_3s : begin
                        bcd1  = 5;
                        bcd10 = 0;
                        if(bcd1_out == 0 && bcd10_out == 0)begin
                            timer_done = 1;
                            next_state = S_0s;
                        end
                        else if (next_timer) begin
                            next_state = S_5s;
                        end
                    end
                    S_5s: begin
                        bcd1  = 0;
                        bcd10 = 1;
                        if(bcd1_out == 0 && bcd10_out == 0)begin
                            timer_done = 1;
                            next_state = S_0s;
                        end
                        else if (next_timer) begin
                            next_state = S_10s;
                        end
                    end
                    S_10s: begin
                        bcd1  = 0;
                        bcd10 = 0;
                        if(bcd1_out == 0 && bcd10_out == 0)begin
                            timer_done = 1;
                             next_state = S_0s;
                        end
                        else if (next_timer) begin
                            next_state = S_0s;
                        end
                    end
                    default: next_state = S_0s;
                endcase
            end
        end
       
        always @(posedge clk or posedge reset_p) begin
            if (reset_p) begin
                bcd1_out  = 0;
                bcd10_out = 0;
            end
            else if (next_timer) begin
                    bcd1_out  = bcd1;
                    bcd10_out = bcd10;
            end        
            else if (clk_sec) begin
                    if(bcd1_out == 0)begin
                        if(bcd10_out > 0)begin
                            bcd10_out = bcd10_out - 1;
                            bcd1_out  = 9;
                        end
                    end    
                    else begin
                            bcd1_out = bcd1_out - 1;
                    end    
            end
        end
endmodule
    
