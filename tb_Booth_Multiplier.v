`timescale 1ns / 1ps

module tb_Booth_Multiplier;

    reg clk;             // clock
    reg rst;             // reset
    reg St;              // Start
    reg [7:0] Mplier;    // 8-bit Multiplier(승수
    reg [7:0] Mcand;     // 8-bit Multiplicand(피승수)
    wire [14:0] product; // 15-bit 곱셈 연산 결과

    Booth_Multiplier uut ( //Booth_Multiplier module을 인스턴스화 후 연결
        .clk(clk),
        .rst(rst),
        .St(St),
        .Mplier(Mplier),
        .Mcand(Mcand),
        .product(product)
    );

    initial begin   // Clock generation, 10ns 주기 Clock
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 0;    // 각각의 신호와 승수, 피승수 레지스터 초기화
        St = 0;
        Mplier = 0;
        Mcand = 0;
        #10 rst = 1; // 10ns 후 rst 활성화하여 Multiplier 동작 시작
       
        Mplier = 8'b10100110; // 승수=-90
        Mcand =  8'b01100110; //피승수=102 둘의 곱의 연산 결과는 -9180
        
        #10 St = 1;     // St 활성화
        #10 St = 0;     // 10ns 후 St 비활성화(1 clock cycle 동안만 활성화)
        #10 Mplier = 0; // 승수, 피승수를 0으로 설정
            Mcand = 0;      
        #200;           // 결과가 안정될 때까지 충분한 시간 대기
        
        rst = 0;               // rst 비활성화하여 모두 초기화
        #10 rst = 1;           // 1 cycle 후 rst 활성화
        Mplier = 8'b01100110;  // 승수=102
        Mcand = 8'b00110011;   // 피승수=51 둘의 곱의 연산 결과는 5202
        
        #10 St = 1;     // St 활성화
        #10 St = 0;     // 1 cycle 후 St 비활성화
        #10 Mplier = 0; // 승수, 피승수를 0으로 설정
            Mcand = 0;      
        #200; $finish;  // 결과가 안정될 때까지 충분한 시간 대기 후 simulation 종료
    end
endmodule