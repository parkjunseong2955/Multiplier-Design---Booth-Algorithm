`timescale 1ns / 1ps

// RegB(승수 레지스터)의 하위 두 bit를 B0와 B1로 define
`define B0 RegB[0] // RegB Register의 최하위 bit
`define B1 RegB[1] // RegB Register의 바로 위 bit

module Booth_Multiplier(  // Booth 알고리즘 연산 모듈 생성
    input clk,            // clock
    input rst,            // Reset
    input St,             // Start
    input [7:0] Mplier,   // 8-bit Multiplier(승수)
    input [7:0] Mcand,    // 8-bit Multiplicand(피승수)
    output [14:0] product // 곱 연산 결과: 부호 bit(1bit)+연산결과 bit(14bit)
);

    reg [1:0] cst, nst;   // cst(현재 상태), nst(다음 상태)
    reg [2:0] Counter;    // 3-bit Counter(0~7을 카운팅)
    reg [8:0] RegB;       // 부호 bit 포함하여 승수를 9bit로 저장
    reg [8:0] ACC;        // Accumulator 9-bit
    reg [7:0] RegC;       // 피승수 8-bit 저장
    wire [7:0] Cmout;     // 2의 보수 연산
    wire [8:0] Addout;    // 덧셈 결과 저장
    wire Carryout;        // 조건에 따른 2의 보수 연산을 위한 Carry 신호
    
    parameter 
        S0 = 2'b00,       // 초기 상태
        S1 = 2'b01,       // 덧셈 또는 보수를 계산하는 상태
        S2 = 2'b10;       // 시프트 연산 상태

    //state register
    always @(posedge clk) begin
        if (!rst) begin //rst=0이면 레지스터와 상태들을 초기화
            cst <= S0;
            ACC <= 0;
            Counter <= 0;
            RegB <= 0;
            RegC <= 0;
        end else begin
            cst <= nst; // 상태 전이
            
            case (cst) // 현재상태에 따른 동작 수행
            S0: begin
                if (St == 1) begin
                    // S0에서 St 신호가 활성화되면 Mplier와 Mcand를 레지스터에 Load
                    RegB <= {Mplier, 1'b0};
                    RegC <= Mcand;
                end
            end
            S1: begin
                if (`B0 ^ `B1 == 1) begin
                    //(`B0 ^ `B1 == 1)이면 ACC에 Addout 값 저장
                    ACC <= Addout;
                end
                else begin
                    ACC <= {ACC[8], ACC[8:1]};  // 그렇지 않으면 시프트 연산 수행
                    RegB <= {ACC[0], RegB[8:1]};
                    if(Counter != 7) begin
                        Counter <= Counter + 1; // Counter가 7이 아니면 1씩 증가시켜 할당
                    end
                    else begin
                        Counter <= 0; // Counter가 7이면 초기화
                    end
                end
            end
            S2: begin
                ACC <= {ACC[8], ACC[8:1]};   // 최상위 비트는 ACC의 최상위 비트를 그대로 추가하여 비트 확장
                RegB <= {ACC[0], RegB[8:1]}; // 오른쪽으로 shift 되어 RegB의 최상위 비트는 ACC[0]이 됨
                if (Counter != 7) begin
                    Counter <= Counter + 1; // Counter가 7이 아니면 1씩 증가시켜 할당
                end 
                else begin
                    Counter <= 0; // Counter가 7이면 초기화
                end                   
            end
            default: begin // 예외 처리: 아무 동작도 수행안함
            end
        endcase
    end
    end

    // next state logic
    always @(*) begin
        case(cst)
            S0: begin
                if (St == 1) begin
                    nst <= S1; // St가 1이면 다음 상태는 S1
                end 
                else begin
                    nst <= S0; // St가 0이면 현재 상태 유지
                end
            end
            
            S1: begin        
                if (`B0 ^ `B1 == 1) begin
                    nst <= S2; // Booth 조건(`B0 ^ `B1 == 1)이 맞으면 S2로 이동
                end
                else begin
                    if(Counter != 7) begin
                        nst <= S1; // Counter가 7이 아니면 S1 유지
                    end
                    else begin
                        nst <= S0; // Counter가 7이면 S0로 돌아감
                    end
                end
            end
            S2: begin
                if (Counter != 7) begin
                    nst <= S1; // Counter가 7이 아니면 S1로 이동하여 shift
                end 
                else begin
                    nst <= S0; // Counter가 7이면 S0로 돌아감
                end                  
            end
            
            default: begin // 예외 처리: 기본적으로 현재 상태 유지
            end
        endcase
    end
    
    // output logic
    assign Carryout = (`B1) & (!`B0); //B1B0=10일 때, C의 2의 보수를 A에 더하는 연산
    assign Cmout = (Carryout == 1) ? (~RegC) : (RegC); // 피승수 1의 보수 연산
    assign Addout = ACC + ({Cmout[7], Cmout} + {8'b00000000, Carryout}); // 각각 9bit로 비트확장 후 덧셈 연산
    assign product = {{7{ACC[8]}}, ACC[6:0], RegB[8:1]}; // 곱의 결과 출력
endmodule

